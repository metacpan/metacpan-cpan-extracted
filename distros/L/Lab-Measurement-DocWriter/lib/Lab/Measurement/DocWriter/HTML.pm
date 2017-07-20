package Lab::Measurement::DocWriter::HTML;
#ABSTRACT: HTML documentation output for Lab::Measurement
$Lab::Measurement::DocWriter::HTML::VERSION = '1.000';
use strict;
use parent 'Lab::Measurement::DocWriter';
use File::Basename;
use Syntax::Highlight::Engine::Simple::Perl;

sub new {
    my $self = shift->SUPER::new(@_);
    $self->{list_open} = 0;
    $self->{highlighter} = Syntax::Highlight::Engine::Simple::Perl->new();
    return $self;
}

sub start {
    my ($self, $title, $authors) = @_;
    open $self->{index_fh}, ">", "$$self{docdir}/index.html" or die $!;
    
    print {$self->{index_fh}} $self->_get_header($title);
    print {$self->{index_fh}} qq{
        <h1><a href="../index.html">Lab::Measurement</a> Documentation</h1>
        <p>$authors</p>
    };
}

sub start_section {
    my ($self, $level, $title) = @_;
    if ($self->{list_open}) {
        print {$self->{index_fh}} "</ul>\n";
        $self->{list_open} = 0;
    }
    print {$self->{index_fh}} "<h$level>$title</h$level>\n";
}

sub process_element {
    my ($self, $podfile, $params, @sections) = @_;
    # my $basename = fileparse($podfile,qr{\.(pod|pm)});

    my $basename = $podfile; 
    $basename =~ s!^.*lib/!!g ;
    $basename =~ s!\.(pod|pm)!!g ;
    $basename =~ s!^.*Measurement/scripts/!!g ;
    $basename =~ s!^examples/!!g ;
    $basename =~ s!/!-!g ;

    my $hascode = ($podfile =~ /\.(pl|pm)$/);
    print "pod $podfile base $basename\n";    

    my $bnt=$basename;
    $bnt =~ s!-!::!g ;

    # pod page
    my $parser = Lab::Measurement::DocWriter::HTML::MyPodXHTML->new();
    my $title = "$sections[0]: $bnt";
    my $html;
    $parser->output_string(\$html);
    $parser->parse_file($podfile);
    
    if ($parser->any_errata_seen ()) {
	    die "file '$podfile' has POD errors";
    }
    
    open OUTFILE, ">", "$$self{docdir}/$basename.html" or die;
        print OUTFILE $self->_get_header($title);
        print OUTFILE qq(<h1><a href="index.html">$sections[0]</a>: <span class="basename">$bnt</span></h1>\n);
        print OUTFILE $hascode ? qq{<p>(<a href="$basename\_source.html">Source code</a>)</p>} : "";
        print OUTFILE $html;
        print OUTFILE $self->_get_footer();
    close OUTFILE;
    
    # highlighted source file
    if ($hascode) {
        my $source = $self->{highlighter}->doFile(
            file      => $podfile,
            tab_width => 4,
        );
        my $title = "$sections[0]: $bnt";
        open SRCFILE, ">", "$$self{docdir}/$basename\_source.html" or die;
            print SRCFILE $self->_get_header($title);
            print SRCFILE qq(<h1><a href="index.html">$sections[0]</a>: <span class="basename">$bnt</span></h1>\n);
            print SRCFILE qq{<p>(<a href="$basename.html">Documentation</a>)</p>};
            print SRCFILE "<pre>$source</pre>\n";
            print SRCFILE $self->_get_footer();
        close SRCFILE;
    }
    
    # link in index page
    unless ($self->{list_open}) {
        print {$self->{index_fh}} "<ul>\n";
        $self->{list_open} = 1;
    }
    print {$self->{index_fh}} qq(<li><a class="index" href="$basename.html">$basename</a></li>\n);
}

sub finish {
    my $self = shift;
    if ($self->{list_open}) {
        print {$self->{index_fh}} "</ul>\n";
        $self->{list_open} = 0;
    }
    print {$self->{index_fh}} $self->_get_footer();
    close $self->{index_fh};
}

sub _get_header {
    my ($self, $title) = @_;
    return <<HEADER;
<?xml version="1.0" encoding="utf8" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=utf8">
        <link rel="stylesheet" type="text/css" href="../doku.css"/>
        <title>$title</title>
    </head>
    <body>
    <!--#include virtual="/defhead.html" -->
    <!--#include virtual="/docstoc.html" -->
HEADER
}

sub _get_footer {
    return <<FOOTER;
    </body>
</html>
FOOTER
}


package Lab::Measurement::DocWriter::HTML::MyPodXHTML;
$Lab::Measurement::DocWriter::HTML::MyPodXHTML::VERSION = '1.000';
use strict;
use parent 'Pod::Simple::XHTML';
#use HTML::Entities;

sub new {
    my $self = shift->SUPER::new();
    $self->html_header('');
    $self->html_footer('');
    $self->html_h_level(2);
    $self->complain_stderr (1);
    return $self;
}

sub resolve_pod_page_link {
    my ($self, $to, $section) = @_;
    return undef unless defined $to || defined $section;
    if ($to =~ /^Lab/) {
        my $tg=$to;
	$tg =~ s!::!-!g ;
        return "$tg.html";
    }
    if (defined $section) {
        $section = '#' . $self->idify($section, 1);
        return $section unless defined $to;
    }
    else {
        $section = ''
    }

    return ($self->perldoc_url_prefix || '')
        . HTML::Entities::encode_entities($to) . $section
        . ($self->perldoc_url_postfix || '');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Measurement::DocWriter::HTML - HTML documentation output for Lab::Measurement

=head1 VERSION

version 1.000

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by the Lab::Measurement team; in detail:

  Copyright 2010       Daniel Schroeer
            2011-2012  Andreas K. Huettel
            2013       Andreas K. Huettel, Christian Butschkow
            2016       Simon Reinhardt
            2017       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
