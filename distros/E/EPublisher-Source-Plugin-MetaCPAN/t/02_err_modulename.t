#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use EPublisher::Source::Plugin::MetaCPAN;

{
  package MockEPublisher;

  use Test::More;

  sub new { return bless {error => ''}, shift }
  sub debug { 
      my ($self,$msg) = @_;
      diag $msg if $ENV{DIAG_EPUBLISHER}; 
      $self->{error} .= $msg . "\n";
  }
  sub error { shift->{error} }
}

my $pub    = MockEPublisher->new;
my $config = { module => 'ThisModuleDoesNotExistHopefully' };
my $obj    = EPublisher::Source::Plugin::MetaCPAN->new( $config );
$obj->publisher( $pub );

my @pods   = $obj->load_source;

# if module does not exist I expect an empty array as return
is (scalar @pods, 0, 'inexisting module name');
like $pub->error, qr/103: release ThisModuleDoesNotExistHopefully does not exist/, 'check error message';

done_testing();
