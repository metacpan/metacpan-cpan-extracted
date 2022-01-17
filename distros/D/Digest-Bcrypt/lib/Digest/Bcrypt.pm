package Digest::Bcrypt;
use parent 'Digest::base';

use strict;
use warnings;
require bytes;

use Carp ();
use Crypt::Bcrypt qw(bcrypt bcrypt_check);
use MIME::Base64 qw(decode_base64 encode_base64);
use utf8;

our $VERSION = '1.212';

sub add {
    my $self = shift;
    $self->{_buffer} .= join('', @_);
    return $self;
}

sub bcrypt_b64digest {
    my $encoded = encode_base64(shift->digest, "");
    $encoded =~ tr{A-Za-z0-9+/=}{./A-Za-z0-9}d;
    return $encoded;
}

sub clone {
    my $self = shift;
    return undef
        unless my $clone = $self->new(
        cost => $self->cost,
        salt => $self->salt,
        type => $self->type,
        );
    $clone->add($self->{_buffer});
    return $clone;
}

sub cost {
    my $self = shift;
    return $self->{cost} unless @_;

    my $cost = shift;

    # allow and undefined value to clear it
    unless (defined $cost) {
        delete $self->{cost};
        return $self;
    }
    $self->_check_cost($cost);

    # bcrypt requires 2 digit costs, it dies if it's a single digit.
    $self->{cost} = sprintf("%02d", $cost);
    return $self;
}

sub digest {
    my $self = shift;
    $self->_check_cost;
    $self->_check_salt;

    my $type     = defined($self->{type}) ? $self->{type} : '2a';
    my $hash     = bcrypt($self->{_buffer}, $type, $self->cost, $self->salt);
    my $settings = $self->settings;
    $self->reset;
    return _de_base64(substr($hash, length($settings)));
}

# new isn't actually implemented in the base class. eww.
sub new {
    my $class = shift;
    my $self  = bless {_buffer => '',}, ref $class || $class;
    return $self unless @_;
    my $params = @_ > 1 ? {@_} : {%{$_[0]}};
    $self->cost($params->{cost})         if $params->{cost};
    $self->salt($params->{salt})         if $params->{salt};
    $self->settings($params->{settings}) if $params->{settings};
    $self->type($params->{type})         if $params->{type};
    return $self;
}

sub reset {
    my $self = shift;
    $self->{_buffer} = '';
    delete $self->{cost};
    delete $self->{salt};
    delete $self->{type};
    return $self;
}

sub salt {
    my $self = shift;
    return $self->{salt} unless @_;

    my $salt = shift;

    # allow and undefined value to clear it
    unless (defined $salt) {
        delete $self->{salt};
        return $self;
    }

    # all other values go through the check
    $self->_check_salt($salt);
    $self->{salt} = $salt;
    return $self;
}

sub settings {
    my $self = shift;
    unless (@_) {
        my $cost        = sprintf('%02d', $self->{cost});
        my $salt_base64 = encode_base64($self->salt, "");
        $salt_base64 =~ tr{A-Za-z0-9+/=}{./A-Za-z0-9}d;
        my $type = defined($self->{type}) ? $self->{type} : '2a';
        return "\$${type}\$${cost}\$${salt_base64}";
    }
    my $settings = shift;
    Carp::croak "bad bcrypt settings"
        unless $settings =~ m#\A\$(2[abxy])\$([0-9]{2})\$
            ([./A-Za-z0-9]{22})#x;
    my ($type, $cost, $salt_base64) = ($1, $2, $3);
    $self->type($type);
    $self->cost($cost);
    $self->salt(_de_base64($salt_base64));
    return $self;
}

sub type {
    my $self = shift;
    return $self->{type} unless (@_);

    my $type = shift;
    Carp::croak "bad bcrypt type" unless $type =~ /^2[abxy]$/;
    $self->{type} = $type;
    return $self;
}

# Checks that the cost is a positive integerCroaks if it isn't
sub _check_cost {
    my ($self, $cost) = @_;
    $cost = defined $cost ? $cost : $self->cost;
    if (!defined $cost || $cost !~ /^\d+$/) {
        Carp::croak "Cost must be a positive integer";
    }
}

# Checks that the salt exactly 16 octets long. Croaks if it isn't
sub _check_salt {
    my ($self, $salt) = @_;
    $salt = defined $salt ? $salt : $self->salt;
    unless ($salt && bytes::length($salt) == 16) {
        Carp::croak "Salt must be exactly 16 octets long";
    }
}

sub _de_base64 {
    my ($text) = @_;
    $text =~ tr#./A-Za-z0-9#A-Za-z0-9+/#;
    return decode_base64($text);
}


1;

=encoding utf8

=head1 NAME

Digest::Bcrypt - Perl interface to the bcrypt digest algorithm

=head1 SYNOPSIS

    #!/usr/bin/env perl
    use strict;
    use warnings;
    use utf8;
    use Digest;   # via the Digest module (recommended)

    my $bcrypt = Digest->new('Bcrypt', cost => 12, salt => 'abcdefgh♥stuff');
    # You can forego the cost and salt in favor of settings strings:
    my $bcrypt = Digest->new('Bcrypt', settings => '$2a$20$GA.eY03tb02ea0DqbA.eG.');

    # $cost is an integer between 5 and 31
    $bcrypt->cost(12);

    # $type is a selection between 2a, 2b, 2x, and 2y
    $bcrypt->type('2b');

    # $salt must be exactly 16 octets long
    $bcrypt->salt('abcdefgh♥stuff');
    # OR, for good, random salts:
    use Data::Entropy::Algorithms qw(rand_bits);
    $bcrypt->salt(rand_bits(16*8)); # 16 octets

    # You can forego the cost and salt in favor of settings strings:
    $bcrypt->settings('$2a$20$GA.eY03tb02ea0DqbA.eG.');

    # add some strings we want to make a secret of
    $bcrypt->add('some stuff', 'here and', 'here');

    my $digest = $bcrypt->digest;
    $digest = $bcrypt->hexdigest;
    $digest = $bcrypt->b64digest;

    # bcrypt's own non-standard base64 dictionary
    $digest = $bcrypt->bcrypt_b64digest;

    # Now, let's create a password hash and check it later:
    use Data::Entropy::Algorithms qw(rand_bits);
    my $bcrypt = Digest->new('Bcrypt', type => '2b', cost => 20, salt => rand_bits(16*8));
    my $settings = $bcrypt->settings(); # save for later checks.
    my $pass_hash = $bcrypt->add('Some secret password')->digest;

    # much later, we can check a password against our hash via:
    my $bcrypt = Digest->new('Bcrypt', settings => $settings);
    if ($bcrypt->add($value_from_user)->digest eq $known_pass_hash) {
        say "Your password matched";
    }
    else {
        say "Try again!";
    }

    # Now that you've seen how cumbersome/silly that is,
    # please use Crypt::Bcrypt instead of this module.

=head1 NOTICE

While maintenance for L<Digest::Bcrypt> will continue, there's no reason to use
L<Digest::Bcrypt> when L<Crypt::Bcrypt> already exists.  We strongly suggest
that you use L<Crypt::Bcrypt> instead.

This C<Digest::Bcrypt> interface is crufty and laborious to use when compared
to that of L<Crypt::Bcrypt>.

=head1 DESCRIPTION

L<Digest::Bcrypt> provides a L<Digest>-based interface to the
L<Crypt::Bcrypt> library.

Please note that you B<must> set a C<salt> of exactly 16 octets in length,
and you B<must> provide a C<cost> in the range C<1..31>.

=head1 ATTRIBUTES

L<Digest::Bcrypt> implements the following attributes.

=head2 cost

    $bcrypt = $bcrypt->cost(20); # allows for method chaining
    my $cost = $bcrypt->cost();

An integer in the range C<5..31>, this is required.

See L<Crypt::Eksblowfish::Bcrypt> for a detailed description of C<cost>
in the context of the bcrypt algorithm.

When called with no arguments, it will return the current cost.

=head2 salt

    $bcrypt = $bcrypt->salt('abcdefgh♥stuff'); # allows for method chaining
    my $salt = $bcrypt->salt();

    # OR, for good, random salts:
    use Data::Entropy::Algorithms qw(rand_bits);
    $bcrypt->salt(rand_bits(16*8)); # 16 octets

Sets the value to be used as a salt. Bcrypt requires B<exactly> 16 octets of salt.

It is recommenced that you use a module like L<Data::Entropy::Algorithms> to
provide a truly randomized salt.

When called with no arguments, it will return the current salt.

=head2 settings

    $bcrypt = $bcrypt->settings('$2a$20$GA.eY03tb02ea0DqbA.eG.'); # allows for method chaining
    my $settings = $bcrypt->settings();

A C<settings> string can be used to set the L<Digest::Bcrypt/salt> and
L<Digest::Bcrypt/cost> automatically. Setting the C<settings> will override any
current values in your C<cost> and C<salt> attributes.

For details on the C<settings> string requirements, please see L<Crypt::Eksblowfish::Bcrypt>.

When called with no arguments, it will return the current settings string.

=head2 type

    $bcrypt = $bcrypt->type('2b');
    # method chaining on mutations
    say $bcrypt->type(); # 2b

This sets the subtype of bcrypt used. These subtypes are as defined in L<Crypt::Bcrypt>.
The available types are:
C<2b> which is the current standard,
C<2a> which is older; it's the one used in L<Crypt::Eksblowfish>,
C<2y> which is considered equivalent to C<2b> and used in PHP.
C<2x> which is very broken and only needed to work with ancient PHP versions.

=head1 METHODS

L<Digest::Bcrypt> inherits all methods from L<Digest::base> and implements/overrides
the following methods as well.

=head2 new

    my $bcrypt = Digest->new('Bcrypt', %params);
    my $bcrypt = Digest::Bcrypt->new(%params);
    my $bcrypt = Digest->new('Bcrypt', \%params);
    my $bcrypt = Digest::Bcrypt->new(\%params);

Creates a new C<Digest::Bcrypt> object. It is recommended that you use the L<Digest>
module in the first example rather than using L<Digest::Bcrypt> directly.

Any of the L<Digest::Bcrypt/ATTRIBUTES> above can be passed in as a parameter.

=head2 add

    $bcrypt->add("a"); $bcrypt->add("b"); $bcrypt->add("c");
    $bcrypt->add("a")->add("b")->add("c");
    $bcrypt->add("a", "b", "c");
    $bcrypt->add("abc");

Adds data to the message we are calculating the digest for. All the above
examples have the same effect.

=head2 b64digest

    my $digest = $bcrypt->b64digest;

Same as L</"digest">, but will return the digest base64 encoded.

The C<length> of the returned string will be 31 and will only contain characters
from the ranges C<'0'..'9'>, C<'A'..'Z'>, C<'a'..'z'>, C<'+'>, and C<'/'>

The base64 encoded string returned is not padded to be a multiple of 4 bytes long.

=head2 bcrypt_b64digest

    my $digest = $bcrypt->bcrypt_b64digest;

Same as L</"digest">, but will return the digest base64 encoded using the alphabet
that is commonly used with bcrypt.

The C<length> of the returned string will be 31 and will only contain characters
from the ranges C<'0'..'9'>, C<'A'..'Z'>, C<'a'..'z'>, C<'+'>, and C<'.'>

The base64 encoded string returned is not padded to be a multiple of 4 bytes long.

I<Note:> This is bcrypt's own non-standard base64 alphabet, It is B<not>
compatible with the standard MIME base64 encoding.

=head2 clone

    my $clone = $bcrypt->clone;

Creates a clone of the C<Digest::Bcrypt> object, and returns it.

=head2 digest

    my $digest = $bcrypt->digest;

Returns the binary digest for the message. The returned string will be 23 bytes long.

=head2 hexdigest

    my $digest = $bcrypt->hexdigest;

Same as L</"digest">, but will return the digest in hexadecimal form.

The C<length> of the returned string will be 46 and will only contain
characters from the ranges C<'0'..'9'> and C<'a'..'f'>.

=head2 reset

    $bcrypt->reset;

Resets the object to the same internal state it was in when it was constructed.

=head1 SEE ALSO

L<Digest>, L<Crypt::Eksblowfish::Bcrypt>, L<Data::Entropy::Algorithms>

=head1 AUTHOR

James Aitken C<jaitken@cpan.org>

=head1 CONTRIBUTORS

=over

=item *

Chase Whitener C<capoeira@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by James Aitken.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
