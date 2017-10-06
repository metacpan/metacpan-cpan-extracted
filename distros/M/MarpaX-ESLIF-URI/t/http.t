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
   # Adapted from https://github.com/serut/vieassociative/blob/master/vendor/lusitanian/oauth/tests/Unit/Common/Http/Uri/UriTest.php
   #
   "http://example.com" => {
       scheme    => { origin => "http",                                 decoded => "http",                                 normalized => "http" },
       host      => { origin => "example.com",                          decoded => "example.com",                          normalized => "example.com" },
       path      => { origin => "",                                     decoded => "",                                     normalized => "/" },
   },
   "http://peehaa\@example.com" => {
       scheme    => { origin => "http",                                 decoded => "http",                                 normalized => "http" },
       host      => { origin => "example.com",                          decoded => "example.com",                          normalized => "example.com" },
       path      => { origin => "",                                     decoded => "",                                     normalized => "/" },
       userinfo  => { origin => "peehaa",                               decoded => "peehaa",                               normalized => "peehaa" },
   },
   "http://peehaa:pass\@example.com" => {
       scheme    => { origin => "http",                                 decoded => "http",                                 normalized => "http" },
       host      => { origin => "example.com",                          decoded => "example.com",                          normalized => "example.com" },
       path      => { origin => "",                                     decoded => "",                                     normalized => "/" },
       userinfo  => { origin => "peehaa:pass",                          decoded => "peehaa:pass",                          normalized => "peehaa:pass" },
   },
   #
   # Adapted from https://github.com/cpp-netlib/uri/blob/master/test/uri_parse_test.cpp
   #
   "http://www.example.com/path?qu\$ery" => {
       scheme    => { origin => "http",                                 decoded => "http",                                 normalized => "http" },
       host      => { origin => "www.example.com",                      decoded => "www.example.com",                      normalized => "www.example.com" },
       path      => { origin => "/path",                                decoded => "/path",                                normalized => "/path" },
       query     => { origin => "qu\$ery",                              decoded => "qu\$ery",                              normalized => "qu\$ery" },
   },
   "http://[1080:0:0:0:8:800:200C:417A]" => {
       scheme    => { origin => "http",                                 decoded => "http",                                 normalized => "http" },
       host      => { origin => "[1080:0:0:0:8:800:200C:417A]",         decoded => "[1080:0:0:0:8:800:200C:417A]",         normalized => "[1080:0:0:0:8:800:200c:417a]" },
       path      => { origin => "",                                     decoded => "",                                     normalized => "/" },
       ip        => { origin => "1080:0:0:0:8:800:200C:417A",           decoded => "1080:0:0:0:8:800:200C:417A",           normalized => "1080:0:0:0:8:800:200c:417a" },
       ipv6      => { origin => "1080:0:0:0:8:800:200C:417A",           decoded => "1080:0:0:0:8:800:200C:417A",           normalized => "1080:0:0:0:8:800:200c:417a" },
   },
   #
   # Adapted from http://www.gestioip.net/docu/ipv6_address_examples.html
   #
   "http://[2001:db8:a0b:12f0::1%25Eth0]:80/index.html" => {
       scheme    => { origin => "http",                                 decoded => "http",                                 normalized => "http" },
       host      => { origin => "[2001:db8:a0b:12f0::1%25Eth0]",        decoded => "[2001:db8:a0b:12f0::1%Eth0]",          normalized => "[2001:db8:a0b:12f0::1%25eth0]" },
       path      => { origin => "/index.html",                          decoded => "/index.html",                          normalized => "/index.html" },
       ip        => { origin => "2001:db8:a0b:12f0::1%25Eth0",          decoded => "2001:db8:a0b:12f0::1%Eth0",            normalized => "2001:db8:a0b:12f0::1%25eth0" },
       ipv6      => { origin => "2001:db8:a0b:12f0::1",                 decoded => "2001:db8:a0b:12f0::1",                 normalized => "2001:db8:a0b:12f0::1" },
       zone      => { origin => "Eth0",                                 decoded => "Eth0",                                 normalized => "eth0" },
   },
   "http://[2001:db8:a0b:12f0::1%Eth0]:80/index.html" => {
       scheme    => { origin => "http",                                 decoded => "http",                                 normalized => "http" },
       host      => { origin => "[2001:db8:a0b:12f0::1%Eth0]",          decoded => "[2001:db8:a0b:12f0::1%Eth0]",          normalized => "[2001:db8:a0b:12f0::1%25eth0]" },
       path      => { origin => "/index.html",                          decoded => "/index.html",                          normalized => "/index.html" },
       ip        => { origin => "2001:db8:a0b:12f0::1%Eth0",            decoded => "2001:db8:a0b:12f0::1%Eth0",            normalized => "2001:db8:a0b:12f0::1%25eth0" },
       ipv6      => { origin => "2001:db8:a0b:12f0::1",                 decoded => "2001:db8:a0b:12f0::1",                 normalized => "2001:db8:a0b:12f0::1" },
       zone      => { origin => "Eth0",                                 decoded => "Eth0",                                 normalized => "eth0" },
   },
  );

foreach my $origin (sort keys %DATA) {
  my $uri = MarpaX::ESLIF::URI->new($origin);
  isa_ok($uri, 'MarpaX::ESLIF::URI::http', "\$uri = MarpaX::ESLIF::URI->new('$origin')");
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
