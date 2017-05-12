package Mail::LMLM::Object;

use strict;
use warnings;

sub new
{
    my $class = shift;
    my $self = {};

    bless($self, $class);

    $self->initialize(@_);

    return $self;
}

sub initialize
{
    my $self = shift;

    return 0;
}

sub destroy_
{
    my $self = shift;

    return 0;
}

sub DESTROY
{
    my $self = shift;

    $self->destroy_();
}

1;

__END__

=head1 Mail::LMLM::Object

Warning! This is an internal Mail::LMLM class. It is used as the base class
for all LMLM objects.

=head1 FUNCTIONS

=head2 new

The default constructor.

=head2 $self->initialize(@args)

Should be over-rided to initialize the object.

=head2 $self->destroy_()

Destroys the object.

=head2 DESTROY

the default destructor.

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>.
