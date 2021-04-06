#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use HTML::Make::Page 'make_page';
binmode STDOUT, ":encoding(utf8)";
my $jstext = <<EOF;
function love() {
    alert ("💕 I love you baby 🥰");
}
EOF
my ($h, $b) = make_page (js => [{text => $jstext}], title => '💌');
$b->add_attr (onload => 'love ();');
print $h->text ();
