package FLAT::Regex::Transform;

# Extends FLAT::Regex::WithExtraOps with PRegex transformations 
# (i.e., reductions based on: w*v & a*b

use base 'FLAT::Regex::WithExtraOps';

sub new {
    my $pkg = shift;
    my $self = $pkg->SUPER::new(@_);
    return $self;
}

# Ideally, the transformation should be implemented as an iterator.  This
# approach will be finite for shuffles with NO closed strings, but will carry on
# indefinitely for the shuffle of strings where at least one of the strings is closed

1;
