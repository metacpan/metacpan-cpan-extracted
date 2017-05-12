# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Math-Telephony-ErlangC.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 100;
#use Test::More 'no_plan';

BEGIN { use_ok('Math::Telephony::ErlangC') }

use Math::Telephony::ErlangC qw(:all);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Just call each function at least once
{
   my $wprob = wait_probability(1, 2);
   ok(($wprob > 0 && $wprob < 1), "wait_probability()");
   is(servers_waitprob(0.1, 0.9), 1, "servers_wait()");
   ok(traffic_waitprob(1, 0.1), "traffic_wait()");

   my $mtprob = maxtime_probability(1, 2, 0.1, 1);
   ok(($mtprob > 0 && $mtprob < 1), "maxtime_probability()");
   is(servers_maxtime(0.1, 0.9, 0.1, 1), 1, "servers_maxtime()");
   ok(traffic_maxtime(1, 0.1, 0.1, 1), "traffic_maxtime()");
   ok(service_time_maxtime(0.5, 1, 0.9, 1) > 0, "service_time_maxtime()");
   ok(max_time_maxtime(0.5, 1, 0.9, 0.1) > 0, "max_time_maxtime()");

   my $awt = average_wait_time(0.5, 1, 0.1);
   ok($awt > 0, "average_wait_time()");
   is(servers_waittime(1, 4, 0.1), 2, "servers_wait_time()");
   ok(traffic_waittime(1, 4, 0.1), "traffic_wait_time()");
   ok(service_time_waittime(0.5, 1, 0.1), "service_time_waittime()");
}

# Edge cases
my %values = (
   servers => {
      strict => [1, 2, 3],
      edge   => [0],
      illegal => [undef, -1, -0.3, 1.5],
   },
   traffic => {
      strict => [1, 2, 3, 4.5],
      edge   => [0],
      illegal => [undef, -1, -0.3],
   },
   probability => {
      strict => [0.001, 0.1, 0.3, 0.5, 0.7, 0.9, 0.999],
      edge   => [0,     1],
      illegal => [undef, -1, -0.3, 1.1, 10],
   },
   time => {
      strict => [0.001, 0.5, 1, 3],
      edge   => [0],
      illegal => [-2, -1, -0.001],
   },
   precision => {
      strict => [undef, 0.001, 0.5],
      edge   => [],
      illegal => [-1, 0],
   }
);

foreach my $href (values %values) {
   push @{$href->{all}}, @$_ foreach values %$href;
   push @{$href->{ok}}, @{$href->{strict}}, @{$href->{edge}};
}

my @prototypes = (
   [qw( wait_probability traffic servers )],
   [qw( servers_waitprob traffic probability )],
   [qw( traffic_waitprob servers probability precision)],

   [qw( maxtime_probability traffic servers time time )],
   [qw( servers_maxtime traffic probability time time )],
   [qw( traffic_maxtime servers probability time time precision )],
   [qw( service_time_maxtime traffic servers probability time )],
   [qw( max_time_maxtime traffic servers probability time )],

   [qw( average_wait_time traffic servers time )],
   [qw( servers_waittime traffic time time )],
   [qw( traffic_waittime servers time time precision )],
   [qw( service_time_waittime traffic servers time )],
);
my %prototypes = map { my ($f, @p) = @$_; $f => \@p } @prototypes;

foreach my $spec (@prototypes) {
   my ($name, @types) = @$spec;
   my $edge_cases;
   $edge_cases = $edges{$name} if exists $edges{$name};

   for (0 .. $#types) {
      # Test out-of-edge cases, i.e. cases for inputs that are
      # out of the domain
      my @args = map { $values{$_}{all} } @types;
      $args[$_] = $values{$types[$_]}{illegal};
      next unless @{$args[$_]};
      test_edge("$name with illegal parameter no. ${_} ($types[$_]) is undef",
                $name, undef, @args);
   } ## end for (0 .. $#types)
} ## end foreach my $spec (@prototypes)

my $edge_tests =<<EOF ;
wait_probability 0 0 ok
wait_probability 1 strict 0

servers_waitprob 0 0 ok
servers_waitprob 0 strict 1

traffic_waitprob 0 0 ok ok
traffic_waitprob 0 ok 0 ok
traffic_waitprob undef strict 1 ok

maxtime_probability 1 0 ok ok ok
maxtime_probability 0 strict 0 ok ok
maxtime_probability 1 strict strict 0 ok
maxtime_probability 0 strict strict strict 0

servers_maxtime 0 0 ok ok ok
servers_maxtime 1 strict ok 0 ok
servers_maxtime undef strict 0 strict ok
servers_maxtime undef strict strict strict 0

traffic_maxtime 0 0 ok ok ok ok
traffic_maxtime 0 ok 0 ok ok ok
traffic_maxtime undef strict strict 0 ok ok
traffic_maxtime undef strict strict strict 0 ok

service_time_maxtime 0 0 ok ok ok
service_time_maxtime undef strict 0 ok ok
service_time_maxtime 0 strict strict 0 ok
service_time_maxtime undef strict strict 1 ok
service_time_maxtime 0 strict strict strict 0

max_time_maxtime 0 0 ok ok ok
max_time_maxtime undef strict 0 ok ok
max_time_maxtime 0 strict strict ok 0
max_time_maxtime 0 strict strict 0 strict
max_time_maxtime undef strict strict 1 strict
max_time_maxtime undef 3 3 strict strict

average_wait_time 0 0 ok ok
average_wait_time undef strict 0 ok
average_wait_time 0 strict strict 0
average_wait_time undef 3 3 strict

servers_waittime 0 0 ok ok
servers_waittime 1 strict ok 0
servers_waittime undef strict 0 strict

traffic_waittime 0 0 ok ok ok
traffic_waittime undef strict 0 ok ok
traffic_waittime undef strict ok 0 ok

service_time_waittime 0 0 ok ok
service_time_waittime undef strict 0 ok
service_time_waittime 0 strict strict 0
service_time_waittime undef 3 3 strict
EOF

foreach my $test (split /\n/, $edge_tests) {
   next unless $test =~ /\S/;
   my ($function, $result, @args) = split /\s+/, $test;
   my @fargs = @{$prototypes{$function}};
   my @pargs;
   foreach my $index (0 .. $#fargs ) {
      if ($args[$index] =~ /\d/) {
         push @pargs, $args[$index];
         $args[$index] = [ $args[$index] ];
      }
      elsif ($args[$index] eq 'undef') {
         push @pargs, 'undef';
         $args[$index] = [undef];
      }
      else {
         push @pargs, "<$args[$index]>";
         $args[$index] = $values{$fargs[$index]}{$args[$index]}
      }
   }
   my $msg = "$function(" . (join ", ", @pargs) . ") is $result";
   $result = undef if $result eq 'undef';
   test_edge($msg, $function, $result, @args);
}

sub equality_test {
   my ($got, $expect) = @_;
   return (!defined $got && !defined $expect)
     if (!defined $got || !defined $expect);
   return $got eq $expect;
} ## end sub equality_test

sub test_edge {
   my ($msg, $subname, $result, @valrefs) = @_;
   my (@args, @strargs, @stack);
   my $stringify   = sub { defined $_[0] ? $_[0] : 'undef' };
   my $presult     = $stringify->($result);
   my @lengths     = map { scalar @$_ } @valrefs;
   my $just_popped = 0;
   my $all_ok      = 1;
   while (@stack || !$just_popped) {

      # Grab "next" element
      if (scalar @stack == scalar @valrefs) {
         no strict 'subs';
         local $" = ', ';
         my $retval = $subname->(@args);
         unless (equality_test($retval, $result)) {
            is($retval, $result, "$subname(@strargs) is $presult");
            $all_ok = 0;
         }
      } ## end if (scalar @stack == scalar...

      if ($just_popped || scalar @stack == scalar @valrefs) {
         if (++$stack[-1] == $lengths[$#stack]) {    # Past last
            pop @stack;
            pop @args;
            pop @strargs;
            $just_popped = 1;
         } ## end if (++$stack[-1] == $lengths...
         else {
            $args[-1]    = $valrefs[$#stack][$stack[-1]];
            $strargs[-1] = $stringify->($args[-1]);
            $just_popped = 0;                               # Reset flag
         }
      } ## end if ($just_popped || scalar...
      else {                                                # Add a brick
         push @args,    $valrefs[@stack][0];
         push @strargs, $stringify->($args[-1]);
         push @stack,   0;
      }
   } ## end while (@stack || !$just_popped)
   $msg = "$subname for some input" unless defined $msg && length $msg;
   ok($all_ok, $msg);
} ## end sub test_edge

# Test data
is(servers_waittime(27.083, 5, 150), 34, "servers_waittime");
is(servers_maxtime(27.083, 0.94, 150, 20), 34, "servers_maxtime");

