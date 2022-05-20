package Mail::DKIM::Canonicalization::relaxed;
use strict;
use warnings;
our $VERSION = '1.20220520'; # VERSION
# ABSTRACT: common canonicalization

# Copyright 2005 Messiah College. All rights reserved.
# Jason Long <jlong@messiah.edu>

# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use base 'Mail::DKIM::Canonicalization::DkimCommon';
use Carp;

sub init {
    my $self = shift;
    $self->SUPER::init;

    $self->{canonicalize_body_empty_lines} = 0;
}

sub canonicalize_header {
    my $self = shift;
    croak 'wrong number of parameters' unless ( @_ == 1 );
    my ($line) = @_;

    #
    # step 1: convert all header field names (not the header field values)
    # to lower case
    #
    if ( $line =~ /^([^:]+):(.*)/s ) {

        # lowercase field name
        $line = lc($1) . ":$2";
    }

    #
    # step 2: unwrap all header field continuation lines... i.e.
    # remove any CRLF sequences that are followed by WSP
    #
    $line =~ s/\015\012(\s)/$1/g;

    #
    # step 3: convert all sequences of one or more WSP characters to
    # a single SP character
    #
    $line =~ s/[ \t]+/ /g;

    #
    # step 4: delete all WSP characters at the end of the header field value
    #
    $line =~ s/ \z//s;

    #
    # step 5: delete any WSP character remaining before and after the colon
    # separating the header field name from the header field value
    #
    $line =~ s/^([^:\s]+)\s*:\s*/$1:/;

    return $line;
}

sub canonicalize_body {
    my ($self, $multiline) = @_;

    $multiline =~ s/\015\012\z//s;

    #
    # step 1: reduce all sequences of WSP within a line to a single
    # SP character
    #
    $multiline =~ s/[ \t]+/ /g;

    #
    # step 2: ignore all white space at the end of lines
    #
    $multiline =~ s/[ \t]+(?=\015\012|\z)//g;

    $multiline .= "\015\012";

    #
    # step 3: ignore empty lines at the end of the message body
    # (i.e. do not emit empty lines until a following nonempty line
    # is found)
    #

    my $empty_lines = $self->{canonicalize_body_empty_lines};

    if ( $multiline =~ s/^((?:\015\012)+)// )
    {    # count & strip leading empty lines
        $empty_lines += length($1) / 2;
    }

    if ( $empty_lines > 0 && length($multiline) > 0 )
    {    # re-insert leading white if any nonempty lines exist
        $multiline   = ( "\015\012" x $empty_lines ) . $multiline;
        $empty_lines = 0;
    }

    while ( $multiline =~ /\015\012\015\012\z/ )
    {    # count & strip trailing empty lines
        chop $multiline;
        chop $multiline;
        $empty_lines++;
    }

    $self->{canonicalize_body_empty_lines} = $empty_lines;
    return $multiline;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::DKIM::Canonicalization::relaxed - common canonicalization

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
