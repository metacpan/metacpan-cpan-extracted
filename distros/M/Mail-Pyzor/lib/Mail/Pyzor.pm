package Mail::Pyzor;

# Copyright 2018 cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# Apache 2.0 license.

use strict;
use warnings;

our $VERSION = '0.05';

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

=cut

1;
