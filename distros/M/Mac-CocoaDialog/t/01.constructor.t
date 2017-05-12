# vim: filetype=perl :
use strict;
use warnings;

use Test::More tests => 3; # last test to print
#use Test::More 'no_plan';    # substitute with previous line when done
use Test::Exception;
use Mac::CocoaDialog;

my $module = 'Mac::CocoaDialog';

my $cocoa;
lives_ok { $cocoa = $module->new(path => $^X) }
'factory constructor lives';
isa_ok($cocoa, $module);
is($cocoa->path(), $^X, 'path is correctly set and get');
