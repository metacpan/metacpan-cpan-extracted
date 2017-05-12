
package HTML::TagClouder::Collection;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
use Class::C3;

__PACKAGE__->mk_accessors($_) for qw(iterator_class cloud);

sub new
{
    my $class = shift;
    return $class->next::method({ @_ });
}

sub sort {}
sub add { die "add() not implemented" }

sub iterator
{
    my $self = shift;
    return $self->iterator_class()->new($self);
}

1;

__END__

=head1 NAME

HTML::TagClouder::Collection - Base Collection Class

=head1 METHODS

=head2 new %args

=over 4

=item iterator_class

The name of the iterator class that will be created upon call to iterator()

=back

=head2 sort

=head2 add

Adds a tag.

=head2 iterator

Creates an iterator for this collection

=cut
