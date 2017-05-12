require 5.002;

use strict;
use MIME::Decoder;


package MIME::Decoder::PGP;

use vars qw(@ISA $VERSION $passPhrases);

@ISA = qw(MIME::Decoder);

# The package version, both in 1.23 style *and* usable by MakeMaker:
$VERSION = substr q$Revision: 1.1.1.1 $, 10;


#------------------------------
#
# decode_it IN, OUT
#
sub decode_it {
    my ($self, $in, $out) = @_;
    my($head) = $self->head();
    if (!$head) {
	die "Missing MIME header";
    }
    my($uid) = $head->mime_attr('content-transfer-encoding.uid');
    if (!$uid) {
	die "Missing User ID (Attribute uid of header field"
	    . " content-transfer-encoding)";
    }
    if (!exists($MIME::Decoder::PGP::passPhrases->{$uid})) {
	die "Unknown User ID: $uid";
    }
    $ENV{'PGPPASS'} = $MIME::Decoder::PGP::passPhrases->{$uid};
    $self->filter($in, $out, "pgp -f +verbose=0");
}

#------------------------------
#
# encode_it IN, OUT
#
sub encode_it {
    my ($self, $in, $out) = @_;
    my($head) = $self->head();
    if (!$head) {
	die "Missing MIME header";
    }
    my($uid) = $head->mime_attr('content-transfer-encoding.uid');
    if (!$uid) {
	die "Missing User ID (Attribute uid of header field"
	    . " content-transfer-encoding)";
    }
    # Make uid shell safe
    $uid =~ s/([^\w])/\\$1/g;
    $self->filter($in, $out, "pgp -fea $uid +verbose=0");
}


#------------------------------
#
# pass_phrases [PASS_PHRASE_HASH]
sub pass_phrases {
    my($self, $passPhraseHash) = @_;
    if (@_ > 1) {
	$MIME::Decoder::PGP::passPhrases = $passPhraseHash;
    }
    $MIME::Decoder::PGP::passPhrases;
}


#------------------------------
1;


__END__

=head1 NAME

MIME::Decoder::PGP - decode a "radix-64" PGP stream


=head1 SYNOPSIS

A generic decoder object; see L<MIME::Decoder> for usage.


=head1 DESCRIPTION

A MIME::Decoder subclass for a nonstandard encoding using the
PGP tool. Common non-standard MIME encodings for this:

    x-pgp


=head1 AUTHOR

Copyright (c) 1998 by Jochen Wiedmann / joe@ispsoft.de

Based on MIME::Decoder::Gzip64, which is

Copyright (c) 1996, 1997 by Eryq / eryq@zeegee.com

All rights reserved.  This program is free software; you can redistribute 
it and/or modify it under the same terms as Perl itself.


=head1 VERSION

$Revision: 1.1.1.1 $ $Date: 1999/09/12 13:05:51 $

=cut
