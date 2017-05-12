package Liquibase::Git;

use strict;
use warnings;
use feature 'say';
use Moo;
use File::Temp qw/tempdir/;
use DateTime;
use IPC::Cmd qw/run/;
use IO::Handle;
use Data::Dumper;

our $VERSION = '0.01';

# ABSTRACT: API and CLI to apply sql scripts from a git repo using Liquibase



has username => (
  is       => 'ro',
  required => 1,
);


has password => (
  is       => 'ro',
  required => 1,
);


has db => (
  is       => 'ro',
  required => 1,
);

has hostname => (
  is       => 'ro',
  required => 1,
);

# something like mydb1
has git_changeset_dir => (
  is       => 'ro',
  required => 1,
);

has git_repo => (
  is       => 'ro', # eg. ssh://git@github.com/foo/myapp.git
  required => 1,
);

has git_identifier => (
  is       => 'ro', # something like 'master', 'branchname' or a commit hash
  required => 1,
);

has temp_dir => (
  # create a temp directory
  is      => 'ro',
  default => sub { tempdir(CLEANUP => 1); },
);

has db_type => (
  is       => 'ro',
  required => 1,
  isa => sub {
    die 'Only types available are postgresql and mysql'
      unless $_[0] eq 'postgresql' || $_[0] eq 'mysql';
  }
);

# filename relative to the changeset_dir
has git_changeset_file => (
  is       => 'ro',
  required => 1,
);

my %default_db_drivers  = (
  postgresql => {
    classpath => '/usr/share/java/postgresql-jdbc.jar',
    port      => '5432',
  },
  mysql => {
    classpath => '/usr/share/java/mysql-connector-java.jar',
    port      => '3306',
  },
);


has classpath => (
  is      => 'lazy',
  default => sub {
    my $self = shift;

    return $default_db_drivers{$self->db_type}->{classpath};
  }
);

has port => (
  is      => 'lazy',
  default => sub {
    my $self = shift;

    return $default_db_drivers{$self->db_type}->{port};
  }
);


sub liquibase_command_stem {
  my $self = shift;

  my $command = "CLASSPATH=".$self->classpath.
    ' /usr/bin/liquibase --changeLogFile='.$self->git_changeset_dir.'/'.$self->git_changeset_file.' '.
    '--url="jdbc:'.$self->db_type.
    '://'.$self->hostname.':'.$self->port.'/'.
    $self->db.'" --username='.$self->username.' --password='.$self->password;

  return $command;
}



# return the buffer (stderr+stdout) only, and die if things go badly
sub run_command {
  my %args = (
    cmd        => undef,
    @_
  );

  my $buffer;

  my ( $success, $error_code, $full_buf, $stdout_buf, $stderr_buf) = run (command => $args{cmd}, buffer => \$buffer);

  STDERR->autoflush(1);
  STDOUT->autoflush(1);

  my $censored_cmd = $args{cmd};
  $censored_cmd =~ s/--password=(\w*)/--password=__CENSORED__/;

  say '=================================================';
  say 'COMMAND: '.$censored_cmd;
  say '=================================================';
  say $buffer if $buffer;
  unless ($success) {
    say '=================================================';
    say 'FAILED';
  }
  unless ($success) {
    say STDERR "ERROR CODE: $error_code";
    say STDERR "ERROR BUF: ".Dumper($stderr_buf);
    exit 1;
  }

  return $buffer;
}


sub retrieve_changeset_from_git {
  my $self = shift;


  my $cmd_git_clone = "git clone ".$self->git_repo." ".$self->temp_dir;
  run_command(cmd => $cmd_git_clone);

  chdir $self->temp_dir;
  my $cmd_git_checkout = "git checkout ".$self->git_identifier;
  run_command(cmd => $cmd_git_checkout);

  my $git_commit_id = run_command(cmd => 'git log --format="%H" -n 1');
  chomp $git_commit_id;

  my $dt_now = DateTime->now;
  my $description = $dt_now.'.'.$self->git_identifier.'.'.$$.".".$git_commit_id;
  run_command(cmd => "echo PATCH_RUN_SIGNATURE: ${description}");
}

sub dryrun {
  my $self = shift;

  run_command(cmd => $self->liquibase_command_stem." updateSQL");
}

sub wetrun {
  my $self = shift;

  run_command(cmd => $self->liquibase_command_stem." update");
  run_command(cmd => 'echo PASSED');
}

sub update {
  my $self = shift;

  $self->retrieve_changeset_from_git;
  chdir $self->temp_dir;
  $self->dryrun;
  $self->wetrun;
}

sub updateSQL {
  my $self = shift;

  $self->retrieve_changeset_from_git;
  chdir $self->temp_dir;
  $self->dryrun;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Liquibase::Git - API and CLI to apply sql scripts from a git repo using Liquibase

=head1 VERSION

version 0.0.1

=head1 SYNOPSIS

  use Liquibase::Git;

  my $liquibase = Liquibase::Git->new(
   %params
  );

  $liquibase->apply;

=head1 DESCRIPTION

Install this module on a server with Liquibase installed

Assume you have an app with:

=over

=item * git repo https://github.com/foo/myapp.git containing a liquibase changeset

=item * a database mydb-db1

=item * a database host db1.myapp.com

=back

The following code

  my $liquibase = Liquibase::Git->new(
     username          => 'liquibase',
     password          => 'foobar',
     db                => 'mydb-db1',
     hostname          => 'db1.myapp.com'
     git_repo          => 'https://github.com/foo/myapp.git',
     git_changeset_dir => 'db/db1',
     git_identifier    => 'master',
     db_type           => 'postgresql',
     port              => '5432', # OPTIONAL
     changeset_file    => 'changeset.xml',
  );

  $liquibase->update;

applies the sql changes defined by

  https://github.com/foo/myapp.git:db/db1/changeset.xml

on the database mydb-db1.

  $liquibase->updateSQL;

Only prints out the changes which would take place.

__THIS IS A DEVELOPMENT RELEASE. MAY CHANGE WITHOUT NOTICE__.

=head1 REFERENCE

<http://www.liquibase.org/>

=head1 ALTERNATIVE

L<App::Sqitch>

=head2 Utilities

=head1 AUTHOR

Andrew Solomon <andrew.solomon@net-a-porter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Net-a-Porter.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
