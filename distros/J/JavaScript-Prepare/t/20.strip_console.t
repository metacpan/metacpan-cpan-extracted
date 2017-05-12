use strict;
use warnings;

use Test::More tests => 2;
use JavaScript::Prepare;



{
    my $jsprep = JavaScript::Prepare->new();
    my $js = <<JS;
\$('#favourites ul + ul li.drag-target').each( function(i) {
    var thisimg = \$('img', this);
    console.log( thisimg.outerWidth() );
    thisimg.css('margin-left', lwidth - thisimg.outerWidth() );
});
JS
    my $minified = <<JSMIN;
\$('#favourites ul + ul li.drag-target').each(function(i){var thisimg=\$('img',this);console.log(thisimg.outerWidth());thisimg.css('margin-left',lwidth-thisimg.outerWidth());});
JSMIN
    
    my $min = $jsprep->process_string( $js );
    ok( $min eq $minified )
        or print $min;
}


{
    my $jsprep = JavaScript::Prepare->new( strip => 1 );
    my $js = <<JS;
\$('#favourites ul + ul li.drag-target').each( function(i) {
    var thisimg = \$('img', this);
    console.log( thisimg.outerWidth() );
    thisimg.css('margin-left', lwidth - thisimg.outerWidth() );
});
JS
    my $minified = <<JSMIN;
\$('#favourites ul + ul li.drag-target').each(function(i){var thisimg=\$('img',this);thisimg.css('margin-left',lwidth-thisimg.outerWidth());});
JSMIN

    my $min = $jsprep->process_string( $js );
    ok( $min eq $minified )
        or print $min;
}
