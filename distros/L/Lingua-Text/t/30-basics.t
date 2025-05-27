#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most tests => 14;

BEGIN {
	use_ok('Lingua::Text')
}

local %ENV;

delete $ENV{'LANGUAGE'};
delete $ENV{'LC_ALL'};
delete $ENV{'LANG'};

# Test object creation
my $string = Lingua::Text->new({ en => 'Hello', fr => 'Bonjour' });
isa_ok($string, 'Lingua::Text', 'Object created');

# Test setting and getting strings
$string->en('Hello, World');
is($string->en(), 'Hello, World', 'Set and get English string');

$string->fr('Bonjour, Tout le Monde, café');
is($string->fr(), 'Bonjour, Tout le Monde, café', 'Set and get French string');

# Test automatic language detection
$ENV{'LANG'} = 'fr_FR';
is($string, 'Bonjour, Tout le Monde, café', 'Automatic language selection (French)');

$ENV{'LANG'} = 'en_US';
is($string, 'Hello, World', 'Automatic language selection (English)');

# Test fallback behaviour
$ENV{'LANG'} = 'de_DE';
ok(!defined($string->as_string()), 'Fallback when language is not set');

# Test encode method
$string->encode();
is($string->fr(), 'Bonjour, Tout le Monde, caf&eacute;', 'Encode retains correct French with HTML entities');

# Test set method
$string->set({ text => 'Hola', lang => 'es' });
is($string->es(), 'Hola', 'Set and get Spanish string');

# Test cloning
my $cloned_string = $string->new({ de => 'Hallo' });
isa_ok($cloned_string, 'Lingua::Text', 'Cloned object created');
is($cloned_string->de(), 'Hallo', 'Cloned object contains new language');
is($cloned_string->es(), 'Hola', 'Cloned object retains old language');

# Test as_string
is($string->as_string('en'), 'Hello, World', 'as_string with English language');
is($string->as_string({ lang => 'es' }), 'Hola', 'as_string with Spanish language');
