#!/usr/bin/perl
# $Id$
use strict;

=head1 NAME

publisher.pl - reformat iTunes Music Library

=head1 SYNOPSIS

	% publisher.pl TEMPLATE [ LIBRARY [ PLAYLIST ] ]

=head1 DESCRIPTION

This script reformats the iTunes Music Library according to the
Text::Template template in TEMPLATE.  By default it uses the
iTunes Music Library in your home directory, or the file you
specify in LIBRARY.  It works with all the tracks in the
library by default, or the playlist PLAYLIST.

The template has access to these variables:

=over 4

=item $playlist

Name of the playlist

=item @items

Array of Mac::iTunes::Item objects

=back

=head1 AUTHOR

brian d foy, E<lt>bdfoy@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2002, brian d foy, All rights reserved.

You may use this script under the same terms as Perl itself.

=cut

use Mac::iTunes;
use Text::Template 'fill_in_file';

my $template = $ARGV[0] || die "Specify an output template file\n";
my $file     = $ARGV[1] || "$ENV{HOME}/Music/iTunes/iTunes 3 Music Library";
my $playlist = $ARGV[2] || 'Library';

die "Music library file [$file] does not exist\n"   unless -e $file;
die "Output template file [$file] does not exist\n" unless -e $template;

my $itunes = Mac::iTunes->read( $file );
die unless ref $itunes;

my $playlist = $itunes->get_playlist( $playlist );

print fill_in_file( $template, HASH =>
	{
	playlist => $playlist->title,
	items    => [ $playlist->items ],
	} );

