#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Differences;
use Data::Dumper::OneLine qw/Dumper/;

BEGIN {
    use_ok( 'MarpaX::ESLIF::URI' ) || print "Bail out!\n";
}

my %DATA =
  (
   #
   # Adapted from http://www.scottseverance.us/mailto.html
   #
   "Tel:+358-9-123-45678" => {
       scheme         => {              origin => "Tel",              decoded => "Tel",              normalized => "tel" },
       number         => {              origin => "+358-9-123-45678", decoded => "+358-9-123-45678", normalized => "+358912345678"},
       is_global      => 1,
       is_local       => undef,
       has_npdi       => undef,
       has_enumdi     => undef
   },
   "Tel:(4)-5.678;PHONE-CONTEXT=Example.Com" => {
       scheme         => {              origin => "Tel",              decoded => "Tel",              normalized => "tel" },
       number         => {              origin => "(4)-5.678",        decoded => "(4)-5.678",        normalized => "45678"},
       phone_context  => {              origin => "Example.Com",      decoded => "Example.Com",      normalized => "example.com"},
       parameters     =>
       {
           origin     =>   [ { key => "PHONE-CONTEXT", value => "Example.Com" } ],
           decoded    =>   [ { key => "PHONE-CONTEXT", value => "Example.Com" } ],
           normalized =>   [ { key => "phone-context", value => "example.com" } ]
       },
       is_global      => undef,
       is_local       => 1,
       has_npdi       => undef,
       has_enumdi     => undef
   },
   "tel:+1-800-123-4567;CIC=+1-6789" => {
       scheme         => {              origin => "tel",              decoded => "tel",              normalized => "tel" },
       number         => {              origin => "+1-800-123-4567",  decoded => "+1-800-123-4567",  normalized => "+18001234567"},
       cic            => {              origin => "+1-6789",          decoded => "+1-6789",          normalized => "+16789"},
       parameters     =>
       {
           origin     =>   [ { key => "CIC", value => "+1-6789" } ],
           decoded    =>   [ { key => "CIC", value => "+1-6789" } ],
           normalized =>   [ { key => "cic", value => "+16789" } ]
       },
       is_global      => 1,
       is_local       => undef,
       has_npdi       => undef,
       has_enumdi     => undef
   },
   "tel:+1-202-533-1234;npdi;rn=+1-202-544-0000" => {
       scheme         => {              origin => "tel",              decoded => "tel",              normalized => "tel" },
       number         => {              origin => "+1-202-533-1234",  decoded => "+1-202-533-1234",  normalized => "+12025331234"},
       rn             => {              origin => "+1-202-544-0000",  decoded => "+1-202-544-0000",  normalized => "+12025440000"},
       parameters     =>
       {
           origin     =>   [ { key => 'npdi', value => undef }, { key => "rn", value => "+1-202-544-0000" } ],
           decoded    =>   [ { key => 'npdi', value => undef }, { key => "rn", value => "+1-202-544-0000" } ],
           normalized =>   [ { key => 'npdi', value => undef }, { key => "rn", value => "+12025440000" } ]
       },
       is_global      => 1,
       is_local       => undef,
       has_npdi       => 1,
       has_enumdi     => undef
   },
   "tel:+1-202-533-6789;npdi" => {
       scheme         => {              origin => "tel",              decoded => "tel",              normalized => "tel" },
       number         => {              origin => "+1-202-533-6789",  decoded => "+1-202-533-6789",  normalized => "+12025336789"},
       parameters     =>
       {
           origin     =>   [ { key => 'npdi', value => undef } ],
           decoded    =>   [ { key => 'npdi', value => undef } ],
           normalized =>   [ { key => 'npdi', value => undef } ]
       },
       is_global      => 1,
       is_local       => undef,
       has_npdi       => 1,
       has_enumdi     => undef
   },
   "tel:+1-202-533-6789;isub-encoding=nsap-ia5" => {
       scheme         => {              origin => "tel",              decoded => "tel",              normalized => "tel" },
       number         => {              origin => "+1-202-533-6789",  decoded => "+1-202-533-6789",  normalized => "+12025336789"},
       isub_encoding  => {              origin => "nsap-ia5",         decoded => "nsap-ia5",         normalized => "nsap-ia5"},
       parameters     =>
       {
           origin     =>   [ { key => 'isub-encoding', value => "nsap-ia5" } ],
           decoded    =>   [ { key => 'isub-encoding', value => "nsap-ia5" } ],
           normalized =>   [ { key => 'isub-encoding', value => "nsap-ia5" } ]
       },
       is_global      => 1,
       is_local       => undef,
       has_npdi       => undef,
       has_enumdi     => undef
   },
   "tel:+1-202-533-6789;enumdi" => {
       scheme         => {              origin => "tel",              decoded => "tel",              normalized => "tel" },
       number         => {              origin => "+1-202-533-6789",  decoded => "+1-202-533-6789",  normalized => "+12025336789"},
       parameters     =>
       {
           origin     =>   [ { key => 'enumdi', value => undef } ],
           decoded    =>   [ { key => 'enumdi', value => undef } ],
           normalized =>   [ { key => 'enumdi', value => undef } ]
       },
       is_global      => 1,
       is_local       => undef,
       has_npdi       => undef,
       has_enumdi     => 1
   },
   "tel:5550100;phone-context=+1-630;tgrp=TG-1;trunk-context=Example.com" => {
       scheme         => {              origin => "tel",              decoded => "tel",              normalized => "tel" },
       number         => {              origin => "5550100",          decoded => "5550100",          normalized => "5550100"},
       phone_context  => {              origin => "+1-630",           decoded => "+1-630",           normalized => "+1630"},
       parameters     =>
       {
           origin     =>   [ { key => "phone-context", value => "+1-630" }, { key => 'tgrp', value => 'TG-1'}, { key => 'trunk-context', value => 'Example.com'} ],
           decoded    =>   [ { key => "phone-context", value => "+1-630" }, { key => 'tgrp', value => 'TG-1'}, { key => 'trunk-context', value => 'Example.com'} ],
           normalized =>   [ { key => "phone-context", value => "+1630" },  { key => 'tgrp', value => 'tg-1'}, { key => 'trunk-context', value => 'example.com'} ],
       },
       is_global      => undef,
       is_local       => 1
   }
  );

foreach my $origin (sort keys %DATA) {
  my $uri = MarpaX::ESLIF::URI->new($origin);
  isa_ok($uri, 'MarpaX::ESLIF::URI::tel', "\$uri = MarpaX::ESLIF::URI->new('$origin')");
  my $methods = $DATA{$origin};
  foreach my $method (sort keys %{$methods}) {
      if (ref($methods->{$method}) eq 'HASH') {
          foreach my $type (sort keys %{$methods->{$method}}) {
              my $got = $uri->$method($type);
              my $expected = $methods->{$method}->{$type};
              my $test_name = "\$uri->$method('$type')";
              if (ref($expected)) {
                  eq_or_diff($got, $expected, "$test_name is " . (defined($expected) ? Dumper($expected) : "undef"));
              } else {
                  is($got, $expected, "$test_name is " . (defined($expected) ? "'$expected'" : "undef"));
              }
          }
      } else {
          my $got = $uri->$method;
          my $expected = $methods->{$method};
          my $test_name = "\$uri->$method()";
          if (ref($expected)) {
              eq_or_diff($got, $expected, "$test_name is " . (defined($expected) ? Dumper($expected) : "undef"));
          } else {
              is($got, $expected, "$test_name is " . (defined($expected) ? "'$expected'" : "undef"));
          }
      }
  }
}

done_testing();
