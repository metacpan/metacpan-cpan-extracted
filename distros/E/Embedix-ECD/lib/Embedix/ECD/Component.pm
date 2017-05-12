package Embedix::ECD::Component;

use strict;
use vars qw(@ISA);
use Embedix::ECD::Util qw(indent %default @attribute_order);

@ISA = qw(Embedix::ECD);

# I imagine different types of ECD nodes may have different attributes.
# I hope I'm right.

#
#_______________________________________
sub toString {
    my $self = shift;
    my $opt  = $self->getFormatOptions(@_);

    return
        $opt->{space} . "<COMPONENT " . $self->name . ">\n" . 
            $self->attributeToString($opt) .    # for the attributes
            $self->SUPER::toString(@_) .        # for the children
        $opt->{space} . "</COMPONENT>\n"
}

1;

__END__

=head1 NAME

Embedix::ECD::Component - an object for COMPONENT nodes

=head1 SYNOPSIS

    my $ecd = Embedix::ECD::Component->new();

=head1 DESCRIPTION

Embedix::ECD::Component is a subclass of Embedix::ECD for representing
COMPONENT nodes.  It differs from its superclass in the following ways.

=head2 Differences

=over 4

=item it doesn't (yet) except in name

=back

=head1 AUTHOR

John BEPPU <beppu@lineo.com>

=head1 SEE ALSO

Embedix::ECD(3pm)

=cut

# $Id: Component.pm,v 1.1 2001/01/19 00:26:38 beppu Exp $
