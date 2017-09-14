package HPC::Runner::Command::stats;

use MooseX::App::Command;
use Moose::Util qw/apply_all_roles/;
extends 'HPC::Runner::Command';

use MooseX::Types::Path::Tiny qw/File Path Paths AbsPath AbsFile/;
with 'HPC::Runner::Command::Logger::JSON';
with 'HPC::Runner::Command::stats::Logger::JSON::Summary';
with 'HPC::Runner::Command::stats::Logger::JSON::Long';
with 'HPC::Runner::Command::Logger::Loggers';

use JSON;
use File::Find::Rule;
use File::stat;
use File::Spec;
use File::Slurp;
use Path::Tiny;
use File::Basename;
use Capture::Tiny ':all';

command_short_description 'Query submissions by project, or jobname';
command_long_description 'Query submissions by project, or jobname. ' . 'This
searches through the tars created during execution.'
  . ' If you have a large number
of submissions you may want to specify a project, '
  . 'or supply the desired submission with --data_tar.';

option 'most_recent' => (
    is            => 'rw',
    isa           => 'Bool',
    required      => 0,
    default       => 1,
    documentation => q(Show only the most recent submission.),
    trigger       => sub {
        my $self = shift;
        $self->all(1) if !$self->most_recent;
    }
);

option 'all' => (
    is            => 'rw',
    isa           => 'Bool',
    required      => 0,
    default       => 0,
    documentation => 'Show all submissions.',
    trigger       => sub {
        my $self = shift;
        $self->most_recent(1) if !$self->all;
    },
    cmd_aliases => ['a'],
);

option '+project' => ( documentation => 'Query by project.', );

option 'jobname' => (
    is            => 'rw',
    isa           => 'Str',
    documentation => 'Query by jobname',
    required      => 0,
    predicate     => 'has_jobname',
);

option 'summary' => (
    is  => 'rw',
    isa => 'Bool',
    documentation =>
'Summary view of your jobs - Number of running, completed, failed, successful.',
    required => 0,
    default  => 1,
);

option 'long' => (
    is  => 'rw',
    isa => 'Bool',
    documentation =>
      'Long view. More detailed report - Task tags, exit codes, duration, etc.',
    required => 0,
    default  => 0,
    trigger  => sub {
        my $self = shift;
        $self->summary(0) if $self->long;
    },
    cmd_aliases => ['l'],
);

option 'json' => (
    is            => 'rw',
    isa           => 'Bool',
    default       => 0,
    documentation => 'Output data in json instead of a table. '
      . 'This option suppresses logging output.',
    cmd_aliases => ['j'],
);

has 'task_data' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
    clearer => 'clear_task_data',
);

parameter 'stats_type' => (
    is            => 'rw',
    isa           => 'Str',
    default       => 'JSON',
    documentation => 'hpcrunner.pl stats JSON/Sqlite/Elasticsearch .',
);

sub BUILD {
    my $self = shift;

    if ( $self->json && $self->summary ) {
        apply_all_roles( $self,
                'HPC::Runner::Command::stats::Logger::'
              . $self->stats_type
              . '::Summary::JSONOutput' );
    }
    elsif ( !$self->json && $self->summary ) {
        apply_all_roles( $self,
                'HPC::Runner::Command::stats::Logger::'
              . $self->stats_type
              . '::Summary::TableOutput' );
    }
    elsif ( $self->json && $self->long ) {
        apply_all_roles( $self,
                'HPC::Runner::Command::stats::Logger::'
              . $self->stats_type
              . '::Long::JSONOutput' );
    }
    elsif ( !$self->json && $self->long ) {
        apply_all_roles( $self,
                'HPC::Runner::Command::stats::Logger::'
              . $self->stats_type
              . '::Long::TableOutput' );
    }
}

sub execute {
    my $self = shift;

    $self->iter_submissions;
}

sub iter_submissions {
    my $self = shift;

    my $results = $self->get_submissions();

    foreach my $result ( @{$results} ) {
        $self->data_dir($result);
        my $submission_file =
          File::Spec->catdir( $self->data_dir, 'submission.json' );
        if ( -e $submission_file ) {
            my $submission_json = read_file($submission_file);
            my $submission      = decode_json($submission_json);
            my $jobref          = $submission->{jobs};

            $self->iter_jobs_summary( $submission, $jobref )
              if $self->summary;
            $self->iter_jobs_long( $submission, $jobref ) if $self->long;
        }
        else {
            $self->screen_log->info( 'Data Tar '
                  . $self->data_dir
                  . ' does not contain any submission info!' );
        }
    }

}

sub get_submissions {
    my $self = shift;

## Skip over this searching nonsense
    my $results;
    if ( $self->has_data_dir && $self->data_dir->exists ) {
        my $file = $self->data_dir;
        $results = ["$file"];
    }
    elsif ( $self->has_data_dir && !$self->data_dir->exists ) {
        $self->screen_log->fatal(
            'You have supplied a data tar that does not exist.');
        $self->screen_log->fatal(
            'Data Tar ' . $self->data_dir . ' does not exist' );
        exit 1;
    }
    else {
        $results = $self->search_submission;
    }

    return $results;
}

sub search_submission {
    my $self = shift;

    my $data_path = "";
    my $data_dir = File::Spec->catdir( $self->cache_dir, '.hpcrunner-data' );
    if ( $self->project ) {
        $data_path = File::Spec->catdir( $data_dir, $self->project );
    }
    else {
        $data_path = $data_dir;
    }

    if ( !path($data_path)->exists && path($data_path)->is_dir ) {
        $self->screen_log->info( 'There is no data logged. '
              . 'Please ensure you either in the project directory, '
              . 'or that you have supplied --data_dir to the correct location.'
        );
    }

    $self->screen_log->info( 'Searching for submissions in ' . $data_dir );

    ##TODO In the case of a lot of submissions - get the most recent directory
    my @files = File::Find::Rule->directory()->maxdepth(2)->name(qr/.*UID.*/)
      ->in($data_path);
    if ( !$self->json ) {
        $self->screen_log->info( 'Found ' . scalar @files . ' submissions.' );
        $self->screen_log->info('Reporting on the most recent.')
          if $self->most_recent;
        $self->screen_log->info('Reporting on all submissions.') if $self->all;
    }

    my %stats = ();
    map { my $st = stat($_); $stats{ $st->[9] } = $_ } @files;

    my @sorted_files = ();
    foreach ( sort { $b <=> $a } keys(%stats) ) {
        push( @sorted_files, $stats{$_} );
        last if $self->most_recent;
    }

    return \@sorted_files;
}

__PACKAGE__->meta()->make_immutable();

1;
