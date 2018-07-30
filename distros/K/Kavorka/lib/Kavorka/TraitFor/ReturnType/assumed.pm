use 5.014;
use strict;
use warnings;

package Kavorka::TraitFor::ReturnType::assumed;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.039';

use Moo::Role;
use Types::Standard qw(Any);

around _effective_type => sub { Any };

1;
