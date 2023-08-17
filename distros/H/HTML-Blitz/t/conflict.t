use Test2::V0;
use HTML::Blitz ();

{
    my $blitz = HTML::Blitz->new(
        [ '.aa',   [ replace_inner_text => 'AA' ] ],
        [ '.b',    [ replace_inner_var  => 'b' ] ],
        [ '.b2',   [ replace_inner_var  => 'b2' ] ],
        [ '.aaaa', [ replace_inner_text => 'AAAA' ] ],
    );

    my $template = <<'_EOT_';
<p>x</p>
<p class="aa">x</p>
<p class="b">x</p>
<p class="aaaa">x</p>
<p class="aa b">x</p>
<p class="aa aaaa">x</p>
<p class="b aaaa">x</p>
<p class="aa b aaaa">x</p>
<p class="b aa b2">x</p>
_EOT_

    my $result = $blitz->apply_to_html('(test)', $template)->process({ b => 'B', b2 => 'drone' });

    is $result, <<'_EOT_';
<p>x</p>
<p class=aa>AA</p>
<p class=b>B</p>
<p class=aaaa>AAAA</p>
<p class="aa b">AA</p>
<p class="aa aaaa">AA</p>
<p class="b aaaa">AAAA</p>
<p class="aa b aaaa">AA</p>
<p class="b aa b2">AA</p>
_EOT_

    $result = $blitz->apply_to_html('(test)', '<p class="b b2">x</p>')->process({ b => 'B', b2 => 'drone' });

    is $result, in_set(
        '<p class="b b2">B</p>',
        '<p class="b b2">drone</p>',
    );
}

{
    my $blitz = HTML::Blitz->new(
        [ '.f', [ transform_inner_sub => sub { "f-$_[0]" } ],
                [ transform_inner_var => 'f' ] ],
        [ '.g', [ transform_inner_sub => sub { "$_[0]-g" } ],
                [ transform_inner_var => 'g' ] ],
    );

    my $template = <<'_EOT_';
<p>x</p>
<p class="f">case 1</p>
<p class="g">case 2</p>
<p class="f g">case 3</p>
<p class="g f">case 4</p>
_EOT_

    my $result = $blitz->apply_to_html('(test)', $template)->process({
        f => sub { uc $_[0] },
        g => sub { "<<$_[0]>>" },
    });

    is $result, <<'_EOT_';
<p>x</p>
<p class=f>F-CASE 1</p>
<p class=g>&lt;&lt;case 2-g>></p>
<p class="f g">&lt;&lt;F-CASE 3-G>></p>
<p class="g f">&lt;&lt;F-CASE 4-G>></p>
_EOT_
}

{
    my $t2 = HTML::Blitz->new(
        [ '.f', [ replace_inner_var => 't2x' ] ],
    )->apply_to_html('(t2)', '<span class=f>no</span>');

    my $blitz = HTML::Blitz->new(
        [ '.f', [ transform_inner_sub    => sub { "f($_[0])" } ] ],
        [ '.g', [ replace_inner_template => $t2 ] ],
        [ '.h', [ replace_inner_text     => 'fixed' ] ],
    );

    my $template = <<'_EOT_';
<p>x</p>
<p class=f>x</p>
<p class=g>y</p>
<p class="f g">both</p>
<p class="g f">also both</p>
<p class="f h"></p>
<p class="g h"></p>
<p class="f g h"></p>
_EOT_

    my $result = $blitz->apply_to_html('(test)', $template)->process({
        t2x => 'hi',
    });

    is $result, <<'_EOT_';
<p>x</p>
<p class=f>f(x)</p>
<p class=g><span class=f>hi</span></p>
<p class="f g"><span class=f>hi</span></p>
<p class="g f"><span class=f>hi</span></p>
<p class="f h">fixed</p>
<p class="g h">fixed</p>
<p class="f g h">fixed</p>
_EOT_
}

{
    my $blitz = HTML::Blitz->new(
        [ '.a', [ remove_attribute        => 'title' ] ],
        [ '.b', [ set_attribute_text      => 'title', 'vstatic' ] ],
        [ '.c', [ set_attribute_var       => 'title', 'v' ] ],
        [ '.d', [ transform_attribute_sub => 'title', sub { "d($_[0])" } ] ],
        [ '.e', [ transform_attribute_var => 'title', 'f' ] ],
    );

    my $template = <<'_EOT_';
<hr title=x>
<hr class=a title=x>
<hr class=b title=x>
<hr class=c title=x>
<hr class=d title=x>
<hr class=e title=x>
<hr class="a b" title=x>
<hr class="a c" title=x>
<hr class="a d" title=x>
<hr class="a e" title=x>
<hr class="b c" title=x>
<hr class="b c" title=x>
<hr class="b d" title=x>
<hr class="b e" title=x>
<hr class="c d" title=x>
<hr class="c e" title=x>
<hr class="a b c" title=x>
<hr class="a b d" title=x>
<hr class="a b e" title=x>
<hr class="b c d" title=x>
<hr class="b c e" title=x>
<hr class="c d e" title=x>
<hr class="a b c d" title=x>
<hr class="a b c e" title=x>
<hr class="b c d e" title=x>
<hr class="a b c d e" title=x>
_EOT_

    my $result = $blitz->apply_to_html('(test)', $template)->process({ v => 'vdynamic', f => sub { "e($_[0])" } });

    is $result, <<'_EOT_';
<hr title=x>
<hr class=a>
<hr class=b title=vstatic>
<hr class=c title="vdynamic">
<hr class=d title=d(x)>
<hr class=e title="e(x)">
<hr class="a b">
<hr class="a c">
<hr class="a d">
<hr class="a e">
<hr class="b c" title=vstatic>
<hr class="b c" title=vstatic>
<hr class="b d" title=vstatic>
<hr class="b e" title=vstatic>
<hr class="c d" title="vdynamic">
<hr class="c e" title="vdynamic">
<hr class="a b c">
<hr class="a b d">
<hr class="a b e">
<hr class="b c d" title=vstatic>
<hr class="b c e" title=vstatic>
<hr class="c d e" title="vdynamic">
<hr class="a b c d">
<hr class="a b c e">
<hr class="b c d e" title=vstatic>
<hr class="a b c d e">
_EOT_
}

{
    my $blitz = HTML::Blitz->new(
        [ '.a', [ replace_all_attributes => { foo => [text => 'a1'], bar => [text => 'a2'] } ] ],
        [ '.b', [ replace_all_attributes => { foo => [var => 'b'] } ] ],
        [ '.c', [ replace_all_attributes => { foo => [var => 'c'], bar => [text => 'c2'], baz => [text => 'c3'] } ] ],
        [ '.d', [ replace_all_attributes => { foo => [text => 'd1'], bar => [text => 'd2'], baz => [text => 'd3'], quux => [text => 'd4'] } ] ],
    );

    my $template = <<'_EOT_';
<hr class>
<hr class=a>
<hr class=b>
<hr class=c>
<hr class=d>
<hr class="a b">
<hr class="a c">
<hr class="a d">
<hr class="b c">
<hr class="b d">
<hr class="c d">
<hr class="a b c">
<hr class="a b d">
<hr class="b c d">
<hr class="a b c d">
_EOT_

    my $result = $blitz->apply_to_html('(test)', $template)->process({
        b => 'bx',
        c => 'cx',
    });

    is $result, <<'_EOT_';
<hr class>
<hr bar=a2 foo=a1>
<hr foo="bx">
<hr bar=c2 baz=c3 foo="cx">
<hr bar=d2 baz=d3 foo=d1 quux=d4>
<hr bar=a2 foo=a1>
<hr bar=a2 foo=a1>
<hr bar=a2 foo=a1>
<hr foo="bx">
<hr bar=d2 baz=d3 foo=d1 quux=d4>
<hr bar=d2 baz=d3 foo=d1 quux=d4>
<hr bar=a2 foo=a1>
<hr bar=a2 foo=a1>
<hr bar=d2 baz=d3 foo=d1 quux=d4>
<hr bar=a2 foo=a1>
_EOT_
}

done_testing;
