package JiftyX::Fixtures::Script::Init;
our $VERSION = '0.07';

# ABSTRACT: init subcommand

use warnings;
use strict;

use Jifty;
use Jifty::Everything;

use IO::File;
use File::Basename;
use File::Spec;
use YAML qw(Dump LoadFile);

use base qw(
  App::CLI::Command
);

my $super = 'JiftyX::Fixtures::Script';

our $help_msg = qq{
Usage:

  jiftyx-fixtures init [options]

Options:

  -h, --help:               show help

};

my $prototype = qq{
development:
  dir: "etc/fixtures/development"
  format: "yml"
  greeking: "false"

test:
  dir: "etc/fixtures/test"
  format: "yml"
  greeking: "false"

};

sub options {
  my ($self) = @_;
  return (
    $super->options,
  );
}

sub before_run {
  my ($self) = @_;

  $super->before_run($self);

  return;
}

sub run {
  my ($self) = @_;
  $self->before_run();
  
  unless ($self->{config}->{fixtures}) {

    my $fixtures_config = IO::File->new;
    if ($fixtures_config->open("> " . $self->{config}->{app_root} . "/etc/fixtures.yml")) {
      print $fixtures_config $prototype;
    }

    mkdir $self->{config}->{app_root} . "/etc/fixtures";
  }
}

1;

__END__
=head1 NAME

JiftyX::Fixtures::Script::Init - init subcommand

=head1 VERSION

version 0.07

=head1 AUTHOR

  shelling <shelling@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by <shelling@cpan.org>.

This is free software, licensed under:

  The MIT (X11) License

