package Mac::iTunes::Item;
use strict;
use warnings;

use vars qw($VERSION);

$VERSION = '1.23';

use MP3::Info qw(get_mp3tag);

=head1 NAME

Mac::iTunes::Item

=head1 SYNOPSIS

	use Mac::iTunes::Item;

	my $item = Mac::iTunes::Item->new(
		{
		title    => $title,
		genre    => $genre,
		seconds  => $seconds,
		file     => $path,
		artist   => $artist,
		url      => $url,
		}
		);

=head1 DESCRIPTION

**This module is unmaintained**


Create an iTunes item (aka track).

=head1 METHODS

=over 4

=item new

=cut

sub new
	{
	my $class = shift;
	my $hash  = shift;

	return unless UNIVERSAL::isa( $hash, 'HASH' );

	my $self = $hash;

	bless $self, $class;

	return $self;
	}

=item new_from_mp3( FILE )

Creates a new item from the given file name.

=cut

sub new_from_mp3
	{
	my $class = shift;
	my $file  = shift;

	return unless -e $file;

	my $tag  = MP3::Info::get_mp3tag( $file );
	my $info = MP3::Info::get_mp3info( $file );
	# XXX: convert to an absolute path, if necessary

	# XXX: return unless it's an MP3 file

	# XXX: extract info from MP3 file

	my $self = {
		title    => $tag->{TITLE},
		genre    => $tag->{GENRE},
		seconds  => $info->{SECS},
		file     => $file,
		artist   => $tag->{ARTIST},
		_tag     => $tag,
		_info    => $info,
		};

	bless $self, $class;

	return $self;
	}

# make a fake object, for testing.
sub _new
	{
	my $class = shift;
	my $num   = shift;

	bless \$num, $class;
	}

=item copy

Return a deep copy of the item.  The returned object will not
refer (as in, point to the same data) as the original object.

=cut

sub copy
	{
	my $self = shift;

	my $ref = {};

	foreach my $key ( qw(title genre seconds file artist) )
		{
		$ref->{$key} = $self->{$key};
		}

	foreach my $key ( qw(_tag _info) )
		{
		foreach my $subkey ( keys %{ $self->{$key} } )
			{
			$ref->{$key}{$subkey} = $self->{$key}{$subkey};
			}
		}

	return $ref;
	}

=item title

Return the title of the item

=cut

sub title
	{
	my $self = shift;

	$self->{title};
	}

=item seconds

Return the length, in seconds, of the item

=cut

sub seconds
	{
	my $self = shift;

	$self->{seconds};
	}

=item genre

Return the genre of the song

=cut

sub genre
	{
	my $self = shift;

	$self->{genre};
	}

=item file

Return the filename of the item

=cut

sub file
	{
	my $self = shift;

	$self->{file};
	}

=item artist

Return the artist of the item

=cut

sub artist
	{
	my $self = shift;

	$self->{artist};
	}

=item as_string

Return a string representation of the item

=cut

sub as_string
	{
	my $self = shift;

	return <<"STRING";
FILE    $$self{file}
TITLE   $$self{title}
GENRE   $$self{genre}
ARTIST  $$self{artist}
TIME    $$self{seconds} seconds

STRING
	}

"See why 1984 won't be like 1984";

=back

=head1 SOURCE AVAILABILITY

This source is in GitHub:

	https://github.com/CPAN-Adopt-Me/MacOSX-iTunes.git

=head1 SEE ALSO

L<Mac::iTunes>, L<Mac::iTunes::Playlist>, L<MP3::Info>

=head1 TO DO

* everything - the list of things already done is much shorter.

=head1 AUTHOR

brian d foy,  C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002-2007 brian d foy.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
