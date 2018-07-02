package MVC::Neaf::X::Form::Data;

use strict;
use warnings;
our $VERSION = 0.2601;

=head1 NAME

MVC::Neaf::X::Form::Data - Form validation result object.

=head1 CAUTION

This module should be moved into a separate distribution or (ideally)
merged with an existing module with similar functionality.

Possible candidates include L<Validator::LIVR>, L<Data::FormValidator>,
L<Data::CGIForm>, and more.

=head1 DESCRIPTION

See L<MVC::Neaf::X::Form>.
This class is not expected to be created and used directly.

=head1 METHODS

=cut

use Digest::SHA qw(sha1);
use MVC::Neaf::Util qw( encode_b64 );
use URI::Escape;

use parent qw(MVC::Neaf::X);

=head2 new( %options )

%options may include:

=over

=item * data  - data that passed validation

=item * error - fields that failed validation  with correspondent error messages.

=item * raw   - data as it was before validation.
This should in theory match data + error, but isn't check in any way.

=back

=cut

=head2 fields()

Return fields currently in either data or raw hashes.

=cut

sub fields {
    my $self = shift;

    my %megahash = (%{ $self->raw }, %{ $self->data });
    return keys %megahash;
};

=head2 is_valid()

Returns true if data passed validation, false otherwise.

=cut

sub is_valid {
    my $self = shift;
    return !%{ $self->error };
};

=head2 data

Returns data that passed validation as hashref.
This MAY be incomplete, check is_valid() first.

=head2 data( "key" )

Get specific data item.

=head2 data( key => $newvalue )

Set specific data item.

=head2 error

Returns errors that occurred during validation.

=head2 error( "key" )

Get specific error item.

=head2 error( key => $newvalue )

Set specific error item. This may be used to invalidate a value
after additional checks, and will also reset is_valid.

=head2 raw

Returns raw input values as hashref.
Only keys subject to validation will be retained.

This may be useful for sending the data back for resubmission.

=head2 raw( "key" )

Get specific raw item.

=head2 raw( key => $newvalue )

Set specific raw item.

=cut

foreach (qw(data error raw)) {
    my $method = $_;

    my $code = sub {
        my $self = shift;

        my $hash = $self->{$method} ||= {};
        return $hash unless @_;

        my $param = shift;
        return $hash->{param} unless @_;

        $hash->{$param} = shift;
        return $self;
    };

    no strict 'refs'; ## no critic
    *$method = $code;
};

=head2 as_url( %override )

Return the cleansed form data as one url-encoded line.
The keys are sorted, and empty/undef values are discarded.

Arrays are NOT supported (yet). This may change in the future.

=cut

sub as_url {
    my ($self, %override) = @_;

    my %data = ( %{ $self->{data} || {} }, %override );

    return join '&'
        , map { uri_escape_utf8( $_ ). "=". uri_escape_utf8( $data{$_} ) }
        grep  { defined $data{$_} and length $data{$_} }
        sort keys %data;
};

=head2 sign( %options )

Sign data with a key.
Empty values are discarded.
The same data set with the same key is guaranteed to produce the same signature,
at least in the same module version.

Options may include:

=over

=item * key (required) - the encryption key. If unsure, run pwgen(1) and
hardcode something from its output.

=item * crypt = CODE($data, $key) - use that function for encryption.
The default is simple sha1-based hash.
You may need a more secure alternative.

=item * override = %hash - override these values.

=item * discard = @list - discard these values. This takes over override.
May be needed e.g. to check if the form matches signature that comes with the
form itself.

=back

=cut

sub sign {
    my ($self, %opt) = @_;

    $self->my_croak( "key parameter is required" )
        unless $opt{key};

    my %override = ( %{ $opt{override} || {} }
        , map { $_ => '' } @{ $opt{exclude} || [] } );
    $opt{crypt} ||= \&_default_sign;

    return $opt{crypt}->( $self->as_url( %override ), $opt{key});
};

# A weak ad-hoc HMAC. Use a better one...
sub _default_sign {
    my ($data, $key) = @_;
    return encode_b64( sha1( join "?", $key, $data, $key ) );
};

=head1 LICENSE AND COPYRIGHT

This module is part of L<MVC::Neaf> suite.

Copyright 2016-2018 Konstantin S. Uvarin C<khedin@cpan.org>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
