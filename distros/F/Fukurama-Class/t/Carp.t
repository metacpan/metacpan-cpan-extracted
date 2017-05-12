#!perl -T
use Test::More tests => 7;
use strict;
use warnings;

{
	package MyClass;
	use Fukurama::Class::Carp;
	
	sub a {
		b(@_);
	}
	sub b {
		c(@_);
	}
	sub c {
		d(@_);
	}
	sub d {
		e(@_);
	}
	sub e {
		&{$_[0]}($_[1], $_[2]);
	}
}
eval { MyClass::a(\&MyClass::_croak, 'exist') };
like($@, qr/exist[^\n]+line 26/, 'export croak');
unlike($@, qr/CODE[^\n]+line 20/, "don't be verbose at croak");
eval { MyClass::a(\&MyClass::_croak, 'exist', 1) };
like($@, qr/exist[^\n]+line 20/, 'croak with CarpLevel');

close(STDERR);
my $warnings = '';
open(STDERR, '>', \$warnings);


eval { MyClass::a(\&MyClass::_carp, 'enabled') };
like($warnings, qr/enabled[^\n]+line 37/, 'export carp');
unlike($warnings, qr/CODE/, "don't be verbose");
eval { MyClass::a(\&MyClass::_carp, 'next_enabled', 1) };
like($warnings, qr/next_enabled[^\n]+line 40/, 'carp with CarpLevel');

my @warnings = split(/\n/, $warnings);
is(scalar(@warnings), 7, 'no other warnings');
