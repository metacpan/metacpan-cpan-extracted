## no critic
package Make::Rule::Vars;

our $VERSION = '1.2.0';

use strict;
use warnings;
use Carp;

# Package to handle 'magic' variables pertaining to rules e.g. $@ $* $^ $?
# by using tie to this package 'subsvars' can work with array of
# hash references to possible sources of variable definitions.

sub TIEHASH {
    my ( $class, $rule ) = @_;
    return bless \$rule, $class;
}

sub FETCH {
    my $self = shift;
    local $_ = shift;
    my $rule = $$self;
    return unless (/^[\@^<?*]$/);

    # print STDERR "FETCH $_ for ",$rule->Name,"\n";
    return $rule->Name if ( $_ eq '@' );
    return $rule->Base if ( $_ eq '*' );
    return join( ' ', $rule->exp_depend )  if ( $_ eq '^' );
    return join( ' ', $rule->out_of_date ) if ( $_ eq '?' );

    # Next one is dubious - I think $< is really more subtle ...
    return ( $rule->exp_depend )[0] if ( $_ eq '<' );
    return;
}

1;
