package Embedix::ECD::Option;

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
        "\n".
        $opt->{space} . "<OPTION " . $self->name . ">\n" . 
            $self->attributeToString($opt) .    # for the attributes
            $self->SUPER::toString(@_) .        # for the children
        $opt->{space} . "</OPTION>\n"
}

1;

__END__

=head1 NAME

Embedix::ECD::Option - an object for OPTION nodes

=head1 SYNOPSIS

    my $ecd = Embedix::ECD::Option->new();

=head1 DESCRIPTION

Embedix::ECD::Option is a subclass of Embedix::ECD for representing
OPTION nodes.  It differs from its superclass in the following ways.

=head2 Differences

=over 4

=item it doesn't (yet) except in name

=back

=head1 AUTHOR

John BEPPU <beppu@lineo.com>

=head1 SEE ALSO

Embedix::ECD(3pm)

=cut

# $Id: Option.pm,v 1.2 2001/02/12 20:50:58 beppu Exp $
