#!/usr/bin/perl

package Log::Dispatch::Binlog;

use strict;

use vars qw($VERSION);

$VERSION = "0.02";

__PACKAGE__

__END__

=pod

=head1 NAME

Log::Dispatch::Binlog - L<Storable> based binary logs.

=head1 SYNOPSIS

	use Log::Dispatch::Binlog::File;

	# or

	use Log::Dispatch::Binlog::Handle;

=head1 DESCRIPTION

The two classes provide in this distribution provide L<Storable> based binary
logging for L<Log::Dispatch>.

This is useful for testing your log output, or for delegating log output to
a listener on a socket without losing high level information.

This file is just for documentation/version purposes, you must use one of
L<Log::Dispatch::Binlog::File> or L<Log::Dispatch::Binlog::Handle> directly.

=head1 VERSION CONTROL

This module is maintained using Darcs. You can get the latest version from
L<http://nothingmuch.woobling.org/code>, and use C<darcs send> to commit
changes.

=head1 AUTHOR

Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT

	Copyright (c) 2008 Yuval Kogman. All rights reserved
	This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut
