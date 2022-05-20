package Mail::DKIM::Canonicalization::DkCommon;
use strict;
use warnings;
our $VERSION = '1.20220520'; # VERSION
# ABSTRACT: dk common canonicalization

# Copyright 2005-2006 Messiah College. All rights reserved.
# Jason Long <jlong@messiah.edu>

# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use base 'Mail::DKIM::Canonicalization::Base';
use Carp;

sub init {
    my $self = shift;
    $self->SUPER::init;

    $self->{header_count} = 0;
}

# similar to code in DkimCommon.pm
sub add_header {

    #Note: canonicalization of headers is performed
    #in finish_header()

    my $self = shift;
    $self->{header_count}++;
}

sub finish_header {
    my $self = shift;
    my %args = @_;

    # RFC4870, 3.3:
    #   h = A colon-separated list of header field names that identify the
    #       headers presented to the signing algorithm. If present, the
    #       value MUST contain the complete list of headers in the order
    #       presented to the signing algorithm.
    #
    #       In the presence of duplicate headers, a signer may include
    #       duplicate entries in the list of headers in this tag.  If a
    #       header is included in this list, a verifier must include all
    #       occurrences of that header, subsequent to the "DomainKey-
    #       Signature:" header in the verification.
    #
    # RFC4870, 3.4.2.1:
    #   * Each line of the email is presented to the signing algorithm in
    #     the order it occurs in the complete email, from the first line of
    #     the headers to the last line of the body.
    #   * If the "h" tag is used, only those header lines (and their
    #     continuation lines if any) added to the "h" tag list are included.

    # only consider headers AFTER my signature
    my @sig_headers;
    {
        my $s0 = @{ $args{Headers} } - $self->{header_count};
        my $s1 = @{ $args{Headers} } - 1;
        @sig_headers = ( @{ $args{Headers} } )[ $s0 .. $s1 ];
    }

    # check if signature specifies a list of headers
    my @sig_header_names = $self->{Signature}->headerlist;
    if (@sig_header_names) {

        # - first, group all header fields with the same name together
        #   (using a hash of arrays)
        my %heads;
        foreach my $line (@sig_headers) {
            next unless $line =~ /^([^\s:]+)\s*:/;
            my $field_name = lc $1;

            $heads{$field_name} ||= [];
            push @{ $heads{$field_name} }, $line;
        }

        # - second, count how many times each header field name appears
        #   in the h= tag
        my %counts;
        foreach my $field_name (@sig_header_names) {
            $heads{ lc $field_name } ||= [];
            $counts{ lc $field_name }++;
        }

        # - finally, working backwards through the h= tag,
        #   collect the headers we will be signing (last to first).
        #   Normally, one occurrence of a name in the h= tag
        #   correlates to one occurrence of that header being presented
        #   to canonicalization, but if (working backwards) we are
        #   at the first occurrence of that name, and there are
        #   multiple headers of that name, then put them all in.
        #
        @sig_headers = ();
        while ( my $field_name = pop @sig_header_names ) {
            $counts{ lc $field_name }--;
            if ( $counts{ lc $field_name } > 0 ) {

                # this field is named more than once in the h= tag,
                # so only take the last occuring of that header
                my $line = pop @{ $heads{ lc $field_name } };
                unshift @sig_headers, $line if defined $line;
            }
            else {
                unshift @sig_headers, @{ $heads{ lc $field_name } };
                $heads{ lc $field_name } = [];
            }
        }
    }

    # iterate through each header, in the order determined above
    foreach my $line (@sig_headers) {
        if ( $line =~ /^(from|sender)\s*:(.*)$/i ) {
            my $field   = $1;
            my $content = $2;
            $self->{interesting_header}->{ lc $field } = $content;
        }
        $line =~ s/\015\012\z//s;
        $self->output( $self->canonicalize_header( $line . "\015\012" ) );
    }

    $self->output( $self->canonicalize_body("\015\012") );
}

sub add_body {
    my $self = shift;
    my ($multiline) = @_;

    $self->output( $self->canonicalize_body($multiline) );
}

sub finish_body {
}

sub finish_message {
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::DKIM::Canonicalization::DkCommon - dk common canonicalization

=head1 VERSION

version 1.20220520

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
