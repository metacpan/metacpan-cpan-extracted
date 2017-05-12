package JiftyX::Fixtures;
our $VERSION = '0.07';

# ABSTRACT: Insert fixtures into your Jifty application database

use strict;
use warnings;

use UNIVERSAL::dump;

use Jifty;
use Jifty::Everything;
use Jifty::Util;

use YAML qw(Dump LoadFile);

use JiftyX::Fixtures::Script;

sub new {
  my $self = bless {}, shift;

  $self->{config}->{app_root}   = Jifty::Util->app_root;
  $self->{config}->{framework}  = Jifty->config->stash->{framework};

  my $fixtures_config = $self->{config}->{app_root} . "/etc/fixtures.yml";
  $self->{config}->{fixtures}   = LoadFile($fixtures_config) if (-e $fixtures_config);

  $self;
}

sub config {
  my ($self, $type, $args) = @_;
  if ($args) {
    $self->{config}->{$type} = $args;
    $self;
  } else {
    $self->{config}->{$type};
  }
}

sub run { 
  my ($self, $subcommand) = @_;
  $subcommand ||= "load";
  unshift @ARGV, $subcommand unless defined($ARGV[0]);
  JiftyX::Fixtures::Script->dispatch( config => $self->{config} );
}
  

1;


__END__
=head1 NAME

JiftyX::Fixtures - Insert fixtures into your Jifty application database

=head1 VERSION

version 0.07

=head1 SYNOPSIS

    JiftyX::Fixtures->new->config(
      fixtures => [
        development => {
          dir => "etc/fixtures/development"
        }
      ]
    )->run;

=head1 DESCRIPTION

    WARNING: This software is stil in alpha stage, any intense variation is possible.

Load pre-defined fixture from specified mode, and Insert it into you Jifty application database.

=head1 AUTHOR

  shelling <shelling@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by <shelling@cpan.org>.

This is free software, licensed under:

  The MIT (X11) License

=head1 METHODS

=head2 new

Constructor, invoke without args

=head2 config

Give one arg which is selected from "app_root", "framework", "fixtures" to get the configuration detail.

Append second arg to set the configuration.

    $jf->config("fixtures"); #=> [  development => { dir => "etc/fixtures/development" }, 
                                    test => { dir => "etc/fixtures/test" } ]
    $jf->config(
      fixtures => [
        development => {
          dir => "etc/dev_fixtures"
        },
        test => {
          dir => "etc/test_fixtures"
        }
      ]
    );

=head2 run

Running subcommand, default is "load". Give one arg to specify which subcommand would be run.

