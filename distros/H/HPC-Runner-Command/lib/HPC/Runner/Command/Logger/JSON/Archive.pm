package HPC::Runner::Command::Logger::JSON::Archive;

use Moose;
use MooseX::NonMoose;

use File::Spec;
use File::Slurp;
use Try::Tiny;
use Path::Tiny;
use Data::Dumper;
use Capture::Tiny ':all';
use File::Temp qw/ tempfile tempdir /;
use File::Path qw(make_path remove_tree);
use Cwd;
use File::Temp qw(tempdir);
use Log::Log4perl qw(:easy);
use IPC::Run qw(run);

extends 'Archive::Tar::Wrapper';

sub contains_file {
    my $self = shift;
    my $file = shift;

    my $found = 0;
    $self->list_reset();

    while ( my $entry = $self->list_next() ) {
        my ( $tar_path, $phys_path ) = @$entry;
        if ( $tar_path eq $file ) {
            $found = 1;
            last;
        }
    }

    $self->list_reset();
    return $found;
}

sub add_data {
    my $self   = shift;
    my $file   = shift;
    my $data   = shift;
    my $append = shift;

    $append = 0 if !$append;

    return unless $file;
    $data = '' unless $data;

    my $cwd = getcwd();
    my $tmpdir = tempdir( CLEANUP => 0 );
    chdir $tmpdir;

    my $rel_path = File::Spec->abs2rel($file);
    path($rel_path)->touchpath;
    path($rel_path)->touch;

    try {
        write_file( $rel_path, { append => $append }, $data );
    }
    catch {
        warn "We were not able to write data to file $file $_\n";
    };

    $self->add( $rel_path, $rel_path );

    chdir $cwd;
    remove_tree($tmpdir);
}

sub replace_content {
    my $self = shift;
    my $file = shift;
    my $data = shift;

    $self->add_data( $file, $data, 0 );
}

sub get_content {
    my $self = shift;
    my $file = shift;

    $self->list_reset();
    my $data = '{}';

    while ( my $entry = $self->list_next() ) {
        my ( $tar_path, $phys_path ) = @$entry;
        if ( $tar_path eq $file ) {
            try {
                $data = read_file( $entry->[1] );
            };
            last;
        }
    }
    $self->list_reset();
    return $data;
}

############################################################
# Read and write are very nearly the same as the original. The only major
# difference was to get rid of the DEBUG statement about Running
############################################################

around 'read' => sub {
    my $orig    = shift;
    my $self    = shift;
    my $tarfile = shift;
    my @files   = @_;

    my $cwd = getcwd();

    $tarfile = File::Spec->rel2abs($tarfile);
    chdir $self->{tardir}
      or LOGDIE "Cannot chdir to $self->{tardir}";

    my $compr_opt = "";
    $compr_opt = $self->is_compressed($tarfile);

    my $cmd = [
        $self->{tar},
        "${compr_opt}x$self->{tar_read_options}",
        @{ $self->{tar_gnu_read_options} },
        "-f", $tarfile, @files
    ];

    my $rc = run( $cmd, \my ( $in, $out, $err ) );

    if ( !$rc ) {
        ERROR "@$cmd failed: $err";
        chdir $cwd or LOGDIE "Cannot chdir to $cwd";
        return undef;
    }

    WARN $err if $err;

    chdir $cwd or LOGDIE "Cannot chdir to $cwd";

    return 1;
};

around 'write' => sub {
    my ( $orig, $self, $tarfile, $compress ) = @_;

    my $cwd = getcwd();
    chdir $self->{tardir} or LOGDIE "Can't chdir to $self->{tardir} ($!)";

    $tarfile = File::Spec->rel2abs($tarfile);

    my $compr_opt = "";
    $compr_opt = "z" if $compress;

    opendir DIR, "." or LOGDIE "Cannot open $self->{tardir}";
    my @top_entries = grep { $_ !~ /^\.\.?$/ } readdir DIR;
    closedir DIR;

    my $cmd = [
        $self->{tar}, "${compr_opt}cf$self->{tar_write_options}",
        $tarfile,     @{ $self->{tar_gnu_write_options} }
    ];

    if ( @top_entries > $self->{max_cmd_line_args} ) {
        my $filelist_file = File::Spec->catdir( $self->{tmpdir}, "file-list" );
        write_file( $filelist_file, { append => 0 }, '' )
          or LOGDIE "Cannot open $filelist_file ($!)";

        for (@top_entries) {
            write_file( $filelist_file, { append => 1 }, $_ );
        }
        push @$cmd, "-T", $filelist_file;
    }
    else {
        push @$cmd, @top_entries;
    }

    my $rc = run( $cmd, \my ( $in, $out, $err ) );

    if ( !$rc ) {
        ERROR "@$cmd failed: $err";
        chdir $cwd or LOGDIE "Cannot chdir to $cwd";
        return undef;
    }

    WARN $err if $err;

    chdir $cwd or LOGDIE "Cannot chdir to $cwd";

    return 1;
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;
