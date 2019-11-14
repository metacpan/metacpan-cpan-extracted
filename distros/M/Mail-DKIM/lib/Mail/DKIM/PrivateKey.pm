#!/usr/bin/perl

# Copyright 2005-2007 Messiah College. All rights reserved.
# Jason Long <jlong@messiah.edu>
#
# Copyright (c) 2004 Anthony D. Urso. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use strict;
use warnings;

=head1 NAME

Mail::DKIM::PrivateKey - a private key loaded in memory for DKIM signing

=head1 SYNOPSIS

 my $key1 = Mail::DKIM::PrivateKey->load(
               File => '/path/to/private.key');

 my $key2 = Mail::DKIM::PrivateKey->load(
               Data => $base64);

 # use the loaded key in a DKIM signing object
 my $dkim = Mail::DKIM::Signer->new(
               Key => $key2,
             );

=cut

package Mail::DKIM::PrivateKey;
use base 'Mail::DKIM::Key';
use Carp;
*calculate_EM = \&Mail::DKIM::Key::calculate_EM;

=head1 CONSTRUCTOR

=head2 load() - loads a private key into memory

 my $key1 = Mail::DKIM::PrivateKey->load(
               File => '/path/to/private.key');

Loads the Base64-encoded key from the specified file.

  my $key2 = Mail::DKIM::PrivateKey->load(Data => $base64);

Loads the Base64-encoded key from a string already in memory.

  my $key3 = Mail::DKIM::PrivateKey->load(Cork => $openssl_object);

Creates a Mail::DKIM::PrivateKey wrapper object for the given
OpenSSL key object. The key object should be of type
L<Crypt::OpenSSL::RSA>.

=cut

sub load {
    my $class = shift;
    my %prms  = @_;

    my $self = bless {}, $class;

    $self->{'TYPE'} = ( $prms{'Type'} or 'rsa' );

    if ( $prms{'Data'} ) {
        $self->{'DATA'} = $prms{'Data'};
    }
    elsif ( defined $prms{'File'} ) {
        my @data;
        open my $file, '<', $prms{'File'}
          or die "Error: cannot read $prms{File}: $!\n";
        while ( my $line = <$file> ) {
            chomp $line;
            next if $line =~ /^---/;
            push @data, $line;
        }
        $self->{'DATA'} = join '', @data;
        close $file;
    }
    elsif ( $prms{'Cork'} ) {
        $self->{'CORK'} = $prms{'Cork'};
    }
    else {
        croak 'missing required argument';
    }

    return $self;
}

=head1 METHODS

=head2 cork() - access the underlying OpenSSL key object

  $openssl_object = $key->cork;

The returned object is of type L<Crypt::OpenSSL::RSA>.

=cut

sub convert {
    use Crypt::OpenSSL::RSA;

    my $self = shift;

    $self->data
      or return;

    # have to PKCS1ify the privkey because openssl is too finicky...
    my $pkcs = "-----BEGIN RSA PRIVATE KEY-----\n";

    for ( my $i = 0 ; $i < length $self->data ; $i += 64 ) {
        $pkcs .= substr $self->data, $i, 64;
        $pkcs .= "\n";
    }

    $pkcs .= "-----END RSA PRIVATE KEY-----\n";

    my $cork;

    eval {
        local $SIG{__DIE__};
        $cork = new_private_key Crypt::OpenSSL::RSA($pkcs);
    };

    $@
      and $self->errorstr($@),
      return;

    $cork
      or return;

    # segfaults on my machine
    #	$cork->check_key or
    #		return;

    $self->cork($cork);

    return 1;
}

#deprecated
sub sign {
    my $self = shift;
    my $mail = shift;

    return $self->cork->sign($mail);
}

#deprecated- use sign_digest() instead
sub sign_sha1_digest {
    my $self = shift;
    my ($digest) = @_;
    return $self->sign_digest( 'SHA-1', $digest );
}

=head2 sign_digest()

Cryptographically sign the given message digest.

  $key->sign_digest('SHA-1', sha1('my message text'));

The first parameter is the name of the digest: one of "SHA-1", "SHA-256".

The second parameter is the message digest as a binary string.

The result should be the signed digest as a binary string.

=cut

sub sign_digest {
    my $self = shift;
    my ( $digest_algorithm, $digest ) = @_;

    my $rsa_priv = $self->cork;
    $rsa_priv->use_no_padding;

    my $k = $rsa_priv->size;
    my $EM = calculate_EM( $digest_algorithm, $digest, $k );
    return $rsa_priv->decrypt($EM);
}

=head1 AUTHOR

Jason Long, E<lt>jlong@messiah.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2008 by Messiah College

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
