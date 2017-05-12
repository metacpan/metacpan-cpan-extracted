package Mail::Action::Address;

use strict;
use warnings;

use vars '$VERSION';
$VERSION = '0.46';

use Class::Roles multi =>
{
    address_expires    => [qw( expires process_time )],
    address_named      => [qw( name )],
    address_described  => [qw( description )],
};

sub description
{
    my $self             = shift;
    $self->{description} = shift if @_;

    return '' unless exists $self->{description};
    return                  $self->{description};
}

sub name
{
    my $self       = shift;
    ($self->{name} = shift) =~ tr/-A-Za-z0-9_//cd if @_;
    return $self->{name};
}

sub expires
{
    my $self = shift;
    $self->{expires} = $self->process_time( shift ) + time() if @_;
    $self->{expires} = 0 unless $self->{expires};
    return $self->{expires};
}

sub process_time
{
    my ($self, $time) = @_;
    return $time unless $time =~ tr/0-9//c;

    my %times = (
        m =>                60,
        h =>           60 * 60,
        d =>      24 * 60 * 60,
        w =>  7 * 24 * 60 * 60,
        M => 30 * 24 * 60 * 60,
    );

    my $units    = join('', keys %times);
    my $seconds;

    while ( $time =~ s/(\d+)([$units])// )
    {
        $seconds += $1 * $times{ $2 };
    }

    return $seconds;
}

1;
__END__

=head1 NAME

Mail::Action::Address - roles applicable to individual addresses

=head1 SYNOPSIS

    use Mail::Action::Address;

    use Class::Roles
        does => 'address_expires',
        does => 'address_named',
        does => 'address_described';

=head1 DESCRIPTION

Most Mail::Action users operate around the idea of unique, lightweight e-mail
addresses, whether unique names within a subdomain, uniquely keyed variants of
a single address, or some combination of the two.

This class defines certain behavior and data storage features of those
addresses.  Use L<Class::Roles> to add these features to your own Address
classes.

=head1 ROLES

=head2 C<address_expires>

Allows Address instances to have an optional expiration date.  This adds two
method to the class to which you apply it:

=over 4

=item C<expires( $timestring )>

Gets and sets the time at which this Address will expire.  Set this time in a
simple text string, such as C<7d2h>.  Valid time units are:

=over 4

=item * C<m>, for minute.  This is sixty (60) seconds.

=item * C<h>, for hour.  This is sixty (60) minutes.

=item * C<d>, for day.  This is twenty-four (24) hours.

=item * C<w>, for week.  This is seven (7) days.

=item * C<M>, for month.  This is thirty (30) days.

The returned time is in epoch seconds.

=back

=item * C<process_time( $timestring )>

Turns a C<$timestring> into the number of seconds it represents.

=back

=head2 C<address_named>

Allows Address instances to have a name.  This adds one method to the class to
which you apply it:

=over 4

=item C<name( $name )>

Gets and sets the name associated with this Address.  This method strips the
name of all non-alphanumeric characters, including spaces and punctuation.

=back

=head2 C<address_described>

Allows Address instances to have a one-sentence description.  This adds one
method to the class to which you apply it:

=over 4

=item C<description( $description )>

Gets and sets the description of this Address.  This will return the empty
string if there is no description.

=back

=head1 AUTHOR

chromatic, C<< chromatic at wgz dot org >>

=head1 BUGS

No known bugs.

=head1 SEE ALSO

L<Class::Roles>, L<Mail::TempAddress::Address>, L<Mail::SimpleList::Alias>.

=head1 COPYRIGHT

Copyright (c) 2003 - 2009 chromatic.  Some rights reserved.  You may use,
modify, and distribute this module under the same terms as Perl 5.10 itself.
