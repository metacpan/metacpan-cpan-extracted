# Tests related to RT25477 - https://rt.cpan.org/Public/Bug/Display.html?id=25477
use strict;
use warnings;
use File::Spec;
use Test::More;

use_ok('HTML::Scrubber');
use HTML::Scrubber;

my $scrubber = HTML::Scrubber->new;
$scrubber->default(1);
is( $scrubber->scrub('<hr/><hr><hr /><hr></hr>'), '<hr /><hr><hr /><hr></hr>', "correct result" );

done_testing;
