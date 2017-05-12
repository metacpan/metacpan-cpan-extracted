package Integer::Tiny;

use utf8;
use strict;
use warnings;

use Math::BigInt;

use Carp;

our $VERSION = '0.3';

sub new {
    my ($class, $alphabet) = @_;

    confess 'Missing key in constructor' unless defined $alphabet;
    confess 'Key is too short' unless length $alphabet >= 2;

    my $pos                = 0;
    my %chars_to_positions = map { $_ => $pos++ } split(//, $alphabet);
    my %positions_to_chars = reverse %chars_to_positions;
    my $length_of_alphabet = length $alphabet;

    confess 'Key contains duplicate characters'
        unless int keys %chars_to_positions == $length_of_alphabet;

    my $self = {
        'c2p' => \%chars_to_positions,
        'p2c' => \%positions_to_chars,
        'len' => $length_of_alphabet,
    };

    return bless $self, $class;
}

sub encrypt {
    my ($self, $value) = @_;
    my $integer;

    confess 'Value to encrypt not given' unless defined $value;

    if (ref $value eq 'Math::BigInt') {
        $integer = $value->copy();
    }
    elsif ($value =~ m/^\d+$/) {
        $integer = Math::BigInt->new($value);
    }
    else {
        confess 'Value to encrypt is not an Integer or Math::BigInt object';
    }

    my $encrypted = '';

    do {
        my $mod = $integer->copy();
        $mod->bmod($self->{'len'});
        $encrypted = $self->{'p2c'}->{$mod} . $encrypted;
        $integer->bdiv($self->{'len'})->bfloor();
    } while ($integer->is_pos());

    return $encrypted;

}

sub decrypt {
    my ($self, $encrypted) = @_;

    confess 'Value encrypted not given' unless defined $encrypted;
    confess 'Value encrypted is an empty string' unless length $encrypted;

    my $pos     = 0;
    my $integer = Math::BigInt->new(0);
    my @chars   = reverse split //, $encrypted;

    confess 'Value encrypted contains characters not present in key' if grep { !defined $self->{'c2p'}->{$_} } @chars;

    for my $ch (@chars) {
        my $to_add = Math::BigInt->new($self->{'len'});
        $to_add->bpow($pos++);
        $to_add->bmul($self->{'c2p'}->{$ch});
        $integer->badd($to_add);
    }

    return $integer;
}

=head1 NAME

Integer::Tiny - Shorten and obfuscate your Integer values. Just like IDs on YouTube!

=head1 SYNOPSIS

    use Integer::Tiny;
    $it = Integer::Tiny->new('0WEMACKGVPHRQNST862UYZ3FL4X17O59DJIB');
    print $it->encrypt('12345678');   # prints 'GQZB2'
    print $it->decrypt('GQZB2');    # prints '12345678'

Check USAGE section for more cool examples.

=head1 DESCRIPTION

Do you need fast and reliable method to obfuscate and shorten some Integer values?

Do you want to choose characters range you can use in output?

This module is for you!

=head1 USAGE

Typical encrypt-and-shorten suitable for URL addresses.

    my $key = 'hc2riK8fku7ezavCBJdMPwmntZ1s0yU4bOLI3SHRqANXFVD69gTG5oYQjExplW';
    my $it = Integer::Tiny->new($key);
    print $it->encrypt('48888851145'); # om3R4e

Time to clone someone, convert Integer to DNA sequence :)

    my $key = 'GCAT';
    my $it = Integer::Tiny->new($key);
    print $it->encrypt('48888851145');  # ATCAGAGGGGAAAATGAC

And so on... You're limited only by your imagination when inventing keys.

This module is suitable for most Internet usage,
like preventing your webpages from being scanned by ID sequence
or hiding informations you do not like to show explicitly.

=head1 KEYS

Key must be a String of AT LEAST TWO UNIQUE CHARACTERS (utf8 is allowed).

Characters used in key will also be your output characters range, simple as that!

The longer the key the shorter output you get!

Here is some code snippet to generate typical alphanumeric keys.

    use List::Util;
    my @t = ('a' .. 'z', 'A' .. 'Z', 0 .. 9);
    $key = join('', List::Util::shuffle @t );

=head1 METHODS

=head3 new

    my $it = Integer::Tiny->new('qwerty');

Create new object of C<Integer::Tiny> using key passed as the first parameter.

C<Carp::confess> will be called on missing or invalid key.

=head3 encrypt

    print $it->encrypt('48888851145'); # rtetrwqyteytyr

or

    my $i = Math::BigInt->new('48888851145');
    print $it->encrypt($i); # rtetrwqyteytyr

Encrypt passed Integer value (bigint allowed) using key given in constructor.

C<Carp::confess> will be called if value to encrypt is missing or not an Integer.

WARNING: Do not use syntax shown below unless you are sure it fits in your machine integer size.

    print $it->encrypt(48888851145); # integer may overflow

NOTE: Passed value is treated as Integer so leading C<0> (zero) chars are ignored!

    my $e = $it->encrypt('0048888851145');
    print $it->decrypt($e); # 48888851145

=head3 decrypt

    print $it->decrypt('rtetrwqyteytyr'); # 48888851145

Decrypt passed value using key given in constructor.

C<Carp::confess> will be called if value to decrypt is missing
or contains characters not existing in key.

=head1 PERL6

Yes, P6 Rakudo version is on the way 

=head1 AUTHOR

Pawel (bbkr) Pabian

Private website: L<http://bbkr.org> (visit for contact data)

Company website: L<http://implix.com>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;
