use strict;
use warnings;

package JSON::String::HASH;

our $VERSION = '0.2.0'; # VERSION

use JSON::String::BaseHandler
    '_reencode',
    '_recurse_wrap_value',
    'constructor' => { type => 'HASH', -as => 'constructor'};

BEGIN {
    *TIEHASH = \&constructor;
}

sub FETCH {
    my($self, $key) = @_;
    return $self->{data}->{$key};
}

sub STORE {
    my($self, $key, $val) = @_;
    $self->{data}->{$key} = $self->_recurse_wrap_value($val);
    $self->_reencode;
    return $val;
}

sub DELETE {
    my($self, $key) = @_;
    my $val = delete $self->{data}->{$key};
    $self->_reencode;
    return $val;
}

sub CLEAR {
    my $self = shift;
    %{$self->{data}} = ();
    $self->_reencode;
}

sub EXISTS {
    my($self, $key) = @_;
    return exists $self->{data}->{$key};
}

sub FIRSTKEY {
    my $self = shift;
    keys(%{$self->{data}}); # reset the iterator
    each %{$self->{data}};
}

sub NEXTKEY { each %{shift->{data}} }
sub SCALAR  { scalar( %{ shift->{data} } ) }

1;

=pod

=head1 NAME

JSON::String::HASH - Handle hashes for JSON::String

=head1 DESCRIPTION

This module is not intended to be used directly.  It is used by
L<JSON::String> to tie behavior to an hash.  Any time the hash is changed,
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
