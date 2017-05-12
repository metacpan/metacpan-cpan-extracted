use strict;

use Test::More tests => 5;

use FindBin;
use File::Spec;
use lib File::Spec->catfile($FindBin::Bin, 'lib');

use HTML::Truncate;

my $ht = HTML::Truncate->new();

my $html = join('', <DATA>);

{
    my $char_count = 50;
    $ht->chars($char_count);
    ok( $ht->chars() == $char_count, "Chars is reset to $char_count" );
    ok( my $trunc = $ht->truncate($html), "Truncating HTML" );

    is( $trunc, _with_pre(),
        "Truncation of <pre> version matches expectations" );

}

{
    # Swap tags, run otherwise same HTML through
    $html =~ s,(</?)pre,${1}p,g;
    ok( my $trunc = $ht->truncate($html), "Truncating HTML" );

    is( $trunc, _with_p(),
        "Truncation of <p> version matches expectations" );
}

sub _with_pre {
    return q{<div>

<pre>
   Some indentation <b>with <i>tags        inside</i></b>
   An&#8230;</pre></div>};
}

sub _with_p {
    return q{<div>

<p>
   Some indentation <b>with <i>tags        inside</i></b> And another line&#8230;</p></div>};
}

__DATA__
<div>

<pre>
   Some indentation <b>with <i>tags        inside</i></b>
   And another line
</pre>

</div>
