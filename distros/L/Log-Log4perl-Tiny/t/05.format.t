# vim: filetype=perl :
use strict;
use warnings;
use Time::Local qw< timelocal timegm >;

use Test::More tests => 38;    # last test to print

#use Test::More 'no_plan';

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
   ['%c', ['whatever'], 'main'],
   ['%C', ['whatever'], 'main'],
   ['%d', ['whatever'], qr{\A\d{4}/\d\d/\d\d \d\d:\d\d:\d\d\z}],
   [
      '%D', ['whatever'],
      qr<\A\d{4}-\d\d-\d\d \d\d:\d\d:\d\d.\d{6}[-+]\d{4}\z>
   ],
   [
      '%{utc}D', ['whatever'],
      qr<\A\d{4}-\d\d-\d\d \d\d:\d\d:\d\d.\d{6}\+0000\z>
   ],
   [
      '%{local}D', ['whatever'],
      qr<\A\d{4}-\d\d-\d\d \d\d:\d\d:\d\d.\d{6}[-+]\d{4}\z>
   ],
   ['%F', ['whatever'], qr{\At[/\\]05\.format\.t\z}],
   ['%H', ['whatever'], $hostname],
   [
      '%l', ['whatever'],
      qr{\Amain::__ANON__ t[/\\]05\.format\.t \(\d+\)\z}
   ],
   ['%L', ['whatever'], qr{\A\d+\z}],
   ['%m', [qw( frozz buzz )], 'frozzbuzz'],
   ['%M', ['whatever'], 'main::__ANON__'],
   ['%n', ['whatever'], "\n"],
   ['%p', ['whatever'], 'INFO'],
   ['%P', ['whatever'], $$],
   ['%r', ['whatever'], qr{\A\d+\z}],
   ['%R', ['whatever'], qr{\A\d+\z}],
   [
      '%T', ['whatever'],
      qr{(?mxs:
         \A
            main::__ANON__ .*? called\ at\ t[/\\]TestLLT.*
            ,\ TestLLT::log_like .*? called\ at\ t[/\\]05\.format\.t
            \ line\ \d+
         )}
   ],
   ['%m%n', [qw( foo bar )], "foobar$/"],
   [
      '[%d] [%-5p] %m%n',
      ['whatever', 'you', 'like'],
qr{\A\[\d{4}/\d\d/\d\d \d\d:\d\d:\d\d\] \[INFO \] whateveryoulike\n\z}
   ],
   ['%{}n', ['whatever'], "%{}n"],
   ['%%n',  ['whatever'], "%n"],
   ['%%',   ['whatever'], "%"],
   ['%',    ['whatever'], "%"],
);

for my $test (@tests) {
   my ($format, $input, $output) = @$test;
   $logger->format($format);
   $output = $output->() if ref($output) eq 'CODE';
   if (ref $output) {
      log_like { $logger->info(@$input) } $output, "format: '$format'";
   }
   else {
      log_is { $logger->info(@$input) } $output, "format: '$format'";
   }
} ## end for my $test (@tests)

# Ensure that %n is not dependent on $/ or $\
{
   local $/;
   local $\;
   $logger->format('%n');
   log_is { $logger->info('whatever') } "\n",
     'format: "%n" with $/ and $\ undefined';
}

{
   my $collector = '';
   open my $fh, '>', \$collector;
   $logger->fh($fh);
   $logger->format('%D%n%{utc}D%n%{local}D');
   $logger->info('whatever');
   close $fh;

   my ($default, $utc, $local) = split /\n/, $collector;
   is $default, $local, 'default and local are the same';

   my @ts = map {
      my @time = m{
         (\d+) - (\d+) - (\d+)  # date
         \s+
         (\d+) : (\d+) : (\d+)  # time
      }mxs;
      $time[0] -= 1900;
      $time[1]--;
      [reverse @time];
   } ($utc, $local);

   is_deeply timegm(@{$ts[0]}), timelocal(@{$ts[1]}),
     'local and UTC refer to same time';
}

# Ensure %r and %R return milliseconds
{
   sleep 1
     while time() <= $start + 2;    # ensure we go beyond 1000 milliseconds
      # 2015-01-01 we have to sleep until we go around 2000 milliseconds to
    # be sure we are beyond 1000 milliseconds, got one test complain because
    # we arrived at 999 (on Windows).

   my $collector = '';
   open my $fh, '>', \$collector;
   $logger->fh($fh);
   $logger->format('%r %R');
   $logger->info('whatever');
   close $fh;

   my $stop  = time();
   my $upper = (1 + $stop - $start) * 1000;

   my ($r, $R) = split /\s/, $collector;
   like($r, qr/\A\d+\z/, '%r has only digits');
   like($R, qr/\A\d+\z/, '%R has only digits');
   ok($r >= $R, "%r ($r) is greater or equal to %R ($R)");
   ok($r >= 1000,
      "%r ($r) is greater than or equal to 1000 (waited one second)");
   ok($r < $upper,
      "%r ($r) is lower than other milliseconds benchmark ($upper)");
   ok($R >= 1000, "%R ($R) is greater than or equal to 1000");
}

# Ensure %R gets reset
{
   my $collector = '';
   open my $fh, '>', \$collector;
   $logger->fh($fh);
   $logger->format('%r %R');
   $logger->info('whatever');
   close $fh;

   my $stop  = time();
   my $upper = (1 + $stop - $start) * 1000;

   my ($r, $R) = split /\s/, $collector;
   ok($r >= $R + 1000, "new call, %r ($r) is 'much' greater than %R ($R)");
}

# Extension: %e
for my $test (
   ['%{foo}e', {foo => 'bar'}, 'bar'],
   [
      '%{foo-sub}e',
      {
         'foo-sub' => sub { 'bar' }
      },
      'bar'
   ],
   [
      '%{foo-sub-tod}e',
      {
         'foo-sub-tod' => sub { return join '.', @{$_[0]{tod}} }
      },
      qr{(?mxs: \A \d+ \. \d+ \z)},
   ],
  )
{
   my ($format, $locals, $expected) = @$test;

   delete $logger->{loglocals};
   $logger->loglocal($_ => $locals->{$_}) for keys %$locals;

   my $collector = '';
   open my $fh, '>', \$collector;
   $logger->fh($fh);
   $logger->format($format);
   $logger->info('whatever');
   close $fh;

   ref($expected)
     ? like($collector, $expected, $format)
     : is($collector, $expected, $format);
} ## end for my $test (['%{foo}e'...])
