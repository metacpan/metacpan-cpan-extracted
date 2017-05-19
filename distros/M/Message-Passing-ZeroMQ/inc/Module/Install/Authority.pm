#line 1
package Module::Install::Authority;
use strict;
use warnings;
use base qw/Module::Install::Base/;

our $VERSION = '0.03';
$VERSION = eval $VERSION;

sub authority {
    my $self = shift;
    my $pause_id = shift;
    $self->Meta->{values}->{x_authority} = $pause_id;
}

1;

#line 69

