use strict;
use warnings;
use Test::More tests => 2;
use HTML::ReplacePictogramMobileJp;
use Encode;

my $x = HTML::ReplacePictogramMobileJp->replace(
    carrier  => 'V',
    charset  => 'utf8',
    html     => '&#xE001;',
    callback => sub {
        my ( $unicode, $carrier ) = @_;
        sprintf "<U+%X> $carrier", $unicode;
    }
);
is $x, "<U+E001> V", 'return value';
ok !Encode::is_utf8($x);

