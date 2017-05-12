package HPC::Runner::Command::Utils::Base;

use Cwd;
use File::Path qw(make_path remove_tree);
use List::Uniq ':all';

use MooseX::App::Role;
use MooseX::Types::Path::Tiny qw/Path Paths AbsPath AbsFile/;

=head1 HPC::Runner::Command::Utils::Base

Base class for HPC::Runner::Command libraries.

This is a Moose Role. To use in any another applications or plugins call as

    package MyApp;

    use Moose;
    with 'HPC::Runner::Command::Utils::Base';

=head2 Command Line Options

=head3 project

When submitting jobs we will prepend the jobname with the project name

=cut

option 'project' => (
    is            => 'rw',
    isa           => 'Str',
    documentation => 'Give your jobnames an additional project name. #HPC jobname=gzip will be submitted as 001_project_gzip',
    required      => 0,
    predicate => 'has_project',
);

=head3 infile

File of commands separated by newline. The command 'wait' indicates all previous commands should finish before starting the next one.

=cut

option 'infile' => (
    is       => 'rw',
    required => 1,
    documentation =>
        q{File of commands separated by newline. The command 'wait' indicates all previous commands should finish before starting the next one.},
    isa    => AbsFile,
    coerce => 1,
);

=head3 outdir

Directory to write out files and optionally, logs.

=cut

option 'outdir' => (
    is            => 'rw',
    isa           => AbsPath,
    lazy          => 1,
    coerce        => 1,
    required      => 1,
    default       => \&set_outdir,
    documentation => q{Directory to write out files.},
    trigger       => \&_make_the_dirs,
    predicate     => 'has_outdir',
);

#These two should both be in execute_jobs


=head3 procs

Total number of concurrent running tasks.

Analagous to parallel --jobs i

=cut

option 'procs' => (
    is       => 'rw',
    isa      => 'Int',
    default  => 1,
    required => 0,
    documentation =>
        q{Total number of concurrently running jobs allowed at any time.}
);

=head2 Attributes

=cut

has 'cmd' => (
    traits   => ['String'],
    is       => 'rw',
    isa      => 'Str',
    required => 0,
    handles  => {
        add_cmd   => 'append',
        match_cmd => 'match',
    },
    predicate => 'has_cmd',
    clearer   => 'clear_cmd',
);

=head3 set_outdir

Internal variable

=cut

sub set_outdir {
    my $self = shift;

    if ( $self->has_outdir ) {
        $self->_make_the_dirs( $self->outdir );
        return;
    }

    my $outdir;

    if ( $self->has_version && $self->has_git ) {
        if($self->has_project){
            $outdir = "hpc-runner/". $self->project. "/". $self->version . "/scratch";
        }
        else{
            $outdir = "hpc-runner/" . $self->version . "/scratch";
        }
    }
    else {
        if($self->has_project){
            $outdir = "hpc-runner/" . $self->project . "/scratch";
        }
        else{
            $outdir = "hpc-runner/". "scratch";
        }
    }

    $self->_make_the_dirs($outdir);

    return $outdir;
}

=head3 make_the_dirs

Make any necessary directories

=cut

sub _make_the_dirs {
    my ( $self, $outdir ) = @_;

    make_path($outdir) unless -d $outdir;
}

=head3 datetime_now

=cut

sub datetime_now {
    my $self = shift;

    my $dt = DateTime->now( time_zone => 'local' );

    my $ymd = $dt->ymd();
    my $hms = $dt->hms();

    return ( $dt, $ymd, $hms );
}

=head3 git_things

Get git versions, branch, and tags

=cut

sub git_things {
    my $self = shift;

    $self->init_git;
    $self->dirty_run;
    $self->git_info;

    return unless $self->has_git;

    return unless $self->has_version;

    if ( $self->tags  ) {
        push( @{ $self->tags }, "$self->{version}" ) if $self->has_version;
    }
    else {
        $self->tags( [ $self->version ] );
    }
    my @tmp = uniq( @{ $self->tags } );
    $self->tags( \@tmp );
}

1;
