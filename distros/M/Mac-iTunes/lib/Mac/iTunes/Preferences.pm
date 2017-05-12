package Mac::iTunes::Preferences;
use strict;
use warnings;

use vars qw($VERSION);

$VERSION = '1.23';

=head1 NAME

Mac::iTunes::Preferences - interact with the iTunes Preferences

=head1 SYNOPSIS

	use Mac::iTunes;

	$prefs = Mac::iTunes->preferences;

=head1 DESCRIPTION

**This module is unmaintained**

=cut

use Mac::PropertyList;

sub _default_prefs
	{
	return;
	}

=over 4

=item parse_file( FILENAME )

=cut

sub parse_file
	{
	my $class = shift;
	my $filename = shift || _default_prefs;

	open my($fh), $filename or return;
	my $string = do { local $/; <$fh> };
	close $fh;

	$class->parse( $string );
	}

=item parse( STRING )

=cut

sub parse
	{
	my $class  = shift;
	my $string = shift;

	my $plist = Mac::PropertyList::parse_plist( $string );

	bless $plist, $class;
	}

=back

=head1 SOURCE AVAILABILITY

This source is in GitHub:

	https://github.com/CPAN-Adopt-Me/MacOSX-iTunes.git

=head1 TO DO

* make it not read-only

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002-2007 brian d foy.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

"See why 1984 won't be like 1984";
