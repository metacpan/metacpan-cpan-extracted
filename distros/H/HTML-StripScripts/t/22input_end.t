
use strict;
use Test::More tests => 7;

BEGIN { $^W = 1 }

use HTML::StripScripts;
my $f = HTML::StripScripts->new;

mytest( '',      '<!--filtered--></i>', 'reject null' );
mytest( '</>',   '<!--filtered--></i>', 'reject empty' );
mytest( '</->',  '<!--filtered--></i>', 'reject malformed' );
mytest( '</foo>','<!--filtered--></i>', 'reject unknown' );
mytest( '</b>',  '<!--filtered--></i>', 'reject misplaced' );
mytest( '</i>',  '</i>',                'accept valid' );
mytest( '</I>',  '</i>',                'accept uppercase' );

sub mytest {
    my ($in, $out, $name) = @_;

    $f->input_start_document;
    $f->input_start('<i>');
    $f->input_text('foo');
    $f->input_end($in);
    $f->input_end_document;
    is( $f->filtered_document, "<i>foo$out", "input_end $name" );
}

