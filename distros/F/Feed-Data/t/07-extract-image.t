use strict;
use warnings;
use Test::More;
use HTML::LinkExtor;

my $p = HTML::LinkExtor->new;

$p->parse('<html><head></head><img src="something.png" /><img src="dontcare.png" /></html>');

my @links = $p->links;

my ($img, %attr);
foreach my $link (@links) {
    ($img, %attr) = @$link if $link->[0] eq 'img';
    last if $img;
}

is( $attr{src}, 'something.png' );

done_testing();

1;
