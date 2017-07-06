package HPC::Runner::Command::archive;

use MooseX::App::Command;

with 'HPC::Runner::Command::Logger::Loggers';

use File::Spec;
use Path::Tiny;
use Cwd;
use DateTime;
use Archive::Tar;
use File::Path qw(make_path remove_tree);
use File::Find::Rule;
use IO::Dir;
use IPC::Cmd qw[can_run run];

use MooseX::Types::Path::Tiny qw/Path Paths AbsPath AbsFile/;

command_short_description 'Create an archive of results.';
command_long_description 'Create an archive of results. '
  . 'Default is to add all files in your current working directory.'
  . 'Include or exclude with --include_paths and --exclude_paths. '
  . 'This requires tar to be installed';

=head2 Command Line Options

=cut

option 'include_paths' => (
    is            => 'rw',
    isa           => Paths,
    required      => 0,
    coerce        => 1,
    documentation => 'Include files or directories',
    cmd_aliases   => ['ip'],
    predicate     => 'has_include_paths',
    clearer       => 'clear_include_paths',
);

option 'exclude_paths' => (
    is            => 'rw',
    isa           => Paths,
    required      => 0,
    coerce        => 1,
    predicate     => 'has_exclude_paths',
    documentation => 'Files or directories to exclude',
    cmd_aliases   => ['ep'],
    clearer       => 'clear_exclude_paths',
);

option 'archive' => (
    is       => 'rw',
    isa      => Path,
    coerce   => 1,
    required => 0,
    default  => sub {
        my $self = shift;
        my $dt = DateTime->now( time_zone => 'local' );
        $dt = "$dt";
        $dt =~ s/:/-/g;

        my $tar_path = File::Spec->catdir( 'archive-' . $dt . '.tar.gz' );

        return path($tar_path);
    },
);

sub execute {
    my $self = shift;

    my $files = $self->list_dirs;
    $files = $self->check_dirs_exist($files);

    $self->create_archive($files);
}

sub create_archive {
    my $self  = shift;
    my $files = shift;

    make_path( $self->archive->parent );

    my $buffer;
    my $cmd =
      "tar -zcvf " . $self->archive->stringify . " " . join( ' ', @{$files} );
    $self->screen_log->info( 'Cmd is: ' . $cmd );
    if (
        scalar run(
            command => $cmd,
            verbose => 0,
            buffer  => \$buffer,
            timeout => 20
        )
      )
    {
        $self->screen_log->info(
            'Archive ' . $self->archive->stringify . ' created successfully' );
    }
    else {
        $self->screen_log->info( 'Archive could not be created! ' . $buffer );
    }

    my $tar = Archive::Tar->new;
    $tar->read( $self->archive );

    return $tar;
}

sub check_dirs_exist {
    my $self  = shift;
    my $files = shift;

    my @exists = ();

    foreach my $file ( @{$files} ) {
        if ( $file->exists ) {
            push( @exists, $file );
        }
        else {
            $self->screen_log->warn(
                'Path ' . $file->stringify . ' does not exist. Excluding.' );
        }
    }

    if ( !scalar @exists ) {
        $self->screen_log->fatal('There are no paths to archive. Exiting.');
        exit 1;
    }

    return \@exists;
}

sub list_dirs {
    my $self = shift;

    my @dirs =
      File::Find::Rule->extras( { follow => 1 } )->maxdepth(1)->directory()
      ->in(getcwd);

    my @files =
      File::Find::Rule->extras( { follow => 1 } )->maxdepth(1)->file()
      ->in(getcwd);

    # my @files = glob( File::Spec->catdir( getcwd(), "*" ) );
    my $cwd_files = {};

    map { $cwd_files->{$_} = 1 } @files;
    map { $cwd_files->{$_} = 1 } @dirs;

    if ( $self->has_include_paths ) {
        map { my $str = $_->absolute->stringify; $cwd_files->{$str} = 1 }
          @{ $self->include_paths };
    }
    push( @{ $self->exclude_paths }, path('.git') );
    push( @{ $self->exclude_paths }, path(getcwd()) );
    map { my $str = $_->absolute->stringify; delete $cwd_files->{$str} }
      @{ $self->exclude_paths };

    my @keys = keys %{$cwd_files};
    @keys = sort(@keys);
    my @rel_files = map { path($_)->relative } @keys;

    return \@rel_files;
}

1;
