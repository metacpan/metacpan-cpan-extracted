use strict;
use warnings;

use Test::More tests => 1;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

$w->element( 'Textfield', 'foo[bar]' );

{
    my $query = HTMLWidget::TestLib->mock_query( { 'foo[bar]' => 'bam' } );

    my $f = $w->process($query);

    is( $f->param('foo[bar]'), 'bam', 'foo[bar] valid' );
}

