# Tests related to RG72659 - https://rt.cpan.org/Public/Bug/Display.html?id=72659
#
# I was unable to reproduce the errors described, but am leaving this in
# place for now as it will catch any future issues with utf8 disjoints.
#
use strict;
use utf8;
use File::Spec;
use Test::More;

use_ok('HTML::Scrubber');

use HTML::Scrubber;

my $source = "\x{DF}";
utf8::upgrade($source);

ok( utf8::is_utf8($source), 'Source string is marked UTF8' );
ok( utf8::valid($source),   'Source string is valid UTF8' );

# scrub it
my $scrubber = HTML::Scrubber->new();
my $result   = $scrubber->scrub($source);

ok( utf8::is_utf8($result), 'Result string is marked UTF8' );
ok( utf8::valid($result),   'Result string is valid UTF8' );
is( $source, $result, 'Result = Source' );

done_testing;
