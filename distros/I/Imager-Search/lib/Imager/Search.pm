package Imager::Search;

=pod

=head1 NAME

Imager::Search - Find images within other images

=head1 SYNOPSIS

  use Imager::Search ();
  
  # Load the pattern to search for
  my $pattern = Imager::Search::Pattern->new(
      driver => 'Imager::Search::Driver::HTML24',
      file   => 'pattern.bmp',
  );
  
  # Load the image to search in
  my $image = Imager::Search::Image->new(
      driver => 'Imager::Search::Driver::HTML24',
      file   => 'target.bmp',
  );
  
  # Execute the search
  my @matches = $image->find( $pattern );
  print "Found " . scalar(@matches) . " matches\n";

=head1 DESCRIPTION

The regular expression engine provided with Perl has demonstrated itself
to be both fully featured and extremely fast for tasks involving searching
for patterns within a string.

The CPAN module L<Imager> has demonstrated robust functionality and
excellent speed across all common operating system platforms for tasks
involving working with images.

The goal of B<Imager::Search> takes the best features from L<Imager> and the
regular expression engine and combines them to produce a simple pure perl
image recognition engine for systems in which the images are pixel perfect.

And equally importantly, B<Imager::Search> does it very very fast.

Benchmarking a simple program that continuously monitors a 1024x768 display
for a single target image on a cheap 1.5Ghtz Windows machine demonstrated
a monitoring rate of 5 frames per second using the default BMP24 driver.

That is, 0.2 seconds to capture the screenshot, convert it into a searchable
string, generate a search regexp, execute the regexp and then convert the
results into match objects.

Finally, B<Imager::Search> itself is pure Perl, and should work quite
simply on any platform that the L<Imager> module supports, which at time
of writing includes Windows, Mac OS X and most other forms of Unix.

=head2 Use Cases

L<Imager::Search> is intended to be useful for a range of tasks involving
images from computing systems and the digital world in general.

The range of potential applications include monitoring screenshots from
kiosk and advertising systems for evidence of crashes or embarrasing popup
messages, automating interactions with graphics-intense desktop or website
applications that would be otherwise intractable for traditional automation
methods, and simple text recognition in systems with fonts that register to
fixed pixel patterns.

For example, by storing captured image fragments of a sample set of playing
cards, a program might conceptually be able to look at a solitaire-type
game and establish the position and identity of all the cards on the screen,
populating a model of the current game state and then allowing the
automation of the playing of the game.

L<Imager::Search> is B<NOT> intended to be useful for tasks such as facial
recognition or any other tasks involving real world images.

=head2 Methodology

Regular expressions are domain-specific Non-Finite Automata (NFA)
programs designed to detect patterns within strings.

Given the problem of locating a smaller "search image" one or more
times inside a larger "target image", we compile the target image into
a suitable string and compile the search image into a suitable regular
expression.

By executing the search regular expression on the target string, and
translating the results of the run back into image terms, we can
determine the specific location of all instances of the search image
inside the target image with relative ease.

By decomposing the image recognition task into a regular expression task,
the problem then becomes how to define a series of transforms that can
generate a suitable search expression, generate a suitable target
string, and derive the match locations in pixel terms from match locations
in character/byte terms.

=head2 The Driver API

While it is fairly easy to conceive of what a potential solution might look
like, implementing any solution is complicated by the need for all the code
surrounding the regular expression execution to be fast as well.

For example, a 0.01 second regular expression search time is of no value
if compiling the search and target images takes several seconds.

It may also be viable to achieve a shorter total processing time by
storing the target image in a format which is inherently searchable
(such as Windows BMP) and using slower and more complex search expression.

Different implementations may be superior in cases where compiled search
expressions are cached and applied to many target images, versus cases
where compiled target images are cached and search over by many search
expressions.

L<Imager::Search> responds to this ambiguity by not imposing a single
solution, but instead defining a driver API for the transforms, so that
a number of different implementations can be used with the same API in
various situations.

=head2 The HTML24 Driver

A default "HTML24" implementation is provided with the module. This is a
reference driver that encodes each pixel as a 24-bit HTML "#RRGGBB" colour
code.

This driver demonstrates fast search times and a simple match resolution,
but has an extremely slow method for generating the target images (as slow
as 10 gigacyles for a typical 1024x768 pixel screenshot).

Faster drivers are currently being pursued.

=head1 USAGE

This new second-generation incarnation of L<Imager::Search> is still in
flux, so while the API for the individual classes are relatively stable,
there is not yet a top level convenience API in the B<Imager::Search>
namespace itself, and the driver API is still being substantially changed
in response to the differing needs of different styles of driver.

However a typical (if verbose) usage can be demonstrated, that should
continue to work for a while...

=head2 1. Load the Search Image

  # An image loaded from a file
  use Imager::Search::Image ();
  my $image = Imager::Search::Image->new(
      driver => 'Imager::Search::Driver::HTML24',
      file   => 'target.bmp',
  );
  
  # An image captured from a screenshot
  use Imager::Search::Screenshot ();
  my $screen = Imager::Search::Screenshot->new(
      driver => 'Imager::Search::Driver::HTML24',
  );

=head2 2. Load the Search Pattern

  # A pattern loaded from a file
  use Imager::Search::Pattern ();
  my $pattern = Imager::Search::Pattern->new(
      driver => 'Imager::Search::Driver::HTML24',
      file   => 'pattern.bmp',
  );

=head2 3. Execute the Search

  # Find the first match
  my $first = $image->find_first( $pattern );
  
  # Find all matches
  my @matches = $image->find( $pattern );

=head1 CLASSES

The following is the complete list of classes provided by the main
B<Imager-Search> distribution.

=head2 Imager::Search::Image

L<Imager::Search::Image> implements the an image that will be searched
within.

=head2 Imager::Search::Screenshot

L<Imager::Search::Screenshot> is a L<Imager::Search::Image>
subclass that captures an image from the currently active window.

=head2 Imager::Search::Pattern

L<Imager::Search::Pattern> provides compiled search pattern objects

=head2 Imager::Search::Match

L<Imager::Search::Match> provides objects that represent locations in
images where a pattern was found.

=head2 Imager::Search::Driver

L<Imager::Search::Driver> is the abstract driver interface. It cannot
be instantiated directly, but it describes (in both code and documentation)
what any driver needs to implement.

=head2 Imager::Search::Driver::HTML24

L<Imager::Search::Driver::HTML24> is an 24-bit reference driver that uses
HTML colour codes (#RRGGBB) to represent each pixel.

=head2 Imager::Search::Driver::BMP24

L<Imager::Search::Driver::BMP24> is a high performance 24-bit driver that
uses the Windows BMP file format natively for the image string format.

=cut

use 5.006;
use strict;
use Carp ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.01';
}

use Imager::Search::Pattern ();
use Imager::Search::Driver  ();
use Imager::Search::Match   ();

1;

=pod

=head1 SUPPORT

No support is available for this module.

However, bug reports may be filed at the following URI.

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Imager-Search>

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2007 - 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
