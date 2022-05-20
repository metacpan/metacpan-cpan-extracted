package Mail::DKIM::Canonicalization::DkimCommon;
use strict;
use warnings;
our $VERSION = '1.20220520'; # VERSION
# ABSTRACT: common canonicalization

# Copyright 2005-2007 Messiah College. All rights reserved.
# Jason Long <jlong@messiah.edu>

# Copyright (c) 2004 Anthony D. Urso. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use base 'Mail::DKIM::Canonicalization::Base';
use Carp;

sub init {
    my $self = shift;
    $self->SUPER::init;

    $self->{body_count}     = 0;
    $self->{body_truncated} = 0;

    # these canonicalization methods require signature to use
    $self->{Signature}
      or croak 'no signature specified';
}

# similar to code in DkCommon.pm
sub add_header {

    #Note: canonicalization of headers is performed
    #in finish_header()
}

sub finish_header {
    my $self = shift;
    my %args = @_;

    # Headers are canonicalized in the order specified by the h= tag.
    # However, in the case of multiple instances of the same header name,
    # the headers will be canonicalized in reverse order (i.e. "from
    # the bottom of the header field block to the top").
    #
    # This is described in 5.4 of RFC4871.

    # Since the bottom-most headers are to get precedence, we reverse
    # the headers here... (now the first header matching a particular
    # name is the header to insert)
    my @mess_headers = reverse @{ $args{Headers} };

    # presence of a h= tag is mandatory...
    unless ( defined $self->{Signature}->headerlist ) {
        die "Error: h= tag is required for this canonicalization\n";
    }

    # iterate through the header field names specified in the signature
    my @sig_headers = $self->{Signature}->headerlist;
    foreach my $hdr_name (@sig_headers) {
        $hdr_name = lc $hdr_name;

        # find the specified header in the message
      inner_loop:
        for ( my $i = 0 ; $i < @mess_headers ; $i++ ) {
            my $hdr = $mess_headers[$i];

            if ( $hdr =~ /^([^\s:]+)\s*:/ ) {
                my $key = lc $1;
                if ( $key eq $hdr_name ) {

                    # found it

                    # remove it from our list, so if it occurs more than
                    # once, we'll get the next header in line
                    splice @mess_headers, $i, 1;

                    $hdr =~ s/\015\012\z//s;
                    $self->output(
                        $self->canonicalize_header($hdr) . "\015\012" );
                    last inner_loop;
                }
            }
        }
    }
}

sub add_body {
    my $self = shift;
    my ($multiline) = @_;

    $multiline = $self->canonicalize_body($multiline);
    if ( $self->{Signature} ) {
        if ( my $limit = $self->{Signature}->body_count ) {
            my $remaining = $limit - $self->{body_count};
            if ( length($multiline) > $remaining ) {
                $self->{body_truncated} += length($multiline) - $remaining;
                $multiline = substr( $multiline, 0, $remaining );
            }
        }
    }

    $self->{body_count} += length($multiline);
    $self->output($multiline);
}

sub finish_body {
}

sub finish_message {
    my $self = shift;

    if ( $self->{Signature} ) {
        $self->output("\015\012");

        # append the DKIM-Signature (without data)
        my $line = $self->{Signature}->as_string_without_data;

        # signature is subject to same canonicalization as headers
        $self->output( $self->canonicalize_header($line) );
    }
}

sub body_count {
    my $self = shift;
    return $self->{body_count};
}

sub body_truncated {
    my $self = shift;
    return $self->{body_truncated};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::DKIM::Canonicalization::DkimCommon - common canonicalization

=head1 VERSION

version 1.20220520

=head1 DESCRIPTION

This class implements functionality that is common to all the
currently-defined DKIM canonicalization methods, but not necessarily
common with future canonicalization methods.

For functionality that is common to all canonicalization methods
(including future methods), see Mail::DKIM::Canonicalization::Base.

=head1 NAME

Mail::DKIM::Canonicalization::DkimCommon - common canonicalization methods

=head1 SEE ALSO

Mail::DKIM::Canonicalization::Base

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
