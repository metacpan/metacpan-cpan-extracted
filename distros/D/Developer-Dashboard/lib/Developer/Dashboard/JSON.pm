package Developer::Dashboard::JSON;

use strict;
use warnings;

our $VERSION = '1.33';

use Exporter 'import';
use JSON::XS ();

our @EXPORT_OK = qw(json_encode json_decode);

# json_encode($value)
# Serializes a Perl value into canonical pretty JSON.
# Input: scalar/array/hash reference.
# Output: JSON text string.
sub json_encode {
    return JSON::XS->new->canonical->pretty->encode( $_[0] );
}

# json_decode($json)
# Parses JSON text into a Perl data structure.
# Input: JSON text string.
# Output: decoded Perl value.
sub json_decode {
    return JSON::XS->new->decode( $_[0] );
}

1;

__END__

=head1 NAME

Developer::Dashboard::JSON - JSON::XS wrapper for Developer Dashboard

=head1 SYNOPSIS

  use Developer::Dashboard::JSON qw(json_encode json_decode);

=head1 DESCRIPTION

This module centralizes JSON encoding and decoding so the project uses a
single consistent JSON backend and output style.

=head1 FUNCTIONS

=head2 json_encode

Encode a Perl value as canonical pretty JSON.

=head2 json_decode

Decode JSON text into a Perl value.

=cut
