use v5.20.0;
use strict;
use warnings;
no warnings 'once';

use B::Deparse;
use FindBin '$Bin';

use lib "$Bin/lib";
use lib "$Bin/../lib";
use lib '/home/tai/src/p5/p5-lexical-accessor/lib';

eval 'require Local::Example::Core;   1' or warn $@;
eval 'require Local::Example::Plain;  1' or warn $@;
eval 'require Local::Example::Marlin; 1' or warn $@;
eval 'require Local::Example::Moo;    1' or warn $@;
eval 'require Local::Example::Moose;  1' or warn $@;
eval 'require Local::Example::Tiny;   1' or warn $@;

my $dp = B::Deparse->new;

for my $i ( @Local::Example::ALL ) {
	say "####";
	say "#### $i";
	say "####";
	
	my $class = $i . "::Employee::Developer";
	for my $method ( qw/ add_language all_languages / ) {
		say sprintf(
			"%s %s::%s %s\n",
			$i =~ /::Core$/ ? 'method' : 'sub',
			$class,
			$method,
			$dp->coderef2text( $class->can($method) ),
		);
	}
	
	say "";
}
