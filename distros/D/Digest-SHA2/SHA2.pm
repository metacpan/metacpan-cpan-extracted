package Digest::SHA2;

use base 'Digest::base';
use strict;
use warnings;
require Exporter;

# addfile() and b64digest() already implemented by Digest::base
our @EXPORT_OK = qw(new hashsize rounds clone reset add digest hexdigest base64digest);
our @EXPORT = qw();
our $VERSION = '1.1.1';
#our @ISA = qw(Exporter);

require XSLoader;
XSLoader::load('Digest::SHA2', $VERSION);

# Preloaded methods go here.

#sub addfile
#{
#    my ($self, $handle) = @_;
#    my ($package, $file, $line) = caller;
#
#    if (!ref($handle)) {
#        $handle = "$package::$handle" unless ($handle =~ /(\:\:|\')/);
#    }
#
#    while (read($handle, my $data, 4*1024)) {
#        $self->add($data);
#    }
#}

sub digest
{
    my ($self) = @_;
    return pack("H*", $self->hexdigest());
}

sub base64digest   # legacy
{
    print STDERR "\nWARNING: base64digest() is now deprecated, and ";
    print STDERR "will be removed in future\n";
    print STDERR "releases; please use b64digest() instead.\n\n";
    return shift->b64digest(@_);
}

1;

__END__

=head1 NAME

Digest::SHA2 - A variable-length one-way hash function (deprecated in favor of L<Digest::SHA>)

=head1 DEPRECATED

This module has numerious known bugs, is not compatable with the
L<Digest> interface and its functionality is a subset of the
functionality of L<Digest::SHA> (which is in perl core as of 5.9.3).

Please use L<Digest::SHA> instead of this module in new and old code.

=head1 ABSTRACT

Digest::SHA2 - A Perl interface for SHA-256, SHA-384 and SHA-512,
collectively known as SHA-2

=head1 DESCRIPTION

SHA-2 is the collective name of one-way hash functions developed by the
NIST. SHA-256, SHA-384, and SHA-512 pertain to hashes whose outputs are
256 bits, 384 bits and 512 bits, respectively.

This Perl implementation is meant to be a replacement for the older
SHA256 by Rafael R. Sevilla. His module has a bug in the SHA-256
implementation.

This new implementation uses the C source of Aaron Gifford.

=head1 SYNOPSIS

    use Digest::SHA2;

    $sha2obj = new Digest::SHA2 [$hashlength];
    $sha2obj->add(LIST);
    $sha2obj->addfile(*HANDLE);
    $sha2obj->reset();

    $sha_clone = $sha2obj->clone();
    $digest = $sha2obj->digest();
    $digest = $sha2obj->hexdigest();
    $digest = $sha2obj->b64digest();
    $digest = $sha2obj->base64digest();  # deprecated

    $digest = $sha2obj->hashsize();
    $digest = $sha2obj->rounds();

=head1 METHODS

SHA-2 supports the following functions:

=over

=item B<new [$hashlength]>

Creates a SHA-2 object, where B<$hashlength> represents the hash output
length; valid values for B<$hashlength> are 256, 384, and 512 only.
If B<$hashlength> is omitted, the output defaults to 256 bits.

For example, to specify SHA-512, use

        $sha2obj = new Digest::SHA2 512;

To specify SHA-256, use

        $sha2obj = new Digest::SHA2 256;

or just simply

        $sha2obj = new Digest::SHA2;

=item B<hashsize()>

Returns the digest size (in bits) of the hash output used; valid sizes
are 256, 384, and 512 only.

=item B<rounds()>

Returns the number of rounds (1, in this case) used to generate the
hash output; this is included only so that B<Digest::SHA2> is
consistent with other one-way hash functions that have variable number
of rounds, like B<Haval> and B<Tiger>.

Haval can uses 3, 4, or 5 rounds, with 5 different output lengths: 128,
160, 192, 224, and 256 bits, thereby, having 15 variants. Tiger, on the
other hand, outputs 192 bits of digest, using 3 rounds; but for added
security, can also use 4 rounds.

=item B<add(LIST)>

Hashes a string or a list of strings

For example,

        $sha2obj->add($string1);
        $sha2obj->add($string2, $string3, $string4);

=item B<addfile(*HANDLE)>

Hashes a file whose file handle is B<HANDLE>

=item B<reset()>

Re-initializes the hash state of the SHA-2 object. Before calculating
another digest, B<reset()> refreshes the hash state, and is, therefore,
functionally equivalent to the B<new()> method, except that no SHA-2
object is created.

=item B<digest()>

Generates the hash output as a binary string

=item B<hexdigest()>

Generates a hexadecimal representation of the hash output

=item B<base64digest() (deprecated)>

This will be removed in future releases; use B<b64digest()> instead.

=item B<b64digest()>

Generates a base64 representation of the hash output

=item B<clone()>

Returns a copy of the SHA-2 object; useful when you want to preserve an
intermediate value of the digest

For example,

        my $clone = $sha2obj->clone();   # clone SHA-2 object

        my $sig = $sha2obj->clone->hexdigest;
        print "partial digest: $sig\n";

=back

=head1 EXAMPLE 1

    #!/usr/local/bin/perl

    use diagnostics;
    use strict;
    use warnings;
    use Digest::SHA2;

    my $string1 = "This is a string.";
    my $string2 = "This is another string.";
    my $string3 = "This is a string.This is another string.";

    my $sha2obj = new Digest::SHA2 512;
    print "hash size = ", $sha2obj->hashsize, " bits\n";

    $sha2obj->add($string1);
    my $digest = $sha2obj->hexdigest();
    print "Hash string1 only\n";
    print "$digest\n\n";

    $sha2obj->reset();
    $sha2obj->add($string1, $string2);
    my $digest2 = $sha2obj->hexdigest();
    print "Hash string1 and then hash string2\n";
    print "$digest2\n\n";

    $sha2obj->reset();
    $sha2obj->add($string1);
    $sha2obj->add($string2);
    my $digest3 = $sha2obj->hexdigest();
    print "Hash string1 and then hash string2\n";
    print "$digest3\n\n";

    $sha2obj->reset();
    $sha2obj->add($string3);
    print "Hash the two concatenated strings\n";
    my $digest4 = $sha2obj->hexdigest();
    print "$digest4\n";

=head1 EXAMPLE 2

    #!/usr/local/bin/perl

    use diagnostics;
    use strict;
    use warnings;
    use MIME::Base64;
    use Digest::SHA2;

    my $file = "strings";
    open INFILE, $file or die "$file not found";

    my $sha2obj = new Digest::SHA2;  # defaults to 256-bit output
    $sha2obj->addfile(*INFILE);
    my $hex_output = $sha2obj->hexdigest();
    my $base64_output = $sha2obj->b64digest();
    close INFILE;
    print "$file\n";
    print "$hex_output\n";
    print "$base64_output\n";

=head1 MORE EXAMPLES

See the "examples" and "t" directories for more examples.

=head1 DIGEST SPEED

Please consult the file, COMPARISON, for comparison of various one-way
hash functions with digest lengths of 256, 384, and 512 bits.

=head1 ACKNOWLEDGEMENT

I used the C source of Aaron Gifford as backend for this Perl
implementation.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003 Julius C. Duque. Please read contact.html that comes
with this distribution for details on how to contact the author.

This library is free software; you can redistribute it and/or modify
it under the same terms as the GNU General Public License.

=cut

