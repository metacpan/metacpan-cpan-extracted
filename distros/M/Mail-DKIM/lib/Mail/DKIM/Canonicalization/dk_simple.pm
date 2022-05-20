package Mail::DKIM::Canonicalization::dk_simple;
use strict;
use warnings;
our $VERSION = '1.20220520'; # VERSION
# ABSTRACT: dk simple canonicalization

# Copyright 2005 Messiah College. All rights reserved.
# Jason Long <jlong@messiah.edu>

# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use base 'Mail::DKIM::Canonicalization::DkCommon';
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

    return $line;
}

sub canonicalize_body {
    my $self = shift;
    my ($multiline) = @_;

    # ignore empty lines at the end of the message body
    #
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

Mail::DKIM::Canonicalization::dk_simple - dk simple canonicalization

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
