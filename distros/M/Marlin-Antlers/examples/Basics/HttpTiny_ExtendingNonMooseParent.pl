BEGIN {{{ # Inspired by Moose::Cookbook::Basics::DateTime_ExtendingNonMooseParent

# Because the parent class accepts a hash, this should mostly "just work".
# The only thing we need is to set sloppy=>1 to prevent Marlin from
# complaining about arguments that were intended for the parent constructor.
# If the parent class didn't accept a hash, we might need to use
# BUILDARGS and/or FOREIGNBUILDARGS to massage the constructor's @_ into
# formats they each understand.
{
	package My::HTTP;
	use Marlin::Antlers { sloppy => 1 };
	extends 'HTTP::Tiny';
	has 'flibble';
}

}}};

use Test2::V0;
use Data::Dumper;

my $ua = My::HTTP->new( max_redirect => 3, flibble => 42 );

isa_ok($ua, 'My::HTTP');
isa_ok($ua, 'HTTP::Tiny');

is( $ua->max_redirect, 3 );
is( $ua->flibble, 42 );

done_testing;
