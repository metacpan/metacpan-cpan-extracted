# Tests related to RT25477 - https://rt.cpan.org/Public/Bug/Display.html?id=25477
use strict;
use warnings;
use File::Spec;
use Test::More;

use_ok('HTML::Scrubber');
use HTML::Scrubber;

my $scrubber = HTML::Scrubber->new;
$scrubber->default(1);
my $scrubbed = $scrubber->scrub( <<'END' );
<script src="www.google.com/script.js" />
<b>one</b>
<script type="text/javascript">
        alert("hello")
</script>
<b>two</b>
END

is( $scrubbed, <<'END', "correct result" );

<b>one</b>

<b>two</b>
END

done_testing;
