package File::Find::Rule::MP3Info;
use strict;

use File::Find::Rule;
use base qw( File::Find::Rule );
use vars qw( @EXPORT $VERSION );
@EXPORT  = @File::Find::Rule::EXPORT;
$VERSION = '0.01';

use MP3::Info;
use Number::Compare;

=head1 NAME

File::Find::Rule::MP3Info - rule to match on id3 tags, length, bitrate, etc

=head1 SYNOPSIS

  use File::Find::Rule::MP3Info;

  # Which mp3s haven't I set the artist tag on yet?
  my @mp3s = find( mp3info => { ARTIST => '' }, in => '/mp3' );

  # Or be OO.
  @mp3s = File::Find::Rule::MP3Info->file()
  	                           ->mp3info( TITLE => 'Paper Bag' )
	                           ->in( '/mp3' );

  # What have I got that's 3 minutes or longer?
  @mp3s = File::Find::Rule::MP3Info->file()
                                   ->mp3info( MM => '>=3' )
                                   ->in( '/mp3' );

  # What have I got by either Kristin Hersh or Throwing Muses?
  # I'm sometimes lazy about case in my tags.
  @mp3s = find( mp3info =>
                    { ARTIST => qr/(kristin hersh|throwing muses)/i },
	        in => '/mp3' );

=head1 DESCRIPTION

An interface between MP3::Info and File::Find::Rule to let you find
files based on MP3-specific information such as bitrate, frequency,
playing time, the stuff in the ID3 tag, and so on.

=head1 METHODS

=head2 B<mp3info>

  my @mp3s = find( mp3info => { YEAR => '1990' }, in => '/mp3' );

Only matches when I<all> criteria are met.  You can be OO or
procedural as you please, as per File::Find::Rule.

The criteria you can use are those that are returned by the
C<get_mp3tag> and C<get_mp3info> methods of MP3::Info.

The following fields are treated as numeric and so can be matched
against using Number::Compare comparisons: YEAR, BITRATE, FREQUENCY,
SIZE, SECS, MM, SS, MS, FRAMES, FRAME_LENGTH, VBR_SCALE.

The following fields are treated as strings and so can be matched
against with either an exact match or a qr// regex: TITLE, ARTIST,
ALBUM, COMMENT, GENRE.

Anything else is matched against as an exact match.

Let's make it DTRT with boolean fields, next!

This needs benchmarking; will it be impossibly slow with lots of files?
I'm seeing around a minute or so to go through 6 gig.

=cut

my %numeric = map { $_ => 1 } qw( YEAR BITRATE FREQUENCY SIZE SECS MM SS MS
                                  FRAMES FRAME_LENGTH VBR_SCALE );
my %strings = map { $_ => 1 } qw( TITLE ARTIST ALBUM COMMENT GENRE );

sub File::Find::Rule::mp3info {
    my $self = shift()->_force_object;

    # Procedural interface allows passing arguments as a hashref.
    my %criteria = UNIVERSAL::isa($_[0], "HASH") ? %{$_[0]} : @_;

    $self->exec( sub {
                     my $file = shift;
                     my $info = get_mp3info($file) or return;
                     my $tag = get_mp3tag($file) or return;
                     for my $fld (keys %criteria) {
                         # Field can be in id3tag, other info, or not defined.
		         my $value =
                           defined $tag->{$fld} ? $tag->{$fld} : $info->{$fld};
			 return unless defined $value;

			 if ( $numeric{$fld} ) {
			     my $cmp = Number::Compare->new($criteria{$fld});
			     return unless $cmp->($value);
			 } elsif ( $strings{$fld}
				   and ref $criteria{$fld} eq 'Regexp') {
			     return unless $value =~ /$criteria{$fld}/;
			 } else {
			     return unless $value eq $criteria{$fld};
                         }
		     }
		     return 1;
                 } );
}

=head1 AUTHOR

Kake Pugh <kake@earth.li>, from an idea by Paul Mison, all the real
work previously done by Richard Clamp in File::Find::Rule and Chris
Nandor in MP3::Info.

=head1 FEEDBACK

Send me mail; it makes me happy.  Does this suck?  Why?  Does it rock?
Why?

=head1 COPYRIGHT

Copyright (C) 2002 Kate L Pugh.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

  File::Find::Rule
  MP3::Info

=cut

1;
