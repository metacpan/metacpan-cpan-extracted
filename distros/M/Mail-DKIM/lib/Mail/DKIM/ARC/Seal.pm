package Mail::DKIM::ARC::Seal;
use strict;
use warnings;
our $VERSION = '1.20220520'; # VERSION
# ABSTRACT: represents a ARC-Seal header

# Copyright 2017 FastMail Pty Ltd. All Rights Reserved.
# Bron Gondwana <brong@fastmailteam.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use base 'Mail::DKIM::ARC::MessageSignature';


sub new {
    my $class = shift;
    my %prms  = @_;
    my $self  = {};
    bless $self, $class;

    $self->instance( $prms{'Instance'} ) if exists $prms{'Instance'};
    $self->algorithm( $prms{'Algorithm'} || 'rsa-sha256' );
    $self->signature( $prms{'Signature'} );
    $self->canonicalization( $prms{'Method'} ) if exists $prms{'Method'};
    $self->chain( $prms{'Chain'} || 'none' );
    $self->domain( $prms{'Domain'} );
    $self->selector( $prms{'Selector'} );
    $self->timestamp(
        defined $prms{'Timestamp'} ? $prms{'Timestamp'} : time() );
    $self->expiration( $prms{'Expiration'} ) if defined $prms{'Expiration'};
    $self->key( $prms{'Key'} )               if defined $prms{'Key'};

    return $self;
}

sub body_hash {

    # Not defined for ARC-Seal
    return;
}

sub DEFAULT_PREFIX {
    return 'ARC-Seal:';
}


sub chain {
    my $self = shift;
    if (@_) {
        my $cv = shift;
        die "INVALID chain value $cv"
          unless grep { $cv eq $_ } qw(none fail pass);
        $self->set_tag( 'cv', $cv );
    }
    return $self->get_tag('cv');
}


sub canonicalization {
    return ( 'seal', 'seal' );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::DKIM::ARC::Seal - represents a ARC-Seal header

=head1 VERSION

version 1.20220520

=head1 CONSTRUCTORS

=head2 new() - create a new signature from parameters

  my $signature = Mail::DKIM::ARC::Seal->new(
                      [ Algorithm => 'rsa-sha256', ]
                      [ Signature => $base64, ]
                      [ Domain => 'example.org', ]
                      [ Instance => 1, ]
                      [ Chain => 'none', ] # none|fail|pass
                      [ Query => 'dns', ]
                      [ Selector => 'alpha', ]
                      [ Timestamp => time(), ]
                      [ Expiration => time() + 86400, ]
                  );

The ARC-Seal is similar to a DKIM signature but with the following changes:

https://tools.ietf.org/html/draft-ietf-dmarc-arc-protocol-06

5.1.1.1.  Tags in the ARC-Seal Header Field Value

   The following tags are the only supported tags for an ARC-Seal field.
   All of them MUST be present.  Unknown tags MUST be ignored and do not
   affect the validity of the header.

   o  a = hash algorithm; syntax is the same as the "a=" tag defined in
      Section 3.5 of [RFC6376];

   o  b = digital signature; syntax is the same as the "b=" tag defined
      in Section 3.5 of [RFC6376];

   o  cv = chain validation status: valid values:

      *  'none' = no pre-existing chain;

      *  'fail' = the chain as received does not or can not validate; or

      *  'pass' = valid chain received.

   o  d = domain for key; syntax is the same as the "d=" tag defined in
      Section 3.5 of [RFC6376];

   o  i = "instance" or sequence number; monotonically increasing at
      each "sealing" entity, beginning with '1', see Section 5.1.1.1.1
      regarding the valid range

   o  s = selector for key; syntax is the same as the "s=" tag defined
      in Section 3.5 of [RFC6376];

   o  t = timestamp; syntax is the same as the "t=" tag defined in
      Section 3.5 of [RFC6376].

=head2 chain() - get or set the chain parameter (cv=) field

This must be one of "pass", "fail" or "none".  For a chain to be valid,
the very first (i=1) seal MUST be cv=none, and all further seals MUST be
cv=pass.

=head2 instance() - get or set the signing instance (i=) field

  my $i = $signature->instance;

Instances must be integers less than 1024 according to the spec.

=head1 SEE ALSO

L<Mail::DKIM::Signature> for DKIM-Signature headers

L<Mail::DKIM::ARC::MessageSignature> for ARC-Message-Signature headers

=head1 AUTHORS

=over 4

=item *

Jason Long <jason@long.name>

=item *

Marc Bradshaw <marc@marcbradshaw.net>

=item *

Bron Gondwana <brong@fastmailteam.com> (ARC)

=back

=head1 THANKS

Work on ensuring that this module passes the ARC test suite was
generously sponsored by Valimail (https://www.valimail.com/)

=head1 COPYRIGHT AND LICENSE

=over 4

=item *

Copyright (C) 2013 by Messiah College

=item *

Copyright (C) 2010 by Jason Long

=item *

Copyright (C) 2017 by Standcore LLC

=item *

Copyright (C) 2020 by FastMail Pty Ltd

=back

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
