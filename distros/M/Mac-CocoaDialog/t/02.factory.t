# vim: filetype=perl :
use strict;
use warnings;

use Test::More tests => 15; # last test to print
#use Test::More 'no_plan';    # substitute with previous line when done
use Test::Exception;
use Mac::CocoaDialog;

my $module = 'Mac::CocoaDialog';
my $runmod = $module . '::Runner';

my $cocoa;
lives_ok { $cocoa = $module->new(path => $^X) }
'factory constructor lives';
isa_ok($cocoa, $module);

my $bubble;
lives_ok { $bubble = $cocoa->bubble() } 'factory method lives';
isa_ok($bubble, $runmod);
is_deeply([$bubble->command_line()],
   ['bubble'], "runner's command line init");

my @params = (
   text               => 'whatever',
   something_isolated => undef,
   little_list        => [qw( what a mess )],
);
while (@params) {
   my ($k, $v) = splice @params, 0, 2;
   my $rval;
   lives_ok {
      no strict 'refs';
      $rval = $bubble->$k(!defined($v) ? () : ref($v) ? @$v : $v);
   }
   'runner method lives';
   is($rval, $bubble, 'runner method returns runner');
} ## end while (@params)

is_deeply(
   [$bubble->command_line()],
   [
      qw(
        bubble
        --text whatever
        --something-isolated
        --little-list what a mess
        )
   ],
   "runner's command line at the end"
);

is_deeply([$bubble->command_line(qw( ciao a tutti ))],
   [qw( ciao a tutti )], "runner's command line overriding");

is_deeply(
   [$bubble->command_line(ciao => {text => [qw( whatever it is )],})],
   [qw( ciao --text whatever it is )],
   "runner's command line overriding with hash"
);

is_deeply(
   [$bubble->command_line()],
   [
      qw(
        bubble
        --text whatever
        --something-isolated
        --little-list what a mess
        )
   ],
   "runner's internal command line still safe"
);
