package FreeDesktop::Icons;

=head1 NAME

FreeDesktop::Icons - Use icon libraries quick & easy

=cut


use strict;
use warnings;
use Carp;
use vars qw($VERSION);
$VERSION="0.02";
use Config;

my $mswin = 0;
$mswin = 1 if $Config{'osname'} eq 'MSWin32';

use File::Basename;

my @extensions = (
	'.jpg',
	'.jpeg',
	'.png',
	'.gif',
	'.xbm',
	'.xpm',
	'.svg',
);

my @defaulticonpath = ();
if ($mswin) {
	push @defaulticonpath, $ENV{ALLUSERSPROFILE} . '\Icons'
} else {
	my $local = $ENV{HOME} . '/.local/share/icons';
	push @defaulticonpath,  $local if -e $local;
	my $xdgpath = $ENV{XDG_DATA_DIRS};
	if (defined $xdgpath) {
		my @xdgdirs = split /\:/, $xdgpath;
		for (@xdgdirs) {
			push @defaulticonpath, "$_/icons";
		}
	}
}

=head1 SYNOPSIS

 my $iconlib = new FreeDeskTop::Icons;
 $iconlib->theme('Oxygen');
 $iconlib->size('16');
 my $imagefile = $iconlib->get('edit-copy');

=head1 DESCRIPTION

This module gives access to icon libraries on your system. It more
ore less conforms to the Free Desktop specifications here:
L<https://specifications.freedesktop.org/icon-theme-spec/icon-theme-spec-latest.html>

Furthermore it allows you to add your own icon folders through the B<rawpath> method.

We have made provisions to make it work on Windows as well.

The constructor takes a list of folders where it finds the icons
libraries. If you specify nothing, it will assign default values for:

Windows:  $ENV{ALLUSERSPROFILE} . '\Icons'. This package will not create 
the folder if it does not exist. See also the README.md included in this distribution.

Others: $ENV{HOME} . '/.local/share/icons',  and the folder 'icons' in $ENV{XDG_DATA_DIRS}.

=head1 METHODS

=over 4

=cut

sub new {
	my $class = shift;
	my $self = {	};
	bless $self, $class;

	$self->{CONTEXT} = undef;
	$self->{ICONSIZE} = undef;
	$self->{THEME} = undef;
	$self->{THEMEPOOL} = {};
	$self->{THEMES} = {};
	$self->{RAWPATH} = [];
	$self->{SIZE} = undef;

	my @iconpath = @_;
	@iconpath = @defaulticonpath unless @iconpath; 
	$self->CollectThemes(@iconpath);

	return $self;
}


=item B<availableContexts>I<($theme, >[ I<$name, $size> ] I<);>

Returns a list of available contexts. If you set $name to undef if will return
all contexts of size $size. If you set $size to undef it will return all
contexts associated with icon $name. If you set $name and $size to undef it
will return all known contexts in the theme. out $size it returns a list
of all contexts found in $theme.

=cut

sub availableContexts {
	my ($self, $theme, $name, $size) = @_;
	my $t = $self->getTheme($theme);
	my %found = ();
	if ((not defined $name) and (not defined $size)) {
		my @names = keys %$t;
		for (@names) {
			my $si = $t->{$_};
			my @sizes = keys %$si;
			for (@sizes) {
				my $ci = $si->{$_};
				for (keys %$ci) {
					$found{$_} = 1;
				}
			}
		}
	} elsif ((defined $name) and (not defined $size)) {
		if (exists $t->{$name}) {
			my $si = $t->{$name};
			my @sizes = keys %$si;
			for (@sizes) {
				my $ci = $si->{$_};
				for (keys %$ci) {
					$found{$_} = 1;
				}
			}
		}
	} elsif ((not defined $name) and (defined $size)) {
		my @names = keys %$t;
		for (@names) {
			if (exists $t->{$_}->{$size}) {
				my $ci = $t->{$_}->{$size};
				for (keys %$ci) {
					$found{$_} = 1;
				}
			}
		}
	} else {
		if (exists $t->{$name}) {
			my $si = $t->{$name};
			if (exists $si->{$size}) {
				my $ci = $si->{$size};
				%found = %$ci;
			}
		}
	}
	my $parent = $self->parentTheme($theme);
	if (defined $parent) {
		my @contexts = $self->availableContexts($parent, $name, $size);
		for (@contexts) {
			$found{$_} = 1
		}
	}
	return sort keys %found
}

=item B<availableIcons>I<($theme, >[ I<$size, $context> ] I<);>

Returns a list of available icons. If you set $size to undef the list will 
contain names it found in all sizes. If you set $context to undef it will return
names it found in all contexts. If you leave out both then
you get a list of all available icons. Watch out, it might be pretty long.

=cut

sub availableIcons {
	my ($self, $theme, $size, $context) = @_;
	my $t = $self->getTheme($theme);

	my @names = keys %$t;
	my %matches = ();
	if ((not defined $size) and (not defined $context)) {
		%matches = %$t
	} elsif ((defined $size) and (not defined $context)) {
		for (@names) {
			if (exists $t->{$_}->{$size}) { $matches{$_} = 1 }
		}
	} elsif ((not defined $size) and (defined $context)) {
		for (@names) {
			my $name = $_;
			my $si = $t->{$name};
			my @sizes = keys %$si;
			for (@sizes) {
				if (exists $t->{$name}->{$_}->{$context}) { $matches{$name} = 1 }
			}
		}
	} else {
		for (@names) {
			if (exists $t->{$_}->{$size}) {
				my $c = $t->{$_}->{$size};
				if (exists $c->{$context}) {
					 $matches{$_} = 1 
				}
			}
		}
	}
	my $parent = $self->parentTheme($theme);
	if (defined $parent) {
		my @icons = $self->availableIcons($parent, $size, $context);
		for (@icons) {
			 $matches{$_} = 1
		}
	}
	return sort keys %matches
}

=item B<availableThemes>

Returns a list of available themes it found while initiating the module.

=cut

sub availableThemes {
	my $self = shift;
	my $k = $self->{THEMES};
	return sort keys %$k
}


=item B<availableSizes>I<($theme, >[ I<$name, $context> ] I<);>

Returns a list of available contexts. If you leave out $size it returns a list
of all contexts found in $theme.

=cut

sub availableSizes {
	my ($self, $theme, $name, $context) = @_;
	my $t = $self->getTheme($theme);
	return () unless defined $t;

	my %found = ();
	if ((not defined $name) and (not defined $context)) {
		my @names = keys %$t;
		for (@names) {
			my $si = $t->{$_};
			my @sizes = keys %$si;
			for (@sizes) {
				$found{$_} = 1
			}
		}
	} elsif ((defined $name) and (not defined $context)) {
		if (exists $t->{$name}) {
			my $si = $t->{$name};
			%found = %$si;
		}
	} elsif ((not defined $name) and (defined $context)) {
		my @names = keys %$t;
		for (@names) {
			my $n = $_;
			my $si = $t->{$n};
			my @sizes = keys %$si;
			for (@sizes) {
				if (exists $t->{$n}->{$_}->{$context}) {
					$found{$_} = 1
				}
			}
		}
	} else {
		if (exists $t->{$name}) {
			my $si = $t->{$name};
			my @sizes = keys %$si;
			for (@sizes) {
				if (exists $t->{$name}->{$_}->{$context}) {
					$found{$_} = 1
				}
			}
		}
	}
	my $parent = $self->parentTheme($theme);
	if (defined $parent) {
		my @sizes = $self->availableSizes($parent, $name, $context);
		for (@sizes) {
			$found{$_} = 1
		}
	}
	delete $found{'unknown'};
	return sort {$a <=> $b} keys %found
}

sub AvailableSizesCurrentTheme {
	my $self = shift;
	return $self->availableSizes($self->theme);
}

sub CollectThemes {
	my $self = shift;
	my %themes = ();
	for (@_) {
		my $dir = $_;
		if (opendir DIR, $dir) {
			while (my $entry = readdir(DIR)) {
				my $fullname = "$dir/$entry";
				if (-d $fullname) {
					if (-e "$fullname/index.theme") {
						my $index = $self->LoadThemeFile($fullname);
						my $main = delete $index->{general};
						my $name = $main->{'Name'};
						if (%$index) {
							$themes{$name} = {
								path => $fullname,
								general => $main,
								folders => $index,
							}
						}
					}
				}
			}
			closedir DIR;
		}
	}
	$self->{THEMES} = \%themes
}

=item B<context>I<(?$context?)>

Set and return the preferred context to search in.

=cut

sub context {
	my $self = shift;
	$self->{CONTEXT} = shift if @_;
	return $self->{CONTEXT}
}

sub CreateIndex {
	my ($self, $tindex) = @_;
	my %index = ();
	my $base = $tindex->{path};
	my $folders = $tindex->{folders};
	foreach my $dir (keys %$folders) {
		my @raw = <"$base/$dir/*">;
		foreach my $file (@raw) {
			if ($self->IsImageFile($file)) {
				my ($name, $d, $e) = fileparse($file, @extensions);
				unless (exists $index{$name}) {
					$index{$name} = {}
				}
				my $size = $folders->{$dir}->{Size};
				unless (defined $size) {
					$size = 'unknown';
				}
				unless (exists $index{$name}->{$size}) {
					$index{$name}->{$size} = {}
				}
				my $context = $folders->{$dir}->{Context};
				unless (defined $context) {
					$context = 'unknown';
				}
				$index{$name}->{$size}->{$context} = $file;
			}
		}
	}
	return \%index;
}

sub FindImageC {
	my ($self, $si, $context) = @_;
	if (exists $si->{$context}) {
		return $si->{$context}
	} else {
		my @contexts = sort keys %$si;
		if (@contexts) {
			return $si->{$contexts[0]};
		}
	}
	return undef
}

sub FindImageS {
	my ($self, $nindex, $size, $context, $resize) = @_;
	if (exists $nindex->{$size}) {
		my $file = $self->FindImageC($nindex->{$size}, $context);
		if (defined $file) { return $file }
	} else {
		if (defined $resize) { 
			$$resize = 1;
			my @sizes = reverse sort keys %$nindex;
			for (@sizes) {
				my $si = $nindex->{$_};
				my $file = $self->FindImageC($si, $context);
				if (defined $file) { return $file }
			}
		}
	}
	return undef
}

sub FindLibImage {
	my ($self, $name, $size, $context, $resize, $theme) = @_;
	
	$size = $self->size unless (defined $size);
	$context = $self->context unless (defined $context);
	$context = 'unknown' unless defined $context;
	$theme = $self->theme unless defined $theme;
	unless (defined $size) {
		warn "you must specify a size";
		return undef
	}
	unless (defined $theme) {
		warn "you must specify a theme";
		return undef
	}

	my $index = $self->getTheme($theme);
	my $file;
	$file = $self->FindImageS($index->{$name}, $size, $context, $resize,) if exists $index->{$name};
	return $file if defined $file;

	my $parent = $self->parentTheme($theme);
	$file = $self->FindLibImage($name, $size, $context, $resize, $parent) if defined $parent;
	return $file if defined $file;

	return undef;
}

sub FindRawImage {
	my ($self, $name) = @_;
	my $path = $self->{RAWPATH};
	for (@$path) {
		my $folder = $_;
		opendir(DIR, $folder);
		my @files = grep(/!$name\.*/, readdir(DIR));
		closedir(DIR);
		for (@files) {
			my $file = "$folder/$_";
			return $file if $self->IsImage($file);
		}
	}
	return undef
}

=item B<get>I<($name, ?$size?, ?$context?, ?\$resize?)>

Returns the full filename of an image in the library. Finds the best suitable
version of the image in the library according to $size and $context. If you specify 
\$resize B<get> will attempt to return an icon of a different size if it cannot find
the requested size. If it eventually returns an image of another size, it sets $resize 
to 1. This gives the opportunity to scale the image to the requested icon size. 
All parameters except $name are optional.

=cut

sub get {
	my ($self, $name, $size, $context, $resize) = @_;
	my $img = $self->FindRawImage($name);
	return $img if defined $img;
	return $self->FindLibImage($name, $size, $context, $resize);
}

=item B<getFolders>I<($theme)>

Returns a reference to the folders hash defined in the theme.index of $theme.

=cut

sub getFolders {
	my ($self, $theme) = @_;
	carp "undefined theme" unless defined $theme;
	my $t = $self->{THEMES}->{$theme};
	if (defined $t) {
		return $t->{'folders'};
	} else {
		carp "theme '$theme' not found"
	}
}

=item B<getGeneral>I<($theme, ?$key?)>

Returns a reference to the folders hash defined in the theme.index of $theme.
If you specify $key it will return the value of that key in the hash.

=cut

sub getGeneral {
	my ($self, $theme, $key) = @_;
	carp "undefined theme" unless defined $theme;
	my $t = $self->{THEMES}->{$theme};
	if (defined $t) {
		if (defined $key) {
			return $t->{'general'}->{$key}
		} else {
			return $t->{'general'}
		}
	} else {
		carp "theme '$theme' not found"
	}
}

=item B<getPath>I<($theme)>

Returns the full path of the theme folder of $theme.

=cut

sub getPath {
	my ($self, $theme) = @_;
	carp "undefined theme" unless defined $theme;
	my $t = $self->{THEMES}->{$theme};
	if (defined $t) {
		return $t->{'path'}
	} else {
		carp "theme '$theme' not found"
	}
}

=item B<getTheme>I<($theme)>

Returns the theme data hash of I<$theme>.
Returns undef if I<$theme> is not found.

=cut

sub getTheme {
	my ($self, $name) = @_;
	my $pool = $self->{THEMEPOOL};
	if (exists $pool->{$name}) {
		return $pool->{$name}
	} else {
		my $themindex = $self->{THEMES}->{$name};
		if (defined $themindex) {
			my $index = $self->CreateIndex($themindex);
			$pool->{$name} = $index;
			return $index
		} else {
			return undef
		}
	}
}

sub IsImageFile {
	my ($self, $file) = @_;
	unless (-f $file) { return 0 } #It must be a file
	my ($d, $f, $e) = fileparse(lc($file), @extensions);
	if ($e ne '') { return 1 }
	return 0
}

sub LoadThemeFile {
	my ($self, $file) = @_;
	$file = "$file/index.theme";
	if (open(OFILE, "<", $file)) {
		my %index = ();
		my $section;
		my %inf = ();
		my $firstline = <OFILE>;
		unless ($firstline =~ /^\[.+\]$/) {
			warn "Illegal file format $file";
		} else {
			while (<OFILE>) {
				my $line = $_;
				chomp $line;
				if ($line =~ /^\[([^\]]+)\]/) { #new section
					if (defined $section) { 
						$index{$section} = { %inf }
					} else {
						$index{general} = { %inf }
					}
					$section = $1;
					%inf = ();
				} elsif ($line =~ s/^([^=]+)=//) { #new key
					$inf{$1} = $line;
				}
			}
			if (defined $section) { 
				$index{$section} = { %inf } 
			}
			close OFILE;
		}
		return \%index;
	} else {
		warn "Cannot open theme index file: $file"
	}
}

sub parentTheme {
	my ($self, $theme) = @_;
	return $self->{THEMES}->{$theme}->{'general'}->{'Inherits'};
}

=item B<rawpath>I<(?\@folders?)>

Sets and returns a reference to a list of folders where raw icons can
be found.

=cut

sub rawpath {
	my $self = shift;
	$self->{RAWPATH} = shift if @_;
	return $self->{RAWPATH}
}

=item B<size>I<(?$size?)>

Sets and returns the preferred size to search for.

=cut

sub size {
	my $self = shift;
	$self->{SIZE} = shift if @_;
	return $self->{SIZE}
}

=item B<themeExists>I<(?$theme?)>

returns a boolean.

=cut

sub themeExists {
	my ($self, $theme) = @_;
	return exists $self->{THEMES}->{$theme}
}

=item B<theme>I<(?$theme?)>

Sets and returns the theme to search in.

=cut

sub theme {
	my $self = shift;
	$self->{THEME} = shift if @_;
	return $self->{THEME}
}

=back

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS

Unknown. If you find any, please contact the author.

=cut

1;






