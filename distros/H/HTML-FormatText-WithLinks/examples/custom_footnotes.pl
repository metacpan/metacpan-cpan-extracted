#!/usr/bin/perl

use strict;
use warnings;

use LWP::Simple;
use HTML::FormatText::WithLinks;

=head1 DESCRIPTION

This script demonstrates how to used a custom footnote for your
links.

In this case all the footnotes will now be of the form

footnote 10 is for http://exo.org.uk/code/

=cut

my $html = get("http://exo.org.uk/");
my $f = HTML::FormatText::WithLinks->new(
    base            =>  'http://exo.org.uk/',
    unique_links    =>  1,
    footnote        =>  'footnote %n is for %l'
);

print $f->parse($html);

