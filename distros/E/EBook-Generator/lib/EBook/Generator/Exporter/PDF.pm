package EBook::Generator::Exporter::PDF;

use 5.008009;
use strict;
use warnings;

use Data::Dumper;
use XML::LibXML;
use Image::Size;
use HTML::Entities;
use LaTeX::Encode;
use File::Temp;
use File::Copy;

use EBook::Generator::Parser;

our $VERSION = '0.01';

sub new
{
	my ($class, @args) = @_;
	my $self = bless {}, $class;
	return $self->init(@args);
}

sub init
{
	my ($self, $browser) = @_;

	$self->{'final-dir'} = '/tmp/';
	$self->{'browser'} = $browser;
	$self->{'log'} = [];

	$self->{'handlers'} = {
		# garamond shapes:
		#
		#  {\garamond normal}
		#  {\slshape This is garamond slanted} \\
    #  {\bfseries This is garamond bold face} \\
    #  {\scshape This is in small caps} \\
    #  {\slshape \bfseries This is slanted and bold face} \\

		'document' => sub {
			my ($self, $node) = @_;			
			my ($type, $opts, @subnodes) = @{$node};
			my $content = $self->transform_nodes(@subnodes);
			return
				'\title{'.$self->{'meta'}->{'title'}.' \footnote{'.$self->transform_text($self->{'meta'}->{'url'}).'}}'."\n".
				'\author{'.$self->{'meta'}->{'author'}.'}'."\n".
				'\date{'.$self->{'meta'}->{'date'}.'}'."\n".
				
				'\documentclass[12pt,a6paper]{article}'."\n".
				'\usepackage[left=5mm,right=5mm,top=5mm,bottom=5mm,nohead,includefoot]{geometry}'."\n".
				'\footnotesep=0mm'."\n".
				
				'\parskip=5mm'."\n".
				'\parindent=0mm'."\n".
				#'\sloppy'."\n".
				
				#'\renewcommand{\familydefault}{\sfdefault}'."\n".
				'\usepackage{garamond}'."\n".
				'\usepackage{lmodern}'."\n".
				'\usepackage{pslatex}'."\n".
				'\usepackage[T1]{fontenc}'."\n".
				
				# no margins in table of contents
				'\usepackage{tocloft}'."\n".
				'\renewcommand{\cftsecindent}{0em}'."\n".
				'\renewcommand{\cftsecnumwidth}{1.9em}'."\n".
				'\renewcommand{\cftsubsecindent}{1.9em}'."\n".
				'\renewcommand{\cftsubsecnumwidth}{2.8em}'."\n".
				'\renewcommand{\cftsubsubsecindent}{0em}'."\n".
				'\renewcommand{\cftsubsubsecnumwidth}{3.2em}'."\n".
		
				'\usepackage{graphicx}'."\n".
				
				'\usepackage{paralist}'."\n".
				'\setdefaultleftmargin{1.3em}{}{}{}{.5em}{.5em}'."\n".
				
				'\usepackage{listings}'."\n".
				'\lstset{numbers=left, numberstyle=\tiny, numbersep=5pt} \lstset{language=Perl}'."\n".
		
				'\begin{document}'."\n".
		
				'\garamond'."\n".
				'\maketitle'."\n".
				'\newpage'."\n".
		
				'\garamond'."\n".
				($self->{'has-section'} > 1 ?
					'\tableofcontents'."\n".
					'\newpage'."\n" : '').
		
				'\garamond'."\n".
				$content.
				'\end{document}'."\n";
		},
		'paragraph' => sub {
			my ($self, $node) = @_;			
			my ($type, $opts, @subnodes) = @{$node};
			return "\n\n".$self->transform_nodes(@subnodes)."\n\n";
		},
		'headline' => sub {
			my ($self, $node) = @_;			
			$self->{'has-section'} = 1;
			my ($type, $opts, @subnodes) = @{$node};
			my $name = 
				($opts->{'level'} == 1 ? 'section' :
					($opts->{'level'} == 2 ? 'subsection' :
						($opts->{'level'} == 3 ? 'subsubsection' :
							($opts->{'level'} == 4 ? 'paragraph' : 
								'subparagraph'))));
			return "\n\n".'\\'.$name.'{'.$self->transform_nodes(@subnodes)."}\n\n";
		},
		'text' => sub {
			my ($self, $node) = @_;
			my ($type, $opts, @subnodes) = @{$node};
			my $latex = $self->transform_nodes(@subnodes);
			$latex = ' {\footnotesize\lstinline|'.$latex.'|} '
				if exists $opts->{'preformatted'} && $opts->{'preformatted'} == 1;
			$latex = ' \textbf{'.$latex.'} '
				if exists $opts->{'weight'} && $opts->{'weight'} eq 'bold';
			$latex = ' \textit{'.$latex.'} '
				if exists $opts->{'style'} && $opts->{'style'} eq 'italic';
			return $latex;
		},
		'link' => sub {
			my ($self, $node) = @_;			
			my ($type, $opts, @subnodes) = @{$node};
			return
				' '.$self->transform_nodes(@subnodes).
				'\footnote{'.$self->transform_text($opts->{'target'})."}";
			
		},
		'media' => sub {
			my ($self, $node) = @_;			
			my ($type, $opts, @subnodes) = @{$node};
			if ($opts->{'type'} =~ /^(gif|jpe?g|png)$/i && -f $opts->{'filename'}) {
				# picture	
				return 
					"\n\n".
					'\includegraphics[width=\columnwidth,keepaspectratio=true]{'.
						$opts->{'filename'}."}".
					"\n\n";
			}
			return '';
		},
		'list' => sub {
			my ($self, $node) = @_;
			my ($type, $opts, @subnodes) = @{$node};
			my $name = ($opts->{'type'} eq 'ordered' ? 'enumerate' : 'itemize');
			return 
				"\n\n".'\begin{'.$name.'}'."\n".
				join('', map {'\item '.$self->transform_nodes($_)."\n\n"} @subnodes).
				'\end{'.$name.'}'."\n\n";
		},
		'preformatted' => sub {
			my ($self, $node) = @_;			
			my ($type, $opts, @subnodes) = @{$node};
			return 
				"\n\n".'{\footnotesize\begin{lstlisting}{Name}'.
				$self->transform_nodes(@subnodes).
				'\end{lstlisting}}'."\n\n";
		},
		'quote' => sub {
			my ($self, $node) = @_;			
			my ($type, $opts, @subnodes) = @{$node};
			return '\textit{'.$self->transform_nodes(@subnodes)."}";
		},
	};
	
	return $self;
}

sub writeEBook
{
	my ($self, $ebook, $options) = @_;

	$self->{'log'} = [];
	$self->{'url'} = $ebook->{'url'};
	$self->{'options'} = $options;

	# used while processing
	$self->{'has-section'} = 0;

	# convert to latex
	$self->{'meta'} = $ebook->{'meta'};
	my $converted = $self->transform_nodes($ebook->{'data'});
	
	my $tmpdir = File::Temp->newdir();

	# write tex file
	my $filename = $tmpdir->dirname()."/main.tex";
	unlink($filename) if -f $filename;
	my $fh = IO::File->new("> ".$filename);
	binmode($fh);
	print $fh $converted;
	
	# create pdf
	print "creating pdf...";

	my $cmd =
		# temporarily set path of local texmf tree to make
		# it able to find garamond files ;)
		'cd "'.$tmpdir->dirname().'"; '.
		"TEXMFHOME='".$self->{'options'}->{'local-tex-tree-path'}."' ".
		#EBook::Generator::Parser::getCommandPath('pdflatex').' '.
		(-f '/usr/bin/pdflatex' ? '/usr/bin/pdflatex' : '/usr/texbin/pdflatex ').' '.
		($ebook->{'options'}->{'debug'} == 1 ? () : '-interaction=batchmode').' '.
		'main.tex'.
		' 2>&1';
		#' > /dev/null 2>&1';
		
	my $output  = `$cmd`;
	   $output .= `$cmd` if $self->{'has-section'}; # second time for table-of-contents
		
	# copy pdf to final place
	my $pdf_filename   = $tmpdir->dirname().'/main.pdf';	
  my $final_filename = $self->{'final-dir'}.$ebook->{'meta'}->{'title'}.'.pdf';
	my $copy_result    = copy($pdf_filename, $final_filename);
	
	push @{$self->{'log'}},
		'dummy'
	#	'filename = '.$filename.' (exist: '.(-f $filename).')',
	#	'cmd = '.$cmd,
	#	'cmd-output = '.$output,
	#	'which-pdflatex = '.`which pdflatex`,
	#	'pdf-filename = '.$pdf_filename.' (exist: '.(-f $pdf_filename).')',
	#	'final-filename = '.$final_filename.' (exist: '.(-f $final_filename).')',
	#	'copy-result = '.$copy_result.' (error: '.$!.')',
		;
	
	return $final_filename;
}

sub transform_nodes
{
	my ($self, @nodes) = @_;	
	my $conv = '';
	foreach my $node (@nodes) {
		if (ref $node) {
			my $type = $node->[0];
			if (exists $self->{'handlers'}->{$type}) {
				$conv .= $self->{'handlers'}->{$type}->($self, $node);
			} else {
				my ($type, $opts, @subnodes) = @{$node};
				$conv .= $self->transform_nodes(@subnodes);
			}
		}
		else {
			$conv .= $self->transform_text($node);
		}
	}
	return $conv;
}

sub transform_text
{
	my ($self, $s) = @_;

	$s =~ s/([\.\;\?\!\:])/$1 /g;

	$s = decode_entities($s);
	$s = latex_encode($s);

	# make URLs shorter by adding split-marks
	#$s =~ s/\/(?!\/)/\\-\/\\-/g;
	
	return $s;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

EBook::Generator - Perl extension for creating EBooks from Websites.

=head1 SYNOPSIS

  use EBook::Generator;
  my $g = EBook::Generator->new();
  my $ebook = $g->readSource("http://www.google.com", fontSize => 12, grayImages => 1);
  $ebook->writeEBook("./Google.pdf");

=head1 DESCRIPTION

EBook::Generator can be used to generate a beautifully looking
e-book out of a website, aka HTML source. It uses LaTeX to
create the actual e-book.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Tom Kirchner, E<lt>kitomer@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Tom Kirchner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.


=cut
