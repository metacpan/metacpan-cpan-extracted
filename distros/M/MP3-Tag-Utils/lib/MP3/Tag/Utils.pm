package MP3::Tag::Utils;

use warnings;
use strict;
use MP3::Tag;
use Text::NeatTemplate;

=head1 NAME

MP3::Tag::Utils - Assorted utilities for manipulating MP3 files via MP3::Tag.

=head1 VERSION

Version 0.0.3

=cut

our $VERSION = '0.0.3';


=head1 SYNOPSIS

    use MP3::Tag::Utils;

    my $foo = MP3::Tag::Utils->new();
    ...

=head1 METHODS

=head2 new

=cut

sub new{
	my %args;
	if (defined($_[1])) {
		%args=%{$_[1]};
	}
	my $method='new';
	
	
	my $self={
			  perror=>undef,
			  error=>undef,
			  errorString=>'',
			  module=>'MP3-Tag-Utils',
			  };
	bless $self;
	
	return $self;
}

=head2 change

Change the tags on a MP3 file.

=head3 args hash

=head4 file

The file to operate on.

=head4 album

If this is defined, the tag is set to it.

=head4 artist

If this is defined, the tag is set to it.

=head4 comment

If this is defined, the tag is set to it.

=head4 genre

If this is defined, the tag is set to it.

=head4 title

If this is defined, the tag is set to it.

=head4 track

If this is defined, the tag is set to it.

=head4 year

If this is defined, the tag is set to it.

    $foo->change(\%args);
    if($foo->error){
        warn('Error '.$foo->error.': '.$foo->errorString);
    }

=cut

sub change{
	my $self=$_[0];
	my %args;
	if (defined($_[1])) {
		%args=%{$_[1]};
	}
	my $method='rename';

	#blanks any previous errors
	if (!$self->errorblank) {
		warn($self->{module}.' '.$method.': Unable to blank previous error');
		return undef;
	}
	
	#makes sure some files are specified.
	if (!defined($args{file})) {
		$self->{error}=1;
		$self->{errorString}='No file specified';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->{errorString});
		return undef;
	}

	
	#make sure something to change is specified
	if (
		(!defined( $args{album} )) &&
		(!defined( $args{artist} )) &&
		(!defined( $args{comment} )) &&
		(!defined( $args{genre} )) &&
		(!defined( $args{title} )) &&
		(!defined( $args{track} )) &&
		(!defined( $args{year} ))
		) {
		$self->{error}=3;
		$self->{errorString}='Nothing specified to change';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->{errorString});
		return undef;
	}

	#makes sure it appears to be a MP3
	if ($args{file} !~ /[Mm][Pp]3$/) {
		$self->{error}=4;
		$self->{errorString}='Not a MP3';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->{errorString});
		return undef;		
	}

	#makes sure the track is numeric
	if (
		defined($args{track}) &&
		($args{track} !~ /^[0123456789]*$/)
		) {
		$self->{error}=5;
		$self->{errorString}='Track is not numeric';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->{errorString});
		return undef;		
	}

	#makes sure the year is numeric
	if (
		defined($args{year}) &&
		($args{year} !~ /^[0123456789]*$/)
		) {
		$self->{error}=5;
		$self->{errorString}='Track is not numeric';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->{errorString});
		return undef;		
	}

	my $mp3=MP3::Tag->new($args{file});

	delete($args{file});

	$mp3->update_tags(\%args);

	return 1;
}

=head2 rename

This renames files. s/\//\\/g is used on all the tags to make sure
there are no directory issues.

One argument is taken and it is a hash ref.

The returned argument is a hash ref.

=head3 args hash ref

=head4 files

This is a array of files to rename.

=head4 template

This is the template to use for renaming a file.

The template keys are listed below.

    {$title}
    {$track}
    {$artist}
    {$album}
    {$comment}
    {$year}
    {$genre}

The default template is.

    {$artist} - {$album} ({$year}) - {$track} - {$title}.mp3

=head3 return hash ref

=head4 failed

This is a array of failed files.

=head4 padto

This pads a the track out to be this wide with zeros. By default is is 2.

To disable this, set it to 0.

=head4 success

This is true if it succeeds.

If it any thing failed, this is set to false.

    my $returned=$foo->rename(\%args);
    if ( $foo->error ||  ){

    }

=cut

sub rename{
	my $self=$_[0];
	my %args;
	if (defined($_[1])) {
		%args=%{$_[1]};
	}
	my $method='rename';

	#blanks any previous errors
	if (!$self->errorblank) {
		warn($self->{module}.' '.$method.': Unable to blank previous error');
		return undef;
	}

	if (!defined($args{padto})) {
		$args{padto}=2;
	}

	#makes sure some files are specified.
	if (!defined($args{files})) {
		$self->{error}=1;
		$self->{errorString}='No files specified';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->{errorString});
		return undef;
	}
	if (ref($args{files}) ne 'ARRAY') {
		$self->{error}=2;
		$self->{errorString}='The key files is not a array.';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->{errorString});
		return undef;		
	}
	if (!defined($args{files}[0])) {
		$self->{error}=1;
		$self->{errorString}='No files specified';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->{errorString});
		return undef;		
	}

	my $template='{$artist} - {$album} ({$year}) - {$track} - {$title}.mp3';
	if (defined($args{template})) {
		$template=$args{template};
	}

	#this will be returned
	my $toreturn={failed=>[], success=>1,};

	#declare it here so it does not have to be constantly recreated
	my $tobj = Text::NeatTemplate->new();


	my $int=0;
	while (defined( $args{files}[$int] )) {

		if (
			(! -r $args{files}[$int] ) ||
			( $args{files}[$int] !~ /\.[Mm][Pp]3$/ )
			) {
			$toreturn->{success}=0;
			push( @{ $self->{failed} }, $args{file}[$int] );
		}else {
			my $mp3=MP3::Tag->new( $args{files}[$int] );
			my ($title, $track, $artist, $album, $comment, $year, $genre) = $mp3->autoinfo();

			my $int2=length($track);
			while ($int2 < $args{padto}) {
				$track='0'.$track;

				$int2++;
			}

			$track=~s/\/.*//;
			$title=~s/\//\\/g;
			$album=~s/\//\\/g;
			$artist=~s/\//\\/g;
			$genre=~s/\//\\/g;
			$year=~s/\//\\/g;

			my %data=(
					  title=>$title,
					  track=>$track,
					  artist=>$artist,
					  album=>$album,
					  comment=>$comment,
					  year=>$year,
					  genre=>$genre,
					  );

			my $newfilename=$tobj->fill_in(
										   data_hash=>\%data,
										   template=>$template,
										   );

			rename($args{files}[$int], $newfilename);

		}

		$int++;
	}

	return $toreturn;
}

=head2 show

This returns a string containing a description of all the specified MP3s.

One argument is taken and it is a hash ref.

The returned argument is a hash ref.

=head3 args hash ref

=head4 files

This is a array of files to rename.

=head4 template

This is the template to use for renaming a file.

The template keys are listed below.

    {$file}
    {$title}
    {$track}
    {$artist}
    {$album}
    {$comment}
    {$year}
    {$genre}

The default template is.

    File: {$file}
    Artist: {$artist}
    Album: {$album}
    Year: {$year}
    Track: {$track}
    Title: {$title}

=head3 return hash ref

=head4 failed

This is a array of failed files.

=head4 padto

This pads a the track out to be this wide with zeros. By default is is 2.

To disable this, set it to 0.

=head4 success

This is true if it succeeds.

If it any thing failed, this is set to false.

    my $returned=$foo->rename(\%args);
    if ( $foo->error ||  ){

    }

=cut

sub show{
	my $self=$_[0];
	my %args;
	if (defined($_[1])) {
		%args=%{$_[1]};
	}
	my $method='rename';

	#blanks any previous errors
	if (!$self->errorblank) {
		warn($self->{module}.' '.$method.': Unable to blank previous error');
		return undef;
	}

	if (!defined($args{padto})) {
		$args{padto}=2;
	}

	#makes sure some files are specified.
	if (!defined($args{files})) {
		$self->{error}=1;
		$self->{errorString}='No files specified';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->{errorString});
		return undef;
	}
	if (ref($args{files}) ne 'ARRAY') {
		$self->{error}=2;
		$self->{errorString}='The key files is not a array.';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->{errorString});
		return undef;		
	}
	if (!defined($args{files}[0])) {
		$self->{error}=1;
		$self->{errorString}='No files specified';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->{errorString});
		return undef;		
	}

	my $template="File: {\$file}\n".
	             "Artist: {\$artist}\n".
	             "Album: {\$album}\n".
				 "Year: {\$year}\n".
				 "Track: {\$track}\n".
				 "Title: {\$title}\n\n";
	if (defined($args{template})) {
		$template=$args{template};
	}

	#this will be returned
	my $toreturn={failed=>[], success=>1, show=>''};

	#declare it here so it does not have to be constantly recreated
	my $tobj = Text::NeatTemplate->new();

	my $int=0;
	while (defined( $args{files}[$int] )) {

		if (
			(! -r $args{files}[$int] ) ||
			( $args{files}[$int] !~ /\.[Mm][Pp]3$/ )
			) {
			$toreturn->{success}=0;
			push( @{ $self->{failed} }, $args{file}[$int] );
		}else {
			my $mp3=MP3::Tag->new( $args{files}[$int] );
			my ($title, $track, $artist, $album, $comment, $year, $genre) = $mp3->autoinfo();

			my $int2=length($track);
			while ($int2 < $args{padto}) {
				$track='0'.$track;

				$int2++;
			}

			$track=~s/\/.*//;

			my %data=(
					  file=>$args{files}[$int],
					  title=>$title,
					  track=>$track,
					  artist=>$artist,
					  album=>$album,
					  comment=>$comment,
					  year=>$year,
					  genre=>$genre,
					  );

			$toreturn->{show}=$toreturn->{show}.$tobj->fill_in(
															   data_hash=>\%data,
															   template=>$template,
															   );
		}

		$int++;
	}

	return $toreturn;
}

=head1 ERROR RELATED METHODS

=head2 error

This returns the current error value.

This returns a integer or undefined, Perl boolean value, indicating if
a error is present or not and if it is which.

    if($foo->error){
        print "Error Code: ".$foo->error."\n";
    }

=cut

sub error{
        return $_[0]->{error};
}

=head2 errorString

This turns the current error string.

    if($foo->errorString ne ''){
        print "Error String: ".$foo->errorString."\n";
    }

=cut

sub errorString{
        return $_[0]->{errorString};
}

=head2 errorblank

This blanks a error, if a permanent error is not set.

This is a internal method and there is no good reason to call it.

=cut

sub errorblank{
        if ($_[0]->{perror}) {
                warn($_[0]->{module}.' errorblank: Unable to blank error. A permanent one is set');
                return undef;
        }

        $_[0]->{error}=undef;
        $_[0]->{errorString}='';

        return 1;
}

=head1 ERROR CODES

=head2 1

No files specified.

=head2 2

The files key does not contain a array.

=head2 3

No changes specified.

=head2 4

Does not appear to be a MP3.

=head2 5

Track is not numeric.

=head2 6

Year is not numeric.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mp3-tag-utils at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MP3-Tag-Utils>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MP3::Tag::Utils


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MP3-Tag-Utils>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MP3-Tag-Utils>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MP3-Tag-Utils>

=item * Search CPAN

L<http://search.cpan.org/dist/MP3-Tag-Utils/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Zane C. Bowers-Hadley.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of MP3::Tag::Utils
