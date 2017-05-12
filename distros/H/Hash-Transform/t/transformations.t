#!perl -T

use Test::More tests => 3;

BEGIN {
  use_ok( 'Hash::Transform' );
}


my %rules
  = (
     foo_field => 'foo',
     bar_field => 'bar',
     name      => [' ', \'Name:', 'first', 'last'],
     constant  => \'42',
     friend    => sub {
       my $data = shift;
       my $fullname = join (' ', @$data{'first','last'});
       return 'Ford' if $fullname eq 'Arthur Dent';
       return 'Arthur' if $fullname eq 'Ford Prefect';
       return 'No friends';
     },
    );

my @tests
  = (
     [
      'example',
      {
       foo   => 'hello',
       bar   => 'goodbye',
       first => 'Arthur',
       last  => 'Dent',
      },
      {
       foo_field => 'hello',
       bar_field => 'goodbye',
       name      => 'Name: Arthur Dent',
       constant  => '42',
       friend    => 'Ford',
      },
     ],
    );


my $transform = Hash::Transform->new(\%rules);

ok($transform, "instatiation");

for my $test (@tests) {
  my ($name, $original_data, $expected_result) = @$test;
  my $result = $transform->apply($original_data);
  is_deeply($result, $expected_result, "transformation $name");
}
