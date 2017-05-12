use strict;
use lib './lib';
use Devel::Diagram;

    my $diagram = new Devel::Diagram('HTML/');
    
    open UXF20, ">cd-HTML.xml";
    print UXF20 $diagram->Render('UXF20');
    warn $@ if $@;
    close UXF20;

    open HTML, ">cd-HTML.html";
    print HTML $diagram->Render('UXF20', 'xsl:uxf20toHtml');
    warn $@ if $@;
    close HTML;

