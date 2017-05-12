#!/usr/bin/perl

use strict;
use warnings;

use Roman;
use LWP::Simple;
use HTML::FormatText::WithLinks;

=head1 DESCRIPTION

This examples uses the custom number generation option to generate 
the footnote numbers as latin numerals. 

It also demonstrates how to place the footnote indicators after the 
link instead of in front which is the default.

=cut

my $html = get("http://exo.org.uk/");
my $f = HTML::FormatText::WithLinks->new(
    base                =>  "http://exo.org.uk/",
    unique_links        =>  1,
    link_num_generator  =>  \&generator,
    # fear my dodgy latin...
    before_link         => '',
    after_link          => '[%n]',
    footnote            => '%n est %l'
);

sub generator()
{
    my $num = shift;
    # Romans didn't get zero...
    $num += 1;
    return uc roman($num);
}

print $f->parse($html);

