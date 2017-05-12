#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

use EPublisher::Source::Plugin::PerltutsCom;

{
  package MockEPublisher;

  use Test::More;

  sub new { return bless {}, shift }
  sub debug { diag $_[1] if $ENV{DIAG_EPUBLISHER} }
}

my $config = { name => 'ThisTutorialDoesNotExistHopefully' };
my $obj    = EPublisher::Source::Plugin::PerltutsCom->new( $config );
$obj->publisher( MockEPublisher->new );

my @pods   = $obj->load_source;

# if tutorial does not exist I expect an empty array as return
is (scalar @pods, 0, 'inexisting tutorial name');

