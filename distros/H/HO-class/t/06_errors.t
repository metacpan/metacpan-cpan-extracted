
use strict;
use warnings;

use Test::More tests => 1;
use Carp;

require HO::accessor;

eval <<'__PERL__';
    no strict 'refs';
    no warnings 'redefine';
    package Unknown::Type;
    local *{'Carp::carp'};
    BEGIN {
      # an unknown type produces only a warning
      *{'Carp::carp'} = \&Carp::croak;
    };
    use HO::class
        _ro => 'name' => 'undef';  
__PERL__

like($@,qr/Unknown property type 'undef', in setup for class Unknown::Type\./,
  'warning for unknown type');


