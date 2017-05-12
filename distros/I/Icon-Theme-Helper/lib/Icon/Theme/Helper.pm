package Icon::Theme::Helper;

use warnings;
use strict;
use Icon::Theme::Index::Parse;

=head1 NAME

Icon::Theme::Helper - Helps locating icon files.

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';


=head1 SYNOPSIS

    use Icon::Theme::Helper;

    my $iconhelper = Icon::Theme::Helper->new();

=head1 METHODS

=head2 new

This initializes the object.

=head3 args hash ref

=head4 alwaysIncludeHicolor

Always include the hicolor theme.

This defaults to '1'.

=head4 alwaysIncludeGnome

Always include the gnome theme.

This defaults to '1'.

=head4 dir

This is the icon dir to use.

If this is not defined, the first directory
found below will be used.

    /usr/local/share/icons
    /usr/share/icons

=head4 maxSize

This is the maximum size to use.

If undefined, there is no upper
size limit.

=head4 minSize

This is the minimum size to use.

If undefined, there is no lower
size limit.

=head4 scalable

Wether or not to use scalable icons.

If not defined, this defaults to 1.

=head4 size

This is the prefered size to use.

If this is not defined, '32' is used.

=head4 skip

A list of inherited themes to skip.

=head4 theme

This is the icon theme to use.

If none is specified, 'hicolor' is used.

=cut

sub new{
	my %args;
	if (defined( $_[1] )) {
		%args=%{$_[1]};
	}
	my $method='new';

	my $self={error=>undef, perror=>undef, errorString=>'', module=>'Icon-Theme-Helper'};
	bless $self;

	#try to automatically detect the directory to use if none is specified
	if (!defined( $args{dir} )) {
		if (-d '/usr/local/share/icons/') {
			$self->{dir}='/usr/local/share/icons/';
		}else {
			if (-d '/usr/share/icons/') {
				$self->{dir}='/usr/share/icons/';
			}
		}

		#error if no directory can be found
		if (!defined( $self->{dir} )) {
			$self->{error}=1;
			$self->{perror}=1;
			$self->{errorString}='No directory specified and one could not be automatically located';
			warn($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
			return $self;
		}

	}else {
		$self->{dir}=$args{dir};

		#error if the specified directory can not be found
		if (!defined( $self->{dir} )) {
			$self->{error}=2;
			$self->{perror}=1;
			$self->{errorString}='The specified directory, "'.$self->{dir}.'", does not exist';
			warn($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
			return $self;
		}
	}


	#get the theme to use
	if (!defined( $args{theme} )) {
		$self->{theme}='hicolor';
	}else {
		$self->{theme}=$args{theme};
	}

	if (! -d $self->{dir}.'/'.$self->{theme} ) {
			$self->{error}=3;
			$self->{perror}=1;
			$self->{errorString}='The specified directory, "'.$self->{dir}.'", does not exist';
			warn($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
			return $self;
	}

	if (! -f $self->{dir}.'/'.$self->{theme}.'/index.theme' ) {
			$self->{error}=4;
			$self->{perror}=1;
			$self->{errorString}='The specified theme, "'.$self->{theme}.'", is not a Freedesktop.org compliant icon theme';
			warn($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
			return $self;
	}

	#holds the required themes
	$self->{themes}={};

	#read the default theme
	$self->{themes}{$self->{theme}}=Icon::Theme::Index::Parse->new_from_file($self->{dir}.'/'.$self->{theme}.'/index.theme');
	if ($self->{themes}{$self->{theme}}->{error}) {
			$self->{error}=5;
			$self->{perror}=1;
			$self->{errorString}='Failed to load the index for the theme "'.$self->{theme}.'"';
			warn($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
			return $self;
	}

	#gets the themes it inherits
	my @inherits=$self->{themes}{$self->{theme}}->inherits;

	#skips over any thing it is told to be skipped

	#builds a order array of themes to check
	my @themeOrder=( $self->{theme} );
	push(@themeOrder, @inherits);

	#this holds a list of items that have been processed
	my %processed;
	$processed{$self->{theme}}=1; #adds the starting theme to the list to avoid it

	#processes each one...
	my $int=1; #we start at 1 as the first item in the themeOrder list is the theme that was used
	while (defined( $themeOrder[$int] )) {
		my $theme=$themeOrder[$int];

		#only process it if we have now already
		if (!defined( $processed{$theme} )) {
			#only parse it if the index file exists
			my $index=$self->{dir}.'/'.$theme.'/index.theme';
			if (-f $index) {
				my $parsedTheme=Icon::Theme::Index::Parse->new_from_file($index);
				#process this theme if it did not error
				if (! $parsedTheme->{error} ) {
					$self->{themes}{$theme}=$parsedTheme;
					#
					push(@themeOrder, $theme);
					#push the inherited stuff onto this stack
					@inherits=$self->{themes}{$theme}->inherits;
					push(@themeOrder, @inherits);
					
					#mark as processed so it is not done again
					$processed{$theme}=1
				}
			}
		}

		$int++;
	}

	#include hicolor if needed
	if (!defined( $args{alwaysIncludeHicolor} )) {
		$args{alwaysIncludeHicolor}=1;
	}
	if ($args{alwaysIncludeHicolor}) {
		#only proceed if it has not been processed already
		if (!defined( $processed{'hicolor'} )) {
			#only proceed if the index file exists
			if (-f $self->{dir}.'/hicolor/index.theme' ) {
				my $parsedTheme=Icon::Theme::Index::Parse->new_from_file( $self->{dir}.'/hicolor/index.theme' );
				#only add it if there was no error
				if (! $parsedTheme->{error} ) {
					$self->{themes}{'hicolor'}=$parsedTheme;
					#push this theme into the order
					push(@themeOrder, 'hicolor');
					#push the inherited stuff onto this stack
					@inherits=$self->{themes}{'hicolor'}->inherits;
					push(@themeOrder, @inherits);
					
					#mark as processed so it is not done again
					$processed{'hicolor'}=1
				}
			}
		}
	}

	#include gnome if needed
	if (!defined( $args{alwaysIncludeGnome} )) {
		$args{alwaysIncludeGnome}=1;
	}
	if ($args{alwaysIncludeGnome}) {
		#only proceed if it has not been processed already
		if (!defined( $processed{'gnome'} )) {
			#only proceed if the index file exists
			if (-f $self->{dir}.'/gnome/index.theme' ) {
				my $parsedTheme=Icon::Theme::Index::Parse->new_from_file( $self->{dir}.'/gnome/index.theme' );
				#only add it if there was no error
				if (! $parsedTheme->{error} ) {
					$self->{themes}{'gnome'}=$parsedTheme;
					#push this theme into the order
					push(@themeOrder, 'gnome');
					#push the inherited stuff onto this stack
					@inherits=$self->{themes}{'gnome'}->inherits;
					push(@themeOrder, @inherits);
					
					#mark as processed so it is not done again
					$processed{'gnome'}=1
				}
			}
		}
	}
	
	#cleans the order list of redundant items
	my @cleanThemeOrder;
	my %cleanedThemes; #used for check if a theme has been cleaned or not
	$int=0;
	while ( defined( $themeOrder[$int] ) ) {
		my $theme=$themeOrder[$int];

		if (!defined( $cleanedThemes{ $theme } )) {
			push(@cleanThemeOrder, $theme);
			$cleanedThemes{$theme}=1;
		}

		$int++;
	}

	#saves the theme order
	$self->{order}=\@cleanThemeOrder;

	#saves the min, max, preferred size, and scalable boolean
	if (defined( $args{minsize} )) {
		$self->{minSize}=$args{minsize};
	}
	if (defined( $args{maxSize} )) {
		$self->{maxSize}=$args{maxSize};
	}
	if (defined( $args{size} )) {
		$self->{size}=$args{size};
	}else {
		$self->{size}='32';
	}
	if (defined($args{scalable} )) {
		$self->{scalable}=$args{scalable};
	}else {
		$self->{scalable}='1';
	}

	return $self;
}

=head2 getIcon

This returns the icon file.

The first arguement is the context and the second is the icon name.

    my $iconFile=$iconhelper->getIcon('Places', 'desktop');

=cut

sub getIcon{
	my $self=$_[0];
	my $context=$_[1];
	my $name=$_[2];
	my $method='getIcon';

	#blanks any previous errors
	$self->errorblank;
	if ($self->{error}) {
		return undef;
	}

	#error if there is no context specified
	if (!defined( $context )) {
			$self->{error}=6;
			$self->{errorString}='No context defined';
			warn($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
			return $self;
	}

	#error if there is no name specified
	if (!defined( $name )) {
			$self->{error}=7;
			$self->{errorString}='No icon name defined';
			warn($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
			return $self;
	}

	#process each theme till we find a int
	my $themeInt=0;
	while (defined( $self->{order}[$themeInt] )) {
		my $theme=$self->{order}[$themeInt];

		#check each directory
		my $dirInt=0;
		if (defined( $self->{themes}{$theme} )) {
			my @dirs=$self->{themes}{$theme}->directories;
			if (!$self->{themes}{$theme}->{error}) {
				while (defined( $dirs[$dirInt] )) {
					my $dircontext=$self->{themes}{$theme}->dirContext( $dirs[$dirInt] );
					if (defined($dircontext) && ($context eq $dircontext)) {
						my $check=1; #default if true;
						
						my $size=$self->{themes}{$theme}->dirSize( $dirs[$dirInt] );
						
						#checks if it needs to check minSize
						if (defined($self->{minSize}) && defined($size)) {
							#don't check this directory if the size is to small
							if ( $self->{minSize} > $size ) {
								$check=0;
							}
						}
						
						#checks if it needs to check maxSize
						if (defined($self->{maxSize}) && defined($size) && $check ) {
							#don't check this directory if the size is to large
							if ( $self->{maxSize} < $size ) {
								$check=0;
							}
						}
						
						#don't check the directory depending on the scalable preference
						if (!$self->{scalable}) {
							$check=0;
						}
						
						#check if the specified icon exists or not
						if ($check) {
							my $basename=$self->{dir}."/".$theme.'/'.$dirs[$dirInt].'/'.$name.'.';
							
							#checks for a svg if scalable
							if ($self->{scalable}) {
								if (-f $basename.'svg') {
									return $basename.'svg'
								}
							}
							
							#checks for a potential xpm icon
							if (-f $basename.'xpm') {
								return $basename.'xpm'
							}
							
							#checks for a potential png icon
							if (-f $basename.'png') {
								return $basename.'png'
							}
						}
					}
				
				
					$dirInt++;
				}
			}
		}

		$themeInt++;
	}

	#not found
	return undef;
}

=head2 getMimeTypeIcon

This searches and feches a MIME type icon.

One arguement is taken and it is the MIME type.

    $iconFile=$iconhelper->getMimeTypeIcon('application/pdf');

=cut

sub getMimeTypeIcon{
	my $self=$_[0];
	my $mimetype=$_[1];
	my $method='getMimeTypeIcon';

	#blanks any previous errors
	$self->errorblank;
	if ($self->{error}) {
		return undef;
	}

	if (!defined($mimetype)) {
			$self->{error}=8;
			$self->{errorString}='No MIME type defined';
			warn($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
			return $self;
	}

	#replace the / in the mimetype with a -
	$mimetype=~s/\//\-/;

	#declare it here for simplicity
	my $icon;

	#try a regular mime type
	$icon=$self->getIcon('MimeTypes', $mimetype);
	if (defined($icon)) {
		return $icon;
	}

	#sees if there is a gnome mimetype
	$icon=$self->getIcon('MimeTypes', 'gnome-mime-'.$mimetype);
	if (defined($icon)) {
		return $icon;
	}

	#if it has spreadsheet in it, check for a regular spreadsheet
	if ($mimetype =~ /spreadsheet/) {
		$icon=$self->getIcon('MimeType', 'spreadsheet');
		if (defined($icon)) {
			return $icon;
		}
	}

	#if it has document in it, check for a regular document
	if ($mimetype =~ /document/) {
		$icon=$self->getIcon('MimeTypes', 'document');
		if (defined($icon)) {
			return $icon;
		}
	}
	if ($mimetype =~ /document/) {
		$icon=$self->getIcon('MimeTypes', 'x-office-document');
		if (defined($icon)) {
			return $icon;
		}
	}	

	#tries to find a icon for a zip file
	if ($mimetype =~ /zip/) {
		$icon=$self->getIcon('MimeTypes', 'zip');
		if (defined($icon)) {
			return $icon;
		}
	}

	#tries a generic one if it is a tar ball
	if ($mimetype =~ /tar/) {
		$icon=$self->getIcon('MimeTypes', 'tar');
		if (defined($icon)) {
			return $icon;
		}
	}

	#tries a generic one if it is video
	if ($mimetype =~ /video/) {
		$icon=$self->getIcon('MimeTypes', 'video');
		if (defined($icon)) {
			return $icon;
		}
	}

	#tries a generic one if it is a html file
	if ($mimetype =~ /html/) {
		$icon=$self->getIcon('MimeTypes', 'text-html');
		if (defined($icon)) {
			return $icon;
		}
	}
	if ($mimetype =~ /html/) {
		$icon=$self->getIcon('MimeTypes', 'html');
		if (defined($icon)) {
			return $icon;
		}
	}

	#tries a generic one for a template
	if ($mimetype =~ /template/) {
		$icon=$self->getIcon('MimeTypes', 'text-x-generic-template');
		if (defined($icon)) {
			return $icon;
		}
	}

	#tries a generic one for a addressbook
	if ($mimetype =~ /addressbook/) {
		$icon=$self->getIcon('MimeTypes', 'stock_addressbook');
		if (defined($icon)) {
			return $icon;
		}
	}
	if ($mimetype =~ /addressbook/) {
		$icon=$self->getIcon('MimeTypes', 'addressbook');
		if (defined($icon)) {
			return $icon;
		}
	}
	if ($mimetype =~ /addressbook/) {
		$icon=$self->getIcon('MimeTypes', 'x-office-address-book');
		if (defined($icon)) {
			return $icon;
		}
	}

	#checks it for a calendar
	if ($mimetype =~ /calendar/) {
		$icon=$self->getIcon('MimeTypes', 'calendar');
		if (defined($icon)) {
			return $icon;
		}
	}
	if ($mimetype =~ /calendar/) {
		$icon=$self->getIcon('MimeTypes', 'stock_calendar');
		if (defined($icon)) {
			return $icon;
		}
	}
	if ($mimetype =~ /calendar/) {
		$icon=$self->getIcon('MimeTypes', 'x-office-calendar');
		if (defined($icon)) {
			return $icon;
		}
	}

	#try it for images
	if ($mimetype =~ /image/) {
		$icon=$self->getIcon('MimeTypes', 'image');
		if (defined($icon)) {
			return $icon;
		}
	}
	if ($mimetype =~ /image/) {
		$icon=$self->getIcon('MimeTypes', 'image-x-generic');
		if (defined($icon)) {
			return $icon;
		}
	}

	#gets it for a RPM
	if ($mimetype =~ /rpm$/) {
		$icon=$self->getIcon('MimeTypes', 'rpm');
		if (defined($icon)) {
			return $icon;
		}
	}

	#tries a generic one for a text file
	if ($mimetype =~ /text/) {
		$icon=$self->getIcon('MimeTypes', 'txt');
		if (defined($icon)) {
			return $icon;
		}
	}

   	#try unknown before finally returning undef
	$icon=$self->getIcon('MimeTypes', 'unknown');
	if (defined($icon)) {
		return $icon;
	}

	#if we get here we did not find one
	return undef;
}

=head1 ERROR METHODS

=head2 error

This fetches any current errors.

A return of undef, false, indicates no error is present.

    if($iconhelper->error){
        warn("Error!");
    }

=cut

sub error{
	return $_[0]->{error};
}

=head2 errorblank

This blanks any previous error.

This is a internal function.

=cut

sub errorblank{
	my $self=$_[0];

	if ($self->{perror}) {
		warn($self->{module}.' errorblank: A permanent error is set');
	}

	$self->{error}=undef;
	$self->{errorString}=undef;

	return 1;
}


=head1 ERROR CODES

=head2 1

No directory specified and one could not be automatically located.

=head2 2

The specified directory does not exist.

=head2 3

The specified theme does not exist.

=head2 4

The theme is not a Freedesktop.org compliant theme.

=head2 5

Parsing the index for the specified config failed.

=head2 6

No context specified.

=head2 7

No icon name specified.

=head2 8

No MIME type specified.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-icon-theme-helper at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Icon-Theme-Helper>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Icon::Theme::Helper


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Icon-Theme-Helper>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Icon-Theme-Helper>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Icon-Theme-Helper>

=item * Search CPAN

L<http://search.cpan.org/dist/Icon-Theme-Helper/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Icon::Theme::Helper
