#!/usr/bin/perl

use strict;
use warnings;

use LWP::Simple;
use HTML::FormatText::WithLinks;

=head1 DESCRIPTION

This script shows the basic usage of the module. 

The two options used are the base one to make sure that any relative links
in the page are turned into absolute links and unique_links which only
generates one footnote per link.

=cut

my $html = get("http://exo.org.uk/");
my $f = HTML::FormatText::WithLinks->new(
    base            =>  "http://exo.org.uk/",
    unique_links    =>  1    
);

print $f->parse($html);

