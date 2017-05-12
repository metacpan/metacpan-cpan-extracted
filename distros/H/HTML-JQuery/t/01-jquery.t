#!perl -T

use Test::More;

BEGIN {
    use_ok( 'HTML::JQuery' ) || print "Bail out!\n";
}

my $j = jquery sub {
    function 'init' => sub {
        alert 'Hello, World!';
    };
};

my $j2 = <<EOJ;
<script type="text/javascript">
\$(document).ready(function() {
if (typeof init == 'function') { init(); }
function init() {
alert("Hello, World!");
}
});
</script>

EOJ

is $j, $j2, 'Generated Javascript correctly';

done_testing;
