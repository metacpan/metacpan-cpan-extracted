#!/usr/bin/perl

# Adapted from http://gist.github.com/212780

use strict;
use warnings;

use Test::More tests => 7;
use Digest::Whirlpool;
#use Digest::MD5;

my @digesters;

for ( 1..5 ){
  push @digesters, {
      whirlpool => Digest::Whirlpool->new(),
      #md5 => Digest::MD5->new()
  };
}

# seeing that its constant accross instances.

for ( @digesters ) {
  my $hex = $_->{whirlpool}->hexdigest();
  my $hexd = $_->{whirlpool}->hexdigest();

  is($hex, $hexd, "Whirlpool: Two digest with no input added are the same");

  #$hex = $_->{md5}->hexdigest();
  #$hexd = $_->{md5}->hexdigest();

  #is($hex, $hexd, "MD5: Two digest with no input added are the same");
}

sub some_key
{
    my $hash = shift;
    if (my @keys = keys %$hash) {
        return $keys[0];
    }
    return;
}

my $tests = 1000;


# seeing that within a single digester, the same empty value results in a pseudorandom sequence generation.
{
    my (%whirl, %md5);

    $digesters[0]->{whirlpool}->reset();
    #$digesters[0]->{md5}->reset();

    for ( 1..$tests ) {
        my $digest = $digesters[0]->{whirlpool}->hexdigest;
        $whirl{$digest} = 1;
    }

    is_deeply({ some_key(\%whirl) => 1 }, \%whirl, "Whirlpool: Should only have one digest");

    #for ( 1..$tests ){
    #    my $digest = $digesters[0]->{md5}->hexdigest;
    #    $md5{ $digest } = 1;
    #}

    #is_deeply({ some_key(\%md5) => 1 }, \%md5, "MD5: Should only have one digest");
}


# seeing that the digester doesn't conform to the specification that the rest conform to
# with regard to hexdigest resetting the state.
{
    my (%whirl, %md5);

    $digesters[0]->{whirlpool}->reset();
    #$digesters[0]->{md5}->reset();

    for ( 1..$tests ) {
        $digesters[0]->{whirlpool}->add('hello');
        my $digest = $digesters[0]->{whirlpool}->hexdigest;
        $whirl{$digest} = 1;
    }

    is_deeply({ some_key(\%whirl) => 1 }, \%whirl, "Whirlpool: Should only have one digest");

    #for ( 1..$tests ){
    #    $digesters[0]->{md5}->add('hello');
    #    my $digest = $digesters[0]->{md5}->hexdigest;
    #    $md5{ $digest } = 1;
    #}

    #is_deeply({ some_key(\%md5) => 1 }, \%md5, "MD5: Should only have one digest");
}
