package Mail::DKIM::MessageParser;
use strict;
use warnings;
our $VERSION = '1.20261105'; # VERSION
# ABSTRACT: Signs/verifies Internet mail with DKIM/DomainKey signatures

# Copyright 2005 Messiah College. All rights reserved.
# Jason Long <jlong@messiah.edu>

# Copyright (c) 2004 Anthony D. Urso. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use Carp;

sub new_object {
    my $class = shift;
    return $class->TIEHANDLE(@_);
}

sub new_handle {
    my $class = shift;
    local *TMP;
    tie *TMP, $class, @_;
    return *TMP;
}

sub TIEHANDLE {
    my $class = shift;
    my %args  = @_;
    my $self  = bless \%args, $class;
    $self->init;
    return $self;
}

sub init {
    my $self = shift;

    my $buf = '';
    $self->{buf_ref}     = \$buf;
    $self->{in_header}   = 1;
    $self->{header_scan} = 0;
}

sub PRINT {
    my $self    = shift;
    my $buf_ref = $self->{buf_ref};
    $$buf_ref .= @_ == 1 ? $_[0] : join( '', @_ ) if @_;

    if ( $self->{in_header} ) {

        # Walk the buffer with an offset, remove the parsed fields once,
        # and resume the search for the end of an incomplete field where
        # the last call stopped: removing each field from the front of
        # the buffer, or rescanning an incomplete field on every call,
        # is quadratic.
        my $off  = 0;
        my $scan = $self->{header_scan};
        while ( $off < length($$buf_ref) ) {
            if ( substr( $$buf_ref, $off, 2 ) eq "\015\012" ) {
                substr( $$buf_ref, 0, $off + 2 ) = '';
                $off = $scan = 0;
                $self->finish_header();
                $self->{in_header} = 0;
                last;
            }

            # the field ends at the first CRLF not followed by SP or HTAB
            my $end;
            my $i = $scan > $off ? $scan : $off;
            while (1) {
                my $j = index( $$buf_ref, "\015\012", $i );
                if ( $j < 0 ) {
                    $i = length($$buf_ref) - 1;    # a final CR may start a CRLF
                    last;
                }
                if ( $j + 2 >= length($$buf_ref) ) {
                    $i = $j;    # the next character isn't here yet
                    last;
                }
                my $c = substr( $$buf_ref, $j + 2, 1 );
                if ( $c ne ' ' && $c ne "\t" ) {
                    $end = $j + 2;
                    last;
                }
                $i = $j + 2;
            }
            if ( !defined $end ) {
                $scan = $i;
                last;
            }
            $self->add_header( substr( $$buf_ref, $off, $end - $off ) );
            $off  = $end;
            $scan = 0;
        }
        substr( $$buf_ref, 0, $off ) = '' if $off;
        $self->{header_scan} = $scan > $off ? $scan - $off : 0;
    }

    if ( !$self->{in_header} ) {
        my $j = rindex( $$buf_ref, "\015\012" );
        if ( $j >= 0 ) {

            # avoid copying a large buffer: the unterminated
            # last line is typically short compared to the rest

            my $carry = substr( $$buf_ref, $j + 2 );
            substr( $$buf_ref, $j + 2 ) = '';    # shrink to last CRLF
            $self->add_body($$buf_ref);          # must end on CRLF
            $$buf_ref = $carry;    # restore unterminated last line
        }
    }
    return 1;
}

sub CLOSE {
    my $self    = shift;
    my $buf_ref = $self->{buf_ref};

    if ( $self->{in_header} ) {
        if ( $$buf_ref ne '' ) {

            # A line of header text ending CRLF would not have been
            # processed yet since before we couldn't tell if it was
            # the complete header. Now that we're in CLOSE, we can
            # finish the header...
            $$buf_ref =~ s/\015\012\z//s;
            $self->add_header("$$buf_ref\015\012");
        }
        $self->finish_header;
        $self->{in_header} = 0;
    }
    else {
        if ( $$buf_ref ne '' ) {
            $self->add_body($$buf_ref);
        }
    }
    $$buf_ref = '';
    $self->finish_body;
    return 1;
}

sub add_header {
    die 'add_header not implemented';
}

sub finish_header {
    die 'finish_header not implemented';
}

sub add_body {
    die 'add_body not implemented';
}

sub finish_body {

    # do nothing by default
}

sub reset {
    carp 'reset not implemented';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::DKIM::MessageParser - Signs/verifies Internet mail with DKIM/DomainKey signatures

=head1 VERSION

version 1.20261105

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
