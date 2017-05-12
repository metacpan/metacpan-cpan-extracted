#!perl
# make sure that we've got unique agents & cached configs for each type of bank
use warnings;
use strict;

use Test::More tests => 3 * 3;

use Finance::Bank::IE::BankOfIreland;
use Finance::Bank::IE::AvantCard;
use Finance::Bank::IE::PTSB;

my @banks;
push @banks, 'Finance::Bank::IE::BankOfIreland';
push @banks, 'Finance::Bank::IE::AvantCard';
push @banks, 'Finance::Bank::IE::PTSB';

my %agents;
for my $class ( @banks ) {
    my $config = { class => $class };
    eval( "$class->cached_config( \$config )" );
    eval( "\$agents{'$class'} = scalar( $class->_agent()) or die" );
}

my %seenagents;
for my $class ( @banks ) {
    my ( $config, $agent );
    eval( "\$config = $class->cached_config()" );
    eval( "\$agent = $class->_agent()" );
    my $proceed = ok( $config && ref $config eq 'HASH', "$class cached_config returned a hash" );

  SKIP:
    {
      skip "because previous test blocks this one", 1 unless $proceed;
      ok( $config->{class} eq $class, "$class has distinct config" );
      ok( !$seenagents{scalar($agent)}, "$class has distinct agent" );
      $seenagents{scalar($agent)} = 1;
    }
}


