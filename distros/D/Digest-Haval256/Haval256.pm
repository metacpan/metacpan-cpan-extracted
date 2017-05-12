package Digest::Haval256;

use strict;
use warnings;
use MIME::Base64;
require Exporter;

our @EXPORT_OK = qw(new hashsize rounds reset add addfile digest hexdigest base64digest);
our $VERSION = '1.0.5';
our @ISA = qw(Exporter);

require XSLoader;
XSLoader::load('Digest::Haval256', $VERSION);

# Preloaded methods go here.

sub addfile
{
    my ($self, $handle) = @_;
    my ($package, $file, $line) = caller;

    if (!ref($handle)) {
        $handle = "$package::$handle" unless ($handle =~ /(\:\:|\')/);
    }

    while (read($handle, my $data, 1048576)) {
        $self->add($data);
    }
}

sub hexdigest
{
    my $self = shift;
    return unpack("H*", $self->digest());
}

sub base64digest
{
    my $self = shift;
    return encode_base64($self->digest(), "");
}

1;

__END__

=head1 NAME

Digest::Haval256 - A 5-round, 256-bit one-way hash function

=head1 ABSTRACT

Haval is a variable-length, variable-round one-way hash function.

=head1 SYNOPSIS

    use Digest::Haval256;

    $haval = new Digest::Haval256;
    $haval->add(LIST);
    $haval->addfile(*HANDLE);
    $haval->reset();

    $digest = $haval->digest();
    $digest = $haval->hexdigest();
    $digest = $haval->base64digest();
    
    $digest = $haval->hashsize();
    $digest = $haval->rounds();

=head1 DESCRIPTION

Haval is a variable-length, variable-round one-way hash function
designed by Yuliang Zheng, Josef Pieprzyk, and Jennifer Seberry.
The number of rounds can be 3, 4, or 5, while the hash length can be
128, 160, 192, 224, or 256 bits. Thus, there are a total of 15
different outputs. For better security, however, this module
implements the 5-round, 256-bit output.

=head2 Functions

=over

=item B<hashsize()>

Returns the size (in bits) of the hash (256, in this case)

=item B<rounds()>

Returns the number of rounds used (5, in this case)

=item B<add(LIST)>

Hashes a string or a list of strings

=item B<addfile(*HANDLE)>

Hashes a file

=item B<reset()>

Re-initializes the hash state. Before calculating another digest, the
hash state must be refreshed.

=item B<digest()>

Generates the hash output (a 32-byte binary string)

=item B<hexdigest()>

Generates a hexadecimal representation of the hash output

=item B<base64digest()>

Generates a base64 representation of the hash output. B<MIME::Base64>
must be installed first for this function to work.

=back

=head1 EXAMPLE 1

    #!/usr/local/bin/perl

    use diagnostics;
    use strict;
    use warnings;
    use Digest::Haval256;

    my $string1 = "This is a string.";
    my $string2 = "This is another string.";
    my $string3 = "This is a string.This is another string.";

    my $haval = new Digest::Haval256;
    print "hash size=", $haval->hashsize, "\n";
    print "number of rounds=", $haval->rounds, "\n\n";

    $haval->add($string1);
    my $digest = $haval->hexdigest();
    print "Hash string1 only\n";
    print "$digest\n\n";

    $haval->reset();
    $haval->add($string1, $string2);
    my $digest2 = $haval->hexdigest();
    print "Hash string1 and then hash string2\n";
    print "$digest2\n\n";
    
    $haval->reset();
    $haval->add($string3);
    print "Hash the two concatenated strings\n";
    my $digest3 = $haval->hexdigest();
    print "$digest3\n";

=head1 EXAMPLE 2

    #!/usr/local/bin/perl

    use diagnostics;
    use strict;
    use warnings;
    use MIME::Base64;
    use Digest::Haval256;

    my $file = "strings.pl";
    open INFILE, $file or die "$file not found";

    my $haval = new Digest::Haval256;
    $haval->addfile(*INFILE);
    my $hex_output = $haval->hexdigest();
    my $base64_output = $haval->base64digest();
    close INFILE;
    print "$file\n";
    print "$hex_output\n";
    print "$base64_output\n";

=head1 MORE EXAMPLES

See the "examples" and "t" directories for more examples.

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Julius C. Duque <jcduque (AT) lycos (DOT) com>

This library is free software; you can redistribute it and/or modify
it under the same terms as the GNU General Public License.

=cut

