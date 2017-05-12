use strict;
use warnings;

package JSON::String::ARRAY;

our $VERSION = '0.2.0'; # VERSION

use JSON::String::BaseHandler
    '_reencode',
    '_recurse_wrap_value',
    'constructor' => { type => 'ARRAY', -as => '_constructor' };

BEGIN {
    *TIEARRAY = \&_constructor;
}

sub FETCH {
    my($self, $idx) = @_;
    return $self->{data}->[$idx];
}

sub STORE {
    my($self, $idx, $val) = @_;
    $self->{data}->[$idx] = $self->_recurse_wrap_value($val);
    $self->_reencode;
    return $val;
}

sub FETCHSIZE {
    return scalar @{shift->{data}};
}

sub STORESIZE {
    my($self, $len) = @_;
    $#{$self->{data}} = $len - 1;
    $self->_reencode;
    return $len;
}

sub EXTEND { goto &STORESIZE }

sub EXISTS {
    my($self, $idx) = @_;
    return($self->FETCHSIZE < $idx);
}

sub DELETE {
    my($self, $idx) = @_;
    my $val = $self->{data}->[$idx];
    $self->{data}->[$idx] = undef;
    return $val;
}

sub CLEAR {
    my $self = shift;
    @{$self->{data}} = ();
    $self->_reencode;
}

sub PUSH {
    my $self = shift;
    my $rv = push @{$self->{data}}, @_;
    $self->_reencode;
    return $rv;
}

sub POP {
    my $self = shift;
    my $rv = pop @{$self->{data}};
    $self->_reencode;
    return $rv;
}

sub SHIFT {
    my $self = shift;
    my $rv = shift @{$self->{data}};
    $self->_reencode;
    return $rv;
}

sub UNSHIFT {
    my $self = shift;
    my $rv = unshift @{$self->{data}}, @_;
    $self->_reencode;
    return $rv;
}

sub SPLICE {
    my $self = shift;
    my @rv;
    if (wantarray) {
        @rv = splice @{$self}, @_;
    } else {
        $rv[0] = splice @{$self}, @_;
    }

    $self->_reencode;

    return( wantarray ? @rv : $rv[0] );
}

1;    

=pod

=head1 NAME

JSON::String::ARRAY - Handle arrays for JSON::String

=head1 DESCRIPTION

This module is not intended to be used directly.  It is used by
L<JSON::String> to tie behavior to an array.  Any time the array is changed,
the top-level data structure is re-encoded and the serialized representation
saved back to the original location.

=head1 SEE ALSO

L<JSON::String>, L<JSON>

=head1 AUTHOR

Anthony Brummett <brummett@cpan.org>

=head1 COPYRIGHT

Copyright 2015, Anthony Brummett.  This module is free software. It may
be used, redistributed and/or modified under the same terms as Perl itself.

=cut
