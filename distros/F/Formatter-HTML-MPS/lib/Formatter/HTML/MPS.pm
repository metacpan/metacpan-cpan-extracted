package Formatter::HTML::MPS;

=head1 NAME

    Formatter::HTML::MPS

=head1 DESCRIPTION

    This module converts MPS input to HTML. MPS is a simple format
    describing a presentation or a set of slides; it is a combination
    of the lightweight markup language Markdown and a separate markup
    language to configure this formatter.

    The slides are contained in a single HTML file, and should be
    shown as individual slides using CSS.

    It conforms with the Formatter API specification, version 0.95.

=head1 MPS FORMAT

    Each slide is formatted using the Markdown format. In addition to
    that, a simple format is used to set variables and to denote new
    slides.

    All MPS directives start with ';', and comments start with
    ';;'. Neither the MPS directives or comments will appear in the
    output.

    To indicate a new slide, use the 'newslide' directive. I.e., start
    the line with:

      ; newslide

    To set a configuration variable, use the 'set' directive. I.e.:

      ; set VAR = VALUE

    Currently, supported variables are:

      * output_format: only 'xhtml1.0_strict' is supported. Example:

        ; set output_format = xhtml1.0_strict

      * title: the title of the presentation.


=head1 SYNOPSIS

    use Formatter::HTML::MPS;
    my $formatter = Formatter::HTML::MPS->format( $mpsdata );

=head1 METHODS

=cut


use strict;
use warnings;

use Carp;
use Exporter;
use Formatter::HTML::MPS::OutputFormats;
use HTML::LinkExtor;
use Text::Markdown;
use vars qw( $VERSION @ISA @EXPORT );

@ISA = ('Exporter');
$VERSION = '0.4';
@EXPORT = ( 'generate' );





our $DEFAULT_OUTPUT_FORMAT = 'xhtml1.0_strict';

=head2 format ( mpsdata )

    Initialize the formatter. Returns an instance of this formatter
    for the specified input.

=cut
sub format {
    my ( $class, $mpsdata ) = @_;

    my $self = {};
    bless $self, $class;

    my %options = ();

    my $slidecount = 0; # Keep track of number of slides
    my $html = '';      # This will contain the generated HTML
    
    my @mps = split( "\n", $mpsdata );

    # Read each line individually
    while ( @mps ) {
        my $line = shift @mps;

        if ( $line =~ /^;/ ) {
            # Line is a comment or directive
            if ( $line =~ /^;\s*set (\w+)\s*=\s*(.+)/ ) {
                # Set an option:
                $options{$1} = $2;
            }
            elsif ( $line =~ /^;;/ ) {
                next;                
            }
            elsif ( $line =~ /^;\s*newslide/ ) {
                if ( ++$slidecount == 1 ) {
                    $html .= _header( \%options );
                }

                # Start a new slide
                $html .= _slidestart( \%options );

                
                # Read slide data from @mps, until we're out of data
                # or run into a new slide
                my @markdown_data = ();
                do {
                    $line = shift @mps;
                    push @markdown_data, $line."\n" unless $line =~ /^;/;
                }
                while ( @mps and $line !~ /^;\s*newslide/ );

                # Unshift the line, so the code will recognize the new slide in next
                # loop.

                unshift( @mps, $line ) if ( $line =~ /^;\s*newslide/ ); 

                # Pass the Markdown input to Text::Markdown and store
                # the resulting HTML
                my $m = Text::Markdown->new;
                $html .= $m->markdown( join( '', @markdown_data ) );

                # End this slide
                $html .= _slideend( \%options );
            }
        }
    }


    # A footer is usually needed, so let's append that as well.
    $html .= _footer( \%options );

    
    # Store misc. data in the object instance.
    $self->{options} = \%options;
    $self->{html} = $html;

    return $self;
}




=head2 document

    Returns the HTML formatting of the previously specified input.

=cut
sub document {
    my ( $self, $charset ) = @_;
    return $self->{html};
}




=head2 title

    Returns the title of the document.

=cut
sub title {
    my $self = shift;
    return $self->{options}->{title};
}




=head2 links
    
    Return the links in the document... At least that's what it should
    do when it's implemented.

=cut
sub links {
    my $self = shift;

    my @links = ();

    my $cb = sub {
        my($tag, %attr) = @_;
        return if $tag ne 'a';
        push @links, values %attr;
    };

    my $xtor = HTML::LinkExtor->new( $cb );
    $xtor->parse( $self->{html} );

    return @links;
}



=head2 fragment

=cut
sub fragment {
    my $self = shift;
    my ( $fragment ) = ( $self->{html} =~ /<body>(.*)<\/body>/s );
    return $fragment;
}


sub _header {
    # Return the right header for the specified output format. We only
    # support one output format for now... This code would perhaps
    # need some refactoring to support more formats.

    my $options = shift;
    my $output_format = $options->{output_format} || $DEFAULT_OUTPUT_FORMAT;

    my $header = '';
    if ( $output_format eq 'xhtml1.0_strict' ) {
        $header = $HEADERS{$output_format};

        # Insert title (if any):
        if ( exists $options->{title} ) {
            $header =~ s/\$title/$options->{title}/;
        }
        
        # Insert CSS, link or inline, default to link:
        if ( exists $options->{csstype} and $options->{csstype} eq 'inline' ) {
            my $css = $CSS{$output_format}->{inline};

            if ( defined $options->{cssfile} ) {
                # Slurp file and insert inline:
                open my $fh, '<', $options->{cssfile} or confess $!;
                my $cssdata = join( '', <$fh> );
                
                $css =~ s/\$content/$cssdata/;
            }
            else {
                #$css =~ s/\$content/$options->{css}/;
                confess "No CSS file specified. Please set CSS filename with '; set cssfile = <filename>'.";
            }
            
            $header =~ s/\$css/$css/;
        }
        elsif ( exists $options->{cssfile} ) {
            # Insert link to CSS file:
            my $css = $CSS{$output_format}->{link};
            $css =~ s/\$cssfile/$options->{cssfile}/;

            $header =~ s/\$css/$css/;
        }
        else {
            #$header =~ s/\$css/$CSS{$output_format}->{link}/;
            #confess "No CSS file specified, unable to continue.";
            
            # Insert default CSS, inline:
            my $css = $CSS{$output_format}->{inline};
            my $cssdata = join( '', <DATA> );
            $css =~ s/\$content/$cssdata/;

            $header =~ s/\$css/$css/;
        }

    }
    else {
        confess "no!";
    }

    my $title = ( defined $options->{title} ) ? $options->{title} : '';
    my $author = ( defined $options->{author} ) ? $options->{author} : '';

    $header .=<<END;
<div class="layout">
<div id="title"><span>$title</span></div>
<div id="author">$author</div>
<div id="bottomleft">&nbsp;</div>
<div id="bottomright">&nbsp;</div>
</div>
END

    return $header;
}


sub _footer {
    my $options = shift;
    my $output_format = $options->{output_format} || $DEFAULT_OUTPUT_FORMAT;

    if ( $output_format eq 'xhtml1.0_strict' ) {
        return $FOOTERS{$output_format};
    }
    else {
        confess "no!";
    }
}


sub _slidestart {
    return "<div class=\"slide\">\n";
}

sub _slideend {
    return "</div>\n";
}


=head1 BUGS

    Please let me know. :)

=head1 COPYRIGHT

Copyright 2006 Vetle Roeim <vetler@gmail.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;

__DATA__

/*
 * Formatter::HTML::MPS - Default CSS 
 *
 */
@media projection {

.screen {
	display:none;
	}

.slide {
	display: block; 
	padding:65px 200px 0px 24px;
	page-break-after: always;
        margin: 3em 3em 0em 3em;
	}

body    {
        background:white;
	padding:0;
	margin:0;
	font-family:'trebuchet ms',arial,sans-serif;
	font-size:150%;
	color:black;
	}

      .layout > div { line-height: 6em; font-size: 0.5em; font-weight: bold; color: white; }
      .layout #title { position: fixed; top: 0px; left: 0px; padding-left: 1em; width: 100%; background-color: #dd0000; display:block; }
      .layout #title span { font-size: 2em; }
      .layout #author { z-index:2; position: fixed; top: 0px; right: 0px; padding-right:1em; background-color: transparent; width: 50%; text-align: right; display:block; }
      .layout #bottomleft { position: fixed; bottom: 0px; left: 0px; padding-left:1em; width: 100%; background-color: #dd0000; display:block; }
      .layout #bottomright { z-index:2; position: fixed; bottom: 0px; right: 0px; padding-right:1em; background-color: transparent; width: 50%; text-align: right; display:block; }

a, a:visited, a:hover {
  color: white;
}

}
