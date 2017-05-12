package M3::ServerView::ResultSet;

use strict;
use warnings;

use Carp qw(croak);

use Scalar::Util qw(refaddr);

sub new {
    my ($pkg, $records) = @_;
    
    $records = [] unless defined $records;
    
    croak "Not an array reference" unless ref $records eq "ARRAY";
    
    my $self = bless $records, $pkg;
    $self->reset();
    
    return $self;
}

{
    my %Position;
    sub reset {
        my ($self) = @_;
        $Position{refaddr $self} = 0;
    }

    sub next {
        my ($self) = @_;
        return if $Position{refaddr $self} >= @$self;
        return $self->[$Position{refaddr $self}++];
    }
}

sub all {
    my ($self) = @_;
    return @$self;
}

sub first {
    my ($self) = @_;
    return $self->[0];
}

sub count {
    my ($self) = @_;
    return scalar @$self;
}

1;
__END__

=head1 NAME

M3::ServerView::ResultSet - Contents returned by a view

=head1 DESCRIPTION

Instances of this class functions as an iterator for iterating over results returned when searching a view.

=head1 INTERFACE

=head2 CLASS METHODS

=over 4

=item new ( ARRAY )

Creates a new result set with the contents of the array reference I<ARRAY>.

=back

=head2 INSTANCE METHODS

=over 4

=item all

Returns a list of all items in the result set.

=item count

Returns the number of items in the result set.

=item first

Returns the first item in the result set or undef if the result set is empty.

=item next

Returns the next item in the result set or undef if there's no more items.

=item reset

Resets the result set to start from the beginning again.

=back

=cut

