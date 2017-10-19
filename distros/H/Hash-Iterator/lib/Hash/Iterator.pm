use utf8;

package Hash::Iterator;

use strict;
use warnings FATAL => 'all';
use Carp ();

use constant MsgEmptyHash => 'the iterator has no values';
use constant TRUE         => 1;
use constant FALSE        => 0;

our $VERSION = '0.002';

sub new {
    my $class = shift;

    Carp::croak("new() requires key-value pairs")
      unless @_ % 2 == 0;

    my ( @keys, %data, $object );

    while (@_) {
        my $k = shift;
        push @keys, $k;
        $data{$k} = shift;
    }

    $object = {
        Keys          => [@keys],
        Data          => {%data},
        LengthKeys    => $#keys,
        CurrentState  => -1,
        PreviousState => -1,
    };

    return bless $object, $class;
}

sub done {
    my $self = shift;

    return ( $self->_get_position == $self->_get_LengthKeys )
      ? TRUE
      : FALSE;
}

sub next {
    my $self = shift;

    unless ( %{ $self->{Data} } ) {
        Carp::croak(MsgEmptyHash);
    }

    if ( $self->{LengthKeys} > $self->{CurrentState} ) {
        $self->{PreviousState} = $self->{CurrentState};
        $self->{CurrentState}++;
    }
    else {
        return 0;
    }
    return 1;
}

sub previous {
    my $self = shift;

    if (    ( int $self->{CurrentState} != -1 )
        and ( int $self->{PreviousState} != -1 ) )
    {
        $self->{CurrentState} = $self->{PreviousState};
        $self->{PreviousState}--;

        return 1;
    }
    return undef;
}

sub peek_key {
    my $self = shift;
    my $key  = $self->_get_key;

    return $key if $key;
    return undef;
}

sub peek_value {
    my $self  = shift;
    my $value = $self->_get_value;

    if ( ref $value eq 'HASH' ) {
        return \%$value;
    }
    elsif ( ref $value eq 'ARRAY' ) {
        return \@$value;
    }
    else {
        return $value;
    }
}

sub is_ref {
    my ( $self, $ref ) = @_;
    my $value = $self->_get_value;

    if ( ref $value eq $ref ) {
        return 1;
    }
    return;
}

sub get_data {
    my $self = shift;
    return wantarray
      ? @{ $self->{Data} }
      : $self->_get_LengthKeys;
}

sub get_keys {
    my $self = shift;
    return wantarray
      ? @{ $self->{Keys} }
      : $self->_get_LengthKeys;
}

sub _get_value {
    my $self = shift;

    my ( $CurrentValue, $CurrentKey );
    eval {
        $CurrentKey   = ${ $self->{Keys} }[ $self->_get_position ];
        $CurrentValue = ${ $self->{Data} }{$CurrentKey};
    };
    Carp::croak($@) if $@;

    return $CurrentValue if $CurrentValue;
    return undef;
}

sub _get_key {
    my $self = shift;

    my $curKey;
    eval { $curKey = ${ $self->{Keys} }[ $self->_get_position ]; };
    Carp::croak($@) if $@;

    return $curKey if $curKey;
}

sub _get_position      { shift->{CurrentState} }
sub _get_PreviousState { shift->{PreviousState} }
sub _get_LengthKeys    { shift->{LengthKeys} }

1;

__END__

# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Hash::Iterator - Hashtable Iterator.

=head1 SYNOPSIS

    my $iterator = Hash::Iterator->new( map { $_ => uc $_ } 'a'..'z' );

    while ($iterator->next) {
        say sprintf("%s => %s", $iterator->peek_key, $iterator->peek_value);
    }

    my $iterator = Hash::Iterator->new( a => [qw(one two three)] );
    $iterator->next;

    if ( $iterator->is_ref('ARRAY') ) {
        foreach my $item ( @{$iterator->peek_value} ) {
            say $item;
        }
    }

=head1 DESCRIPTION

=head1 CONSTRUCTORS

=head2 new

    my $iterator = Hash::Iterator->new( %hash );

Return a Hash::Iterator for C<hash>

=head1 METHODS

=over

=back

=head2 next

    $iterator->next;

Advance the iterator to the next key-value pair

=head2 previous

    $iterator->previous;

Advance the iterator to the previous key-value pair

=head2 done

    do {
        ....
    } while ($iterator->done);

Returns a boolean value if the iterator was exhausted

=head2 peek_key

    say $iterator->peek_key;

Return the key of the current key-value pair. It's not allowed to
call this method before L<next()|/next> was called for the first time or
after the iterator was exhausted.

=head2 peek_value

    say $iterator->peek_value;

Return the value of the current key-value pair.  It's not allowed to
call this method before L<next()|/next> was called for the first time or
after the iterator was exhausted.

=head2 is_ref

    if ( $iterator->is_ref('ARRAY') ) {
        ...
    }

Returns a boolean value if value is a reference.

=head2 get_keys

    my @keys =  $iterator->get_keys;

Returns a list of all keys from hash

=head1 AUTHOR

vlad mirkos, E<lt>vladmirkos@sd.apple.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by vlad mirkos

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.

=encoding UTF-8

=cut