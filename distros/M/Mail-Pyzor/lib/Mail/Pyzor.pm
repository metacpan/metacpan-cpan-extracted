package Mail::Pyzor;

# Copyright 2018 cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

our $VERSION = '0.02';

=encoding utf-8

=head1 NAME

Mail::Pyzor - Pyzor spam filtering in Perl

=head1 DESCRIPTION

This distribution contains Perl implementations of parts of
L<Pyzor|http://pyzor.org>, a tool for use in spam email filtering.
It is intended for use with L<Mail::SpamAssassin> but may be useful
in other contexts.

See the following modules for information on specific tools that
the distribution includes:

=over

=item * L<Mail::Pyzor::Client>

=item * L<Mail::Pyzor::Digest>

=back

=head1 STABILITY

This module’s API is EXPERIMENTAL. Please check the changelog
before updating to a new release.

=cut

1;
