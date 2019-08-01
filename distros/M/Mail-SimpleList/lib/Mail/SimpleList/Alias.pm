package Mail::SimpleList::Alias;

use strict;
use warnings;

use Mail::Action::Address;
use Mail::Address;

use Class::Roles
    does => 'address_expires',
    does => 'address_named',
    does => 'address_described';

use vars qw( $VERSION );
$VERSION = '0.95';

sub new
{
    my $class = shift;
    bless {
        owner       => '',
        closed      => 0,
        expires     => 0,
        auto_add    => 1,
        description => '',
        members     => [],
    @_ }, $class;
}

sub members
{
    my $self = shift;
    return $self->{members};
}

sub add
{
    my $self = shift;

    my %existing = map { $_ => 1 } @{ $self->{members} };
    my $existing = @{ $self->{members} };

    while (@_)
    {
        my $address = shift or next;
        chomp $address;

        for my $member ( Mail::Address->parse( $address ))
        {
            $member = $member->address();
            next if exists $existing{ $member };
            push @{ $self->{members} }, $member;
            $existing{ $member } = 1;
        }
    }

    return @{ $self->{members} }[ $existing .. $#{ $self->{members} } ];
}

sub remove_address
{
    my ($self, $remove) = @_;

    # Mail::Address format adds a newline
    chomp $remove;
    my $original = @{ $self->{members} };

    $self->{members} = [ grep { $_ ne $remove } @{ $self->{members} } ];
    $self->{owner}   = '' if $self->{owner} eq $remove;

    return $original > @{ $self->{members} };
}

sub owner
{
    my $self = shift;
    $self->add( $self->{owner} = shift ) if @_;
    return $self->{owner};
}

sub closed
{
    my $self = shift;
    $self->{closed} = $self->is_true( $_[0] ) if @_;
    return $self->{closed};
}

sub is_true
{
    my ($self, $value) = @_;
    return 0 unless $value;
    return 0 if $value =~ /^[Nn]o/;
    return 1;

}

sub auto_add
{
    my $self = shift;
    $self->{auto_add} = $self->is_true( $_[0] ) if @_;
    return $self->{auto_add};
}

sub attributes
{
    +{ map { $_ => 1 } qw( owner closed expires auto_add description name ) }
}

1;
__END__

=head1 NAME

Mail::SimpleList::Alias - object representing a temporary mailing list

=head1 SYNOPSIS

    use Mail::SimpleList::Alias;
    my $alias   =  Mail::SimpleList::Alias->new(
        owner   => 'me@example.com',
        members => [
            'alice@example.com', 'bob@example.com', 'charlie@example.com'
        ],
    );

=head1 DESCRIPTION

A Mail::SimpleList::Alias object represents a temporary mailing list within
Mail::SimpleList.  It contains all of the attributes of the list and provides
methods to query and to set them.  The current attributes are C<owner>,
C<closed>, C<expires>, C<auto_add>, C<description>, C<members> and C<name>.

=head1 METHODS

=over 4

=item * new( %options )

C<new()> creates a new Mail::SimpleList::Alias object.  Pass in a hash of
attribute options to set them.  By default, C<closed> and C<expires> are false,
C<auto_add> is true, and C<owner> and C<members> are empty.

=item * members()

Returns a reference to an array of the subscribed addresses.

=item * add( @addresses )

Adds a list of addresses to the Alias object.  Duplicate addresses are not
added.  Returns a list of addresses that were actually added.  This method
tries very hard to add only the canonical representation of an address to
prevent duplication.

=item * remove_address( $address )

Removes an address from the Alias.  Returns true or false if the address could
be removed.  If the owner of the list is removed, the C<owner> attribute will
be cleared.

=item * attributes()

Returns a reference to a hash of valid attributes for Alias objects.  This
allows you to see which attributes you should actually care about.

=item * owner(   [ $new_owner     ] )

Given C<$new_owner>, the e-mail address of a new owner, adds him to the alias
if he is not already subscribed and makes him the new list owner.  If the
argument is not provided, returns the address of the current owner.

=item * closed(  [ $new_closed    ] )

Given C<$new_closed>, updates the C<closed> attribute of the Alias and returns
the new value.  If the argument is not provided, returns the current value.

=item * expires( [ $new_expires   ] )

Given C<$new_expires>, updates the C<expires> attribute of the Alias and
returns the new value.  If the argument is not provided, returns the current
value.

=item * auto_add( [ $new_auto_add ] )

Given C<$new_auto_add>, updates the C<auto_add> attribute of the Alias and
returns the new value.  If the argument is not provided, returns the current
value.

=item * description( [ $new_description ] )

Given C<$new_description>, updates the C<description> attribute of the Alias
and returns the new value.  If the argument is not provided, returns the
current value.

=item * name( [ $new_name ] )

Given C<$new_name>, updates the C<name> attribute of the Alias and returns the
new value.  If the argument is not provided, returns the current value.  Note
that this attribute is I<not> saved; it is not intrinsic to the behavior of the
Alias at all.  Also note that only numbers, letters, the underscore, and the
hyphen characters are allowed.

=back

=head1 AUTHOR

chromatic, C<chromatic@wgz.org>, with helpful suggestions from friends, family,
and peers.  Allison Randal suggested the C<name> scheme.

=head1 BUGS

None known.

=head1 TODO

No plans.  It's pretty nice as it is.

=head1 SEE ALSO

L<Mail::Action::Address>, the parent class.

=head1 COPYRIGHT

Copyright (c) 2003 - 2016 chromatic. All rights reserved. This module is
distributed under the same terms as Perl 5.30, in the hope that it is useful
but under no warranty.
