package HPC::Runner::Command::Plugin::Logger::Sqlite;

our $VERSION = '0.01';

use Moose::Role;

use HPC::Runner::Command::Plugin::Logger::Sqlite::Schema;
use Data::Dumper;
use Cwd;
use Log::Log4perl qw(:easy);

with 'HPC::Runner::Command::Plugin::Logger::Sqlite::Deploy';

##Application log
has 'app_log' => (
    is      => 'rw',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $log_conf = q(
log4perl.category = DEBUG, Screen
log4perl.appender.Screen = \
    Log::Log4perl::Appender::ScreenColoredLevels
log4perl.appender.Screen.layout = \
    Log::Log4perl::Layout::PatternLayout
log4perl.appender.Screen.layout.ConversionPattern = \
    [%d] %m %n
        );

        Log::Log4perl->init( \$log_conf);
        return get_logger();
      }
);

=head1 HPC::Runner::Command::Plugin::Logger::Sqlite;

Base class for HPC::Runner::Command::submit_jobs::Plugin::Logger::Sqlite and HPC::Runner::Command::execute_job::Plugin::Sqlite

=cut

=head2 Attributes

=cut

=head3 schema

Sqlite3 Schema Object

=cut

has 'schema' => (
    is      => 'rw',
    default => sub {
        my $self = shift;
        my $schema
            = HPC::Runner::Command::Plugin::Logger::Sqlite::Schema->connect(
            'dbi:SQLite:' . $self->db_file );
        return $schema;
    },
    lazy => 1,
);

=head3 db_file

Path to sqlite3 db file. If the file doesn't exist sqlite3 will create it.

=cut

has 'db_file' => (
    is      => 'rw',
    default => sub {
        my $cwd = getcwd();
        return $cwd . "/hpc-runner-command-plugin-logger-sqlite.db";
    },
);

=head3 submission_id

This is the ID for the entire hpcrunner.pl submit_jobs submission, not the individual scheduler IDs

=cut

has 'submission_id' => (
    is        => 'rw',
    isa       => 'Str|Int',
    lazy      => 1,
    default   => '',
    predicate => 'has_submission_id',
    clearer   => 'clear_submission_id'
);

=head2 Subroutines

=cut

1;

__END__

=encoding utf-8

=head1 NAME

HPC::Runner::Command::Plugin::Sqlite - Log HPC::Runner workflows to a sqlite DB.

=head1 SYNOPSIS

To submit jobs to a cluster

    hpcrunner.pl submit_jobs --hpc_plugins Logger::Sqlite

To execute jobs on a single node

    hpcrunner.pl execute_jobs --job_plugins Logger::Sqlite

Generate a summary report

  hpcrunner.pl stats
  hpcrunner.pl stats --jobname gatk
  hpcrunner.pl stats --project Sequencing1
  hpcrunner.pl stats --project Sequencing1 --jobname gatk_haplotypecaller

Generate a longer report

  hpcrunner.pl stats
  hpcrunner.pl stats --long/-l --jobname gatk
  hpcrunner.pl stats --long/-l --project Sequencing1
  hpcrunner.pl stats --long/-l --project Sequencing1 --jobname gatk_haplotypecaller


=head1 DESCRIPTION

HPC::Runner::Command::Plugin::Sqlite - Log HPC::Runner workflows to a sqlite DB.

This plugin requires sqlite3 in the path.

=head1 AUTHOR

Jillian Rowe E<lt>jillian.e.rowe@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2016- Jillian Rowe

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
