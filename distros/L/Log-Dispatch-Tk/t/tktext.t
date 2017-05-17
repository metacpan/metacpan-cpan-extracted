# -*- cperl -*-
use warnings FATAL => qw(all);
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use strict;
use Test::More ;

use Tk ;

use ExtUtils::testlib;
use Log::Dispatch;
use Log::Dispatch::TkText ;

my $mw = eval { MainWindow->new };
plan skip_all => "Cannot create main window: $@" if !$mw;
plan tests => 2;

# See https://rt.cpan.org/Ticket/Display.html?id=121483
$mw->geometry('+10+10'); # for twm

my $arg = shift || '';
my $keep_running = $arg =~ /i/ ;

my $dispatch = Log::Dispatch->new;

ok($dispatch) ;

my $tklog = $mw->Scrolled('LogText', name => 'tk',
                          min_level => 'debug');
$tklog -> pack ;

ok($tklog) ;

$dispatch->add($tklog->logger) ;

$dispatch->log(
    level => 'info',
    message => "Test exits after 5s unless the script is invoked with 'i' argument\n"
        . "E.g. 'perl -Ilib $0 i'\n"
        . "You can use <Button-3> Filter menu to filter log levels\n"
        . "Please use <Button-3> File->exit to finish the test"
    );

$dispatch -> log 
  (
   level => 'crit',
   message => "critical message using abbreviated form (3)"
   );

$dispatch -> log 
  (
   level => 3,
   message => "message using numeric levels (level 3 in this case)"
   );



foreach my $level ($tklog->logger->all_levels())
  {
    $dispatch -> log (level => $level, message => "some $level bla-bla") ;
    my $nb = $tklog->logger -> _level_as_number($level); # naughty ...
    $dispatch -> log (level => $level, message => "some level $nb bla-bla") ;
  }

foreach my $level ($tklog->logger->all_levels())
  {
    $dispatch -> log (level => $level, message => "another very long $level bla-bla\nWell, not so long\n") ;
  }

$mw->after(5000, sub { $mw->destroy;}) unless $keep_running;

MainLoop ; # Tk's
