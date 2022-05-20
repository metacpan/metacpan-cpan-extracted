package Mail::DKIM::Canonicalization::nowsp;
use strict;
use warnings;
our $VERSION = '1.20220520'; # VERSION
# ABSTRACT: nowsp canonicalization

# Copyright 2005 Messiah College. All rights reserved.
# Jason Long <jlong@messiah.edu>

# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use base 'Mail::DKIM::Canonicalization::DkimCommon';
use Carp;

sub canonicalize_header {
    my $self = shift;
    croak 'wrong number of parameters' unless ( @_ == 1 );
    my ($line) = @_;

    # remove all whitespace
    $line =~ s/[ \t\015\012]//g;

    if ( $line =~ /^([^:]+):(.*)$/ ) {

        # lowercase field name
        $line = lc($1) . ":$2";
    }

    return $line;
}

sub canonicalize_body {
    my $self = shift;
    my ($multiline) = @_;

    $multiline =~ s/[ \t\015\012]//g;
    return $multiline;
}

sub finish_body {
    my $self = shift;
    $self->SUPER::finish_body;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::DKIM::Canonicalization::nowsp - nowsp canonicalization

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
