#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Differences;

BEGIN {
    use_ok( 'MarpaX::ESLIF::URI' ) || print "Bail out!\n";
}

my %DATA =
  (
   #
   # Adapted from http://www.scottseverance.us/mailto.html
   #
   "mailto:bogus\@email.com,bogus2\@email.com" => {
       scheme    => { origin => "mailto",                                 decoded => "mailto",                                 normalized => "mailto" },
       to        => { origin => ["bogus\@email.com","bogus2\@email.com"], decoded => ["bogus\@email.com","bogus2\@email.com"], normalized => ["bogus\@email.com","bogus2\@email.com"]},
   },
   "mailto:bogus\@email.com,bogus2\@email.com?subject=test" => {
       scheme    => { origin => "mailto",                                 decoded => "mailto",                                 normalized => "mailto" },
       to        => { origin => ["bogus\@email.com","bogus2\@email.com"], decoded => ["bogus\@email.com","bogus2\@email.com"], normalized => ["bogus\@email.com","bogus2\@email.com"]},
       headers   => {
           origin => [
               {subject => "test"}
               ],
           decoded => [
               {subject => "test"}
               ],
           normalized => [
               {SUBJECT => "test"}
               ]
       },
   },
   "mailto:bogus\@email.com,bogus2\@email.com?subject=test%20subject&body=This%20is%20the%20body%20of%20this%20message." => {
       scheme    => { origin => "mailto",                                 decoded => "mailto",                                 normalized => "mailto" },
       to        => { origin => ["bogus\@email.com","bogus2\@email.com"], decoded => ["bogus\@email.com","bogus2\@email.com"], normalized => ["bogus\@email.com","bogus2\@email.com"]},
       headers   => {
           origin => [
               {subject => "test%20subject"},
               {body => "This%20is%20the%20body%20of%20this%20message."}
               ],
           decoded => [
               {subject => "test subject"},
               {body => "This is the body of this message."}
               ],
           normalized => [
               {SUBJECT => "test%20subject"},
               {BODY => "This%20is%20the%20body%20of%20this%20message."}
               ]
       },
   }
  );

foreach my $origin (sort keys %DATA) {
  my $uri = MarpaX::ESLIF::URI->new($origin);
  isa_ok($uri, 'MarpaX::ESLIF::URI::mailto', "\$uri = MarpaX::ESLIF::URI->new('$origin')");
  my $methods = $DATA{$origin};
  foreach my $method (sort keys %{$methods}) {
    foreach my $type (sort keys %{$methods->{$method}}) {
      my $got = $uri->$method($type);
      my $expected = $methods->{$method}->{$type};
      my $test_name = "\$uri->$method('$type')";
      if (ref($expected)) {
        eq_or_diff($got, $expected, "$test_name is " . (defined($expected) ? (ref($expected) eq 'ARRAY' ? "[" . join(", ", map { "'$_'" } @{$expected}) . "]" : "$expected") : "undef"));
      } else {
        is($got, $expected, "$test_name is " . (defined($expected) ? "'$expected'" : "undef"));
      }
    }
  }
}

done_testing();
