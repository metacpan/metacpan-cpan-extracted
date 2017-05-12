package JiftyX::Fixtures::Script::Clean;
our $VERSION = '0.07';

# ABSTRACT: clean subcommand

use warnings;
use strict;

use Jifty;
use Jifty::Everything;

use IO::File;
use File::Basename;
use File::Spec;
use File::Path;
use YAML qw(Dump LoadFile);

use base qw(
  App::CLI::Command
);

my $super = 'JiftyX::Fixtures::Script';

our $help_msg = qq{
Usage:

  jiftyx-fixtures clean [options]

Options:

  -h, --help:               show help

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

  for (keys %{$self->{config}->{fixtures}}) {
    my $dir = File::Spec->catfile(
      $self->{config}->{app_root},
      $self->{config}->{fixtures}->{$_}->{dir}
    );
    rmtree $dir;
  }
  rmdir File::Spec->catfile(
    $self->{config}->{app_root},
    "etc",
    "fixtures"
  );
  unlink File::Spec->catfile(
    $self->{config}->{app_root},
    "etc",
    "fixtures.yml"
  );


}

1;

__END__
=head1 NAME

JiftyX::Fixtures::Script::Clean - clean subcommand

=head1 VERSION

version 0.07

=head1 AUTHOR

  shelling <shelling@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by <shelling@cpan.org>.

This is free software, licensed under:

  The MIT (X11) License

