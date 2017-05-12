package JiftyX::Fixtures::Script::Load;
our $VERSION = '0.07';

# ABSTRACT: load subcommand, primary function of this module

use warnings;
use strict;

use Jifty;
use Jifty::Everything;

use File::Basename;
use File::Spec;
use YAML qw(Dump LoadFile);

use base qw(
  App::CLI::Command
);

my $super = 'JiftyX::Fixtures::Script';

our $help_msg = qq{
Usage:

  jiftyx-fixtures load [options]

Options:

  -d, --drop-database:      drop database before loading fixtures, default is true
  -e, --environment:        specify environment, default is development
  -h, --help:               show help

};

sub options {
  my ($self) = @_;
  return (
    $super->options,
    'd|drop-database=s' => 'drop-database',
    'e|environment=s'   => 'environment',
  );
}

sub before_run {
  my ($self) = @_;

  $super->before_run($self);

  $self->{environment} ||= "development";
  $self->{'drop-database'} ||= "true";
  $self->drop_db() if ($self->{"drop-database"} eq "true");

  return;
}

sub run {
  my ($self) = @_;
  $self->before_run();

  Jifty->new;

  for ($self->fixtures_files) {
    my $filename = basename($_);
    $filename =~ s/\.yml//;

    my $fixtures = LoadFile($_);

    my $model = Jifty->app_class("Model",$filename)->new;

    for my $entity (@{ $fixtures }) {
      $model->create( %{$entity} );
    }
  }
}

sub fixtures_files {
  my $self = shift;
  return glob(
    File::Spec->catfile(
      $self->{config}->{app_root},
      "etc",
      "fixtures",
      $self->{environment},
      "*"
    )
  );
}

sub drop_db {
  my $self = shift;
  my $dbconfig = $self->{config}->{framework}->{Database};

  if ( $dbconfig->{Driver} eq "SQLite" && -e $dbconfig->{Database} ) {
    print "WARN - SQLite Database has existed, delete file now.\n";
    unlink $dbconfig->{Database};
  }

  if ($dbconfig->{Driver} eq "MySQL") {
    print "WARN - MySQL Database has existed, delete file now.\n";
    unlink $dbconfig->{Database};
    my $dbh = DBI->connect("dbi:mysql:database=".$dbconfig->{Database}, $dbconfig->{User}, $dbconfig->{Password});
    $dbh->prepare("drop database ". $dbconfig->{Database});
    $dbh->disconnect;
  }
}


1;

__END__
=head1 NAME

JiftyX::Fixtures::Script::Load - load subcommand, primary function of this module

=head1 VERSION

version 0.07

=head1 AUTHOR

  shelling <shelling@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by <shelling@cpan.org>.

This is free software, licensed under:

  The MIT (X11) License

