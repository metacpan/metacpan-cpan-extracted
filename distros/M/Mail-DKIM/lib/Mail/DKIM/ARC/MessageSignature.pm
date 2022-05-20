package Mail::DKIM::ARC::MessageSignature;
use strict;
use warnings;
our $VERSION = '1.20220520'; # VERSION
# ABSTRACT: Subclass of Mail::DKIM::Signature which represents a ARC-Message-Signature header

# Copyright 2017 FastMail Pty Ltd. All Rights Reserved.
# Bron Gondwana <brong@fastmailteam.com>

# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use base 'Mail::DKIM::Signature';
use Carp;


sub new {
    my $class = shift;
    my %prms  = @_;
    my $self  = {};
    bless $self, $class;

    $self->instance( $prms{'Instance'} ) if exists $prms{'Instance'};
    $self->algorithm( $prms{'Algorithm'} || 'rsa-sha256' );
    $self->signature( $prms{'Signature'} );
    $self->canonicalization( $prms{'Method'} ) if exists $prms{'Method'};
    $self->domain( $prms{'Domain'} );
    $self->headerlist( $prms{'Headers'} );
    $self->protocol( $prms{'Query'} ) if exists $prms{'Query'};
    $self->selector( $prms{'Selector'} );
    $self->timestamp( $prms{'Timestamp'} )   if defined $prms{'Timestamp'};
    $self->expiration( $prms{'Expiration'} ) if defined $prms{'Expiration'};
    $self->key( $prms{'Key'} )               if defined $prms{'Key'};

    return $self;
}

sub DEFAULT_PREFIX {
    return 'ARC-Message-Signature:';
}


sub instance {
    my $self = shift;

    # ARC identities must be a number
    if (@_) {
        my $val = int(shift);
        die "INVALID instance $val" unless ( $val > 0 and $val < 1025 );
        $self->set_tag( 'i', $val );
    }

    my $i = $self->get_tag('i');
    return $i;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::DKIM::ARC::MessageSignature - Subclass of Mail::DKIM::Signature which represents a ARC-Message-Signature header

=head1 VERSION

version 1.20220520

=head1 CONSTRUCTORS

=head2 new() - create a new signature from parameters

  my $signature = Mail::DKIM::ARC::MessageSignature->new(
                      [ Algorithm => 'rsa-sha256', ]
                      [ Signature => $base64, ]
                      [ Method => 'relaxed', ]
                      [ Domain => 'example.org', ]
                      [ Instance => 1, ]
                      [ Headers => 'from:subject:date:message-id', ]
                      [ Query => 'dns', ]
                      [ Selector => 'alpha', ]
                      [ Timestamp => time(), ]
                      [ Expiration => time() + 86400, ]
                  );

The only differences between this module and Mail::DKIM::Signature are
the header name, and that 'instance' is an integer rather than a base64
encoded value.

=head2 instance() - get or set the signing instance (i=) field

  my $i = $signature->instance;

Instances must be integers less than 1024 according to the spec.

NOTE: the i= field is "Identity" in DKIM and is a base64 value, but in
ARC it is "Instance" and an integer.  The parsing routine does not
check that the i= value is a number.

=head1 SEE ALSO

L<Mail::DKIM::Signature> for DKIM-Signature headers

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
