# vim: filetype=perl :
use strict;
use warnings;
use Time::Local qw< timelocal timegm >;

#use Test::More tests => 38;    # last test to print

use Test::More 'no_plan';

my $start;
BEGIN { $start = time() }

use Log::Log4perl::Tiny qw( :levels );

use lib 't';
use TestLLT qw( set_logger log_is log_like );

my $logger = Log::Log4perl::Tiny::get_logger();
ok($logger, 'got a logger instance');

$logger->level($INFO);
set_logger($logger);

my $hostname = eval {
   require Sys::Hostname;
   Sys::Hostname::hostname();
} || '';

my @tests = (
   ['%C', ['whatever'], 'main'],
   ['%F', ['whatever'], qr{\At[/\\]32\.caller_depth\.t\z}],
   [
      '%l', ['whatever'],
      qr{\Amain::__ANON__ t[/\\]32\.caller_depth\.t \(\d+\)\z}
   ],
   ['%L', ['whatever'], qr{\A\d+\z}],
   ['%M', ['whatever'], 'main::__ANON__'],
   [
      '%T', ['whatever'],
      qr{(?mxs:
         \A
            main::__ANON__ .*? called\ at\ t[/\\]TestLLT.*
            ,\ TestLLT::log_like .*? called\ at\ t[/\\]32\.caller_depth\.t
            \ line\ \d+
         )}
   ],

   ['%C', ['whatever'], 'TestLLT', 1],
   ['%F', ['whatever'], qr{\At[/\\]TestLLT\.pm\z}, 1],
   [
      '%l', ['whatever'],
      qr{\ATestLLT::log_like t[/\\]TestLLT\.pm \(\d+\)\z}, 1
   ],
   ['%L', ['whatever'], qr{\A\d+\z},      1],
   ['%M', ['whatever'], 'TestLLT::log_is', 1],
   [
      '%T', ['whatever'],
      qr{(?mxs:
         \A
            TestLLT::log_like\( .* called
            \ at\ t[/\\]32\.caller_depth\.t\ line\ \d+
         )},
      1
   ],
);

for my $test (@tests) {
   my ($format, $input, $output, $depth) = @$test;
   local $Log::Log4perl::Tiny::caller_depth = $depth ||= 0;
   $logger->format($format);
   $output = $output->() if ref($output) eq 'CODE';
   if (ref $output) {
      log_like { $logger->info(@$input) } $output,
        "depth: $depth format: '$format'";
   }
   else {
      log_is { $logger->info(@$input) } $output,
        "depth: $depth format: '$format'";
   }
} ## end for my $test (@tests)
