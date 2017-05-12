#!perl -T

use Test::More tests => 3;
use Test::NoWarnings;
use strict;
use warnings;

BEGIN {
    use_ok( 'Encode::Detect::Upload' ) || print "Bail out!\n";
}

subtest 'simple',sub{
    %ENV = (
        HTTP_USER_AGENT => 'foo Windows',
	REMOTE_ADDR => '127.0.0.1',
	HTTP_ACCEPT_LANGUAGE => 'en',
    );
    my $detector = Encode::Detect::Upload->new;

    my $charset = $detector->detect(text => 'hello world');
    is($charset, 'utf-8');

    $charset = $detector->detect(text => "Mari\xe9 Cl\xe2re");
    is($charset, 'windows-1252');

    $charset = $detector->detect(text => "\xd5\xee\xf0\xee\xf8");
    is($charset, 'windows-1252');

	# If the Mozilla library is available it will affect the sequence by default
	# Adjust the ranking object to prevent this and keep things consistent for different
	# testing setups.
	my %rank = (
		mozilla_move => 0,
	);

    $charset = $detector->detect(text => "\xd5\xee\xf0\xee\xf8", lang => 'ru', ranking => \%rank);
    is($charset, 'windows-1251');

    my($charsets,$meta) = $detector->detect(text => "\xd5\xee\xf0\xee\xf8", lang => 'ru', ranking => \%rank);
    is_deeply($charsets, ['windows-1251','x-mac-cyrillic']);
};
