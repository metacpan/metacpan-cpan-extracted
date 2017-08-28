package HPC::Runner::Command::Logger::JSON;

use MooseX::App::Role;
use MooseX::Types::Path::Tiny qw/File Path Paths AbsPath AbsFile/;
use File::Spec;
use Data::UUID;
use DateTime;
use File::Path qw(make_path remove_tree);
use HPC::Runner::Command::Logger::JSON::Archive;

with 'BioSAILs::Utils::Files::CacheDir';

has 'data_dir' => (
    is            => 'rw',
    isa           => AbsPath,
    lazy          => 1,
    coerce        => 1,
    required      => 1,
    documentation => q{Data directory for hpcrunner},
    predicate     => 'has_data_dir',
    default       => sub {
        my $self = shift;
        return File::Spec->catdir( $self->cache_dir, '.hpcrunner-data' );
    }
);

option 'data_tar' => (
    is            => 'rw',
    isa           => Path,
    coerce        => 1,
    required      => 0,
    predicate     => 'has_data_tar',
    documentation => 'Location of tar file for hpcrunner logging data.',
    lazy          => 1,
    trigger       => sub {
        my $self = shift;
        $self->data_tar->touchpath;
        my $tar = $self->set_archive;
        $self->archive($tar);
    },
    default => sub {
        my $self = shift;
        $self->create_data_archive;
    },
);

has 'archive' => (
    is        => 'rw',
    required  => 0,
    lazy      => 1,
    predicate => 'has_archive',
    clearer   => 'clear_archive',
    default   => sub {
        my $self = shift;
        # return $self->set_archive;
    },
);

sub set_archive {
    my $self = shift;
    my $tar = HPC::Runner::Command::Logger::JSON::Archive->new( dirs => 1 );

    if ( $self->has_data_tar ) {
        $self->data_tar->touchpath;
    }
    else {
        #Create a UID and a tar
        my $archive = $self->create_data_archive;
    }

    $ENV{HPC_DATA_TAR} = $self->data_tar->stringify;
    return $tar;
}

sub create_data_archive {
    my $self = shift;

    my $project = "NULL_PROJECT";
    $project = $self->project if $self->has_project;

    ##Create initial document
    my $dt = DateTime->now( time_zone => 'local' );
    $dt = "$dt";
    $dt =~ s/:/-/g;

    my $ug   = Data::UUID->new;
    my $uuid = $ug->create();
    $uuid = $ug->to_string($uuid);

    $self->submission_uuid($uuid);

    my $path = File::Spec->catdir( $self->data_dir, $project );
    make_path($path);

    if ( $self->has_project ) {
        $path =
          File::Spec->catdir( $self->data_dir, $project,
            $dt . '__PR_' . $project . '__UID_' . $uuid );
    }
    else {
        $path =
          File::Spec->catdir( $self->data_dir, $project,
            $dt . '__UID_' . $uuid );
    }

    $self->data_dir($path);
    my $archive = $path . '.tar.gz';
    $self->data_tar($archive);

    return $archive;
}

1;
