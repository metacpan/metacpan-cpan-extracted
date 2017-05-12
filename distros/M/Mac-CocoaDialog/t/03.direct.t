# vim: filetype=perl :
use strict;
use warnings;

use Test::More tests => 10; # last test to print
#use Test::More 'no_plan';    # substitute with previous line when done
use Test::Exception;
use Mac::CocoaDialog;

my $module = 'Mac::CocoaDialog';

my $cocoa;
lives_ok { $cocoa = $module->new(path => $^X) }
'factory constructor lives';
isa_ok($cocoa, $module);

lives_ok {$cocoa->push_params('bubble') } 'first push_params lives';

my @params = (
   text               => 'whatever',
   something_isolated => undef,
   little_list        => [qw( what a mess )],
);
while (@params) {
   my ($k, $v) = splice @params, 0, 2;
   lives_ok {
      no strict 'refs';
      $cocoa->push_params($k, !defined($v) ? () : ref($v) ? @$v : $v);
   }
   'further push_params lives';
} ## end while (@params)

is_deeply(
   [$cocoa->command_line()],
   [
      qw(
        bubble
        text whatever
        something_isolated
        little_list what a mess
        )
   ],
   "runner's command line at the end"
);

is_deeply([$cocoa->command_line(qw( ciao a tutti ))],
   [qw( ciao a tutti )], "runner's command line overriding");

is_deeply(
   [$cocoa->command_line(ciao => {text => [qw( whatever it is )],})],
   [qw( ciao --text whatever it is )],
   "runner's command line overriding with hash"
);

is_deeply(
   [$cocoa->command_line()],
   [
      qw(
        bubble
        text whatever
        something_isolated
        little_list what a mess
        )
   ],
   "runner's internal command line still safe"
);
