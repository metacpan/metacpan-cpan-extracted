#!perl
use 5.008;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Test::More;
use Test::Exception;

use lib 'lib';
use Mail::AuthenticationResults::Parser;

my $ARHeader = "Authentication-Results: foo.example.net (foobar) 1 (baz);
           dkim (Because I like it) / 1 (One yay) = (wait for it) fail

             policy (A dot can go here) . (like that) expired
             (this surprised me) = (as I wasn't expecting it) 1362471462";

my $AsString = "foo.example.net (foobar) (baz) 1;
    dkim=fail (Because I like it) / 1 (One yay) (wait for it) policy.expired=1362471462 (A dot can go here) (like that) (this surprised me) (as I wasn't expecting it)";

my $Parsed;

lives_ok( sub{ $Parsed = Mail::AuthenticationResults::Parser->new()->parse( $ARHeader ) }, 'Comment heavy example parses' );
is( $Parsed->as_string, $AsString, 'as string is as expected' );

done_testing();

