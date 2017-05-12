package Embedix::ECD::Group;

use strict;
use vars qw(@ISA);

@ISA = qw(Embedix::ECD);

# I imagine different types of ECD nodes may have different attributes.
# I hope I'm right.

#
#_______________________________________
sub toString {
    my $self = shift;
    my $opt  = $self->getFormatOptions(@_);

    return
        $opt->{space} . "<GROUP " . $self->name . ">\n" . 
            $self->attributeToString($opt) .    # for the attributes
            $self->SUPER::toString(@_) .        # for the children
        $opt->{space} . "</GROUP>\n"
}

1;

__END__

=head1 NAME

Embedix::ECD::Group - an object for GROUP nodes

=head1 SYNOPSIS

    my $ecd = Embedix::ECD::Group->new();

=head1 DESCRIPTION

Embedix::ECD::Group is a subclass of Embedix::ECD for representing
GROUP nodes.  It differs from its superclass in the following ways.

=head2 Differences

=over 4

=item it doesn't (yet) except in name

=back

=head1 AUTHOR

John BEPPU <beppu@lineo.com>

=head1 SEE ALSO

Embedix::ECD(3pm)

=cut

# $Id: Group.pm,v 1.1 2001/01/19 00:26:38 beppu Exp $
