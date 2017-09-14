package HPC::Runner::Command::Logger::JSON;

use MooseX::App::Role;
use MooseX::Types::Path::Tiny qw/File Path Paths AbsPath AbsFile/;
use File::Spec;
use Data::UUID;
use DateTime;
use File::Path qw(make_path remove_tree);
use HPC::Runner::Command::Logger::JSON::Archive;

with 'BioSAILs::Utils::Files::CacheDir';

option 'data_dir' => (
    is            => 'rw',
    isa           => AbsPath,
    lazy          => 1,
    coerce        => 1,
    required      => 1,
    documentation => q{Data directory for hpcrunner},
    predicate     => 'has_data_dir',
    default       => sub {
        my $self = shift;
        my $path = $self->create_data_dir;
        $ENV{HPC_DATA_DIR} = $path;
        return $path;
    },
    trigger => sub {
        my $self = shift;
        make_path( $self->data_dir );
        $ENV{HPC_DATA_DIR} = $self->data_dir->stringify;
    },
);

sub create_data_dir {
    my $self = shift;

    if ( $self->has_data_dir ) {
        make_path( $self->data_dir);
        return;
    }

    my $data_dir = File::Spec->catdir( $self->cache_dir, '.hpcrunner-data' );
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

    my $path = File::Spec->catdir( $data_dir, $project );
    make_path($path);

    if ( $self->has_project ) {
        $path =
          File::Spec->catdir( $data_dir, $project,
            $dt . '__PR_' . $project . '__UID_' . $uuid );
    }
    else {
        $path =
          File::Spec->catdir( $data_dir, $project, $dt . '__UID_' . $uuid );
    }

    return $path;
}

1;
