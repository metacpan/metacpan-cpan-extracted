package Other;

use strict;
use warnings;

use base 'Froody::API';

# okay, this is a 'by hand' definition, where we declare the method
# details very slowly in perl space rather than using XML

sub load {
  my $class = shift;
  return (
  Froody::Method
    ->new()
    ->full_name('other.object.method')
    ->arguments({
      one => {
        optional => '0',
        type => ['text'],
        multiple => '0',
        documentation => 'simple value',
      },
      two => {
        optional => '1',
        type => ['text'],
        multiple => '1',
        documentation => 'multiple value',
      }})
    ->structure({
        value => {
          text => 1,
          elts => [],
          attr => [],
        }
      })
    ->needslogin(0)
    ->description('Simple test method')
  );
}

1;
