package File::SOPS::Format::JSON;
our $VERSION = '0.001';
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: JSON format handler for SOPS

use Moo;
use Carp qw(croak);
use JSON::MaybeXS qw(decode_json);
use namespace::clean;

my $json = JSON::MaybeXS->new(
    utf8      => 1,
    pretty    => 1,
    canonical => 1,
);


sub parse {
    my ($class, $content) = @_;
    croak "content required" unless defined $content;

    my $data = decode_json($content);
    croak "JSON did not parse to a hash" unless ref $data eq 'HASH';

    my $metadata;
    if (exists $data->{sops}) {
        require File::SOPS::Metadata;
        $metadata = File::SOPS::Metadata->from_hash(delete $data->{sops});
    }

    return ($data, $metadata);
}


sub serialize {
    my ($class, %args) = @_;
    my $data     = $args{data}     // croak "data required";
    my $metadata = $args{metadata} // croak "metadata required";

    my %output = %$data;
    $output{sops} = $metadata->to_hash;

    return $json->encode(\%output);
}


sub format_name { 'json' }


sub file_extensions { qw(json) }


sub detect {
    my ($class, $filename) = @_;
    return 1 if $filename =~ /\.json$/i;
    return 0;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::SOPS::Format::JSON - JSON format handler for SOPS

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use File::SOPS::Format::JSON;

    # Parse JSON with SOPS metadata
    my ($data, $metadata) = File::SOPS::Format::JSON->parse($json_content);

    # Serialize data with SOPS metadata
    my $json = File::SOPS::Format::JSON->serialize(
        data     => $encrypted_data,
        metadata => $metadata_obj,
    );

    # Check if filename is JSON
    if (File::SOPS::Format::JSON->detect('secrets.json')) {
        # It's a JSON file
    }

=head1 DESCRIPTION

JSON format handler for File::SOPS. Handles parsing and serialization of
SOPS-encrypted JSON files.

Uses L<JSON::MaybeXS> for JSON processing (automatically uses the fastest
available JSON backend: Cpanel::JSON::XS, JSON::XS, or JSON::PP).

Output is always pretty-printed and canonically ordered for consistent diffs.

=head2 parse

    my ($data, $metadata) = File::SOPS::Format::JSON->parse($json_string);

Class method to parse a JSON string.

Returns a two-element list:

=over 4

=item 1. C<$data> - HashRef of the data (without the C<sops> section)

=item 2. C<$metadata> - L<File::SOPS::Metadata> object, or C<undef> if no C<sops> section

=back

Dies if the JSON is invalid or doesn't parse to a HashRef.

=head2 serialize

    my $json = File::SOPS::Format::JSON->serialize(
        data     => \%data,
        metadata => $metadata_obj,
    );

Class method to serialize data and metadata to JSON.

The C<data> parameter must be a HashRef. The C<metadata> parameter must be
a L<File::SOPS::Metadata> object.

Returns a pretty-printed, canonically-ordered JSON string with the C<sops>
section included.

=head2 format_name

Returns C<'json'>.

=head2 file_extensions

Returns a list of file extensions: C<('json')>.

=head2 detect

    if (File::SOPS::Format::JSON->detect($filename)) {
        # File is JSON based on extension
    }

Class method to detect if a filename is JSON based on extension.

Returns true if filename ends with C<.json> (case-insensitive).

=head1 SEE ALSO

=over 4

=item * L<File::SOPS> - Main SOPS interface

=item * L<JSON::MaybeXS> - JSON parser/serializer

=back

=head1 SUPPORT

=head2 IRC

You can reach Getty on C<irc.perl.org> for questions and support.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
