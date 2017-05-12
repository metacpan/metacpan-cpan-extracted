package Image::Index::LaTeX;

use 5.008009;
use strict;
use warnings;
use File::Find qw(finddepth);
use Image::Size;

our $VERSION = '0.01';

sub new
{
	my ($class, @args) = @_;
	my $self = bless {}, $class;
	return $self->_init(@args);
}

sub _init
{
	my ($self, @dirs_or_files) = @_;
	
	# build list of image filenames
	$self->{'images'} = [
		grep {
			-f $_ && /\.(jpe?g|png|pdf|eps)$/i;
		}
		map {
			my @files = ();
			(-d $_ ?	
				finddepth(sub { push @files, $File::Find::name }, $_) : 
				do { push @files, $_ } );
			@files;
		}
		@dirs_or_files
	];
	
	$self->{'tmpl'} = {
		'latex' => q{
				\documentclass{article}
				
				\usepackage[margin=1cm]{geometry}
				\usepackage{graphicx}
				\usepackage{epstopdf}
				\geometry{screen}
				
				\begin{document}
				
				%[GRAPHICS]%
				
				\end{document}  
			},
			
		'context' => q{
				\starttext
				
				%[GRAPHICS]%
				
				\stoptext
			},		
	};
	
	return $self;
}

sub tex
{
	my ($self, %opts) = @_;

	my $flavour = lc($opts{'flavour'} || 'LaTeX');
	die "Error: supported flavours are: 'LaTeX' or 'ConTeXt'\n"
		if $flavour !~ /^(latex|context)$/;
	
	my $graphics = 
		join '',
		map {
			my $file = $_;
			my ($width, $height) = (0, 0);
			($width, $height) = imgsize($file) if $file =~ /\.(png|jpe?g)$/i;
			
			($flavour eq 'latex' ?
				'\includegraphics['.
					($width > $height ? 
						'width=\textwidth' :
						'height=\textheight').']{'.$file.'}'."\n".
				'\newpage'."\n"
					:
				'\useexternalfigure['.$file.']['.
					($width > $height ? 
						'width=\textwidth' :
						'height=\textheight').']'."\n"
			);
		}
		@{$self->{'images'}};

	my $tex = $self->{'tmpl'}->{$flavour};
	$tex =~ s/\%\[GRAPHICS\]\%/$graphics/;
	return $tex;
}

1;
__END__
=head1 NAME

Image::Index::LaTeX - Create an image index document using LaTeX

=head1 SYNOPSIS

  use Image::Index::LaTeX;
  my $generator = Image::Index::LaTeX->new("./mydir/");
  print $generator->tex(flavour => 'ConTeXt');

=head1 DESCRIPTION

Image::Index::LaTeX generates a TeX document that shows thumbnails of a set of
given images (or directories) to create a printable image index.

=head2 new( I<Directory-or-Filename>, ... )

This constructs an instance of Image::Index::LaTeX and returns it.
It takes as parameters one or more directory or filenames. The directories
are scanned for images and added to the list of images to create an index
of. The files are added to that list as well (if they are images).

This module currently allows only image types that are compatible with
pdflatex, namely JPG, PNG, PDF and EPS. 

=head2 tex( flavour => I<Flavourname> )

This creates a TeX document string from the list of images in a given
flavour. The document string is returned. 

These flavours exist:

=head3 flavour => "LaTeX" (Default)

This creates a LaTeX document string.

=head3 flavour => "ConTeXt"

This creates a ConTeXt document string.

=head2 EXPORT

None by default.

=head1 SEE ALSO

none.

=head1 AUTHOR

Tom Kirchner, E<lt>tom@tomkirchner.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Tom Kirchner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.


=cut
