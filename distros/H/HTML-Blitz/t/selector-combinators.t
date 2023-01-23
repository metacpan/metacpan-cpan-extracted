use v5.14.0;
use warnings;
use Test::More;
use HTML::Blitz ();

my $html = <<'_EOT_';
<span>A1</span>
<div>
    <span>A2</span> <span>A3</span>
    <p>B1 <br> B2</p>
    <span>A4</span> <span>A5</span>
</div>
<div id=target>
    <span>A6</span>
    <div>
        <span>A7</span> <span>A8</span>
        <p>B3 <br> B4</p>
        <span>A9</span> <span>A10</span>
    </div>
</div>
<span>A11</span>
<div>
    <span>A12</span> <span>A13</span>
    <p>B5 <br> B6</p>
    <span>A14</span> <span>A15</span>
</div>
_EOT_

{
    my $blitz = HTML::Blitz->new([ '#target span' => [replace_inner_text => 'xyzzy'] ]);
    my $got = $blitz->apply_to_html('html~' . __LINE__, $html)->process;
    is $got, <<'_EOT_', 'descendant combinator';
<span>A1</span>
<div>
    <span>A2</span> <span>A3</span>
    <p>B1 <br> B2</p>
    <span>A4</span> <span>A5</span>
</div>
<div id=target>
    <span>xyzzy</span>
    <div>
        <span>xyzzy</span> <span>xyzzy</span>
        <p>B3 <br> B4</p>
        <span>xyzzy</span> <span>xyzzy</span>
    </div>
</div>
<span>A11</span>
<div>
    <span>A12</span> <span>A13</span>
    <p>B5 <br> B6</p>
    <span>A14</span> <span>A15</span>
</div>
_EOT_
}

{
    my $blitz = HTML::Blitz->new([ ':not(:first-of-type)' => [add_class => 'not-first'] ]);
    my $got = $blitz->apply_to_html('html~' . __LINE__, $html)->process;
    is $got, <<'_EOT_', 'not first of type';
<span>A1</span>
<div>
    <span>A2</span> <span class=not-first>A3</span>
    <p>B1 <br> B2</p>
    <span class=not-first>A4</span> <span class=not-first>A5</span>
</div>
<div class=not-first id=target>
    <span>A6</span>
    <div>
        <span>A7</span> <span class=not-first>A8</span>
        <p>B3 <br> B4</p>
        <span class=not-first>A9</span> <span class=not-first>A10</span>
    </div>
</div>
<span class=not-first>A11</span>
<div class=not-first>
    <span>A12</span> <span class=not-first>A13</span>
    <p>B5 <br> B6</p>
    <span class=not-first>A14</span> <span class=not-first>A15</span>
</div>
_EOT_

    $blitz->add_rules([ '#target span' => [replace_inner_text => 'xyzzy'] ]);
    $got = $blitz->apply_to_html('html~' . __LINE__, $html)->process;
    is $got, <<'_EOT_', 'descendant combinator & not first of type';
<span>A1</span>
<div>
    <span>A2</span> <span class=not-first>A3</span>
    <p>B1 <br> B2</p>
    <span class=not-first>A4</span> <span class=not-first>A5</span>
</div>
<div class=not-first id=target>
    <span>xyzzy</span>
    <div>
        <span>xyzzy</span> <span class=not-first>xyzzy</span>
        <p>B3 <br> B4</p>
        <span class=not-first>xyzzy</span> <span class=not-first>xyzzy</span>
    </div>
</div>
<span class=not-first>A11</span>
<div class=not-first>
    <span>A12</span> <span class=not-first>A13</span>
    <p>B5 <br> B6</p>
    <span class=not-first>A14</span> <span class=not-first>A15</span>
</div>
_EOT_
}

{
    my $blitz = HTML::Blitz->new(
        [ '#target ~ div > :not(:first-child)' => [replace_inner_text => 'xyzzy'] ],
        [ 'div + *'                            => [add_class => 'post-div'] ],
        [ '*>*>*'                              => [set_attribute_text => '3deep-child', ''] ],
        [ '* * *'                              => [set_attribute_text => '3deep-desc', ''] ],
    );
    my $got = $blitz->apply_to_html('html~' . __LINE__, $html)->process;
    is $got, <<'_EOT_', 'wild party';
<span>A1</span>
<div>
    <span>A2</span> <span>A3</span>
    <p>B1 <br 3deep-child 3deep-desc> B2</p>
    <span>A4</span> <span>A5</span>
</div>
<div class=post-div id=target>
    <span>A6</span>
    <div>
        <span 3deep-child 3deep-desc>A7</span> <span 3deep-child 3deep-desc>A8</span>
        <p 3deep-child 3deep-desc>B3 <br 3deep-child 3deep-desc> B4</p>
        <span 3deep-child 3deep-desc>A9</span> <span 3deep-child 3deep-desc>A10</span>
    </div>
</div>
<span class=post-div>A11</span>
<div>
    <span>A12</span> <span>xyzzy</span>
    <p>xyzzy</p>
    <span>xyzzy</span> <span>xyzzy</span>
</div>
_EOT_
}

{
    my $html = '<ul> <li>hi</li> </ul>';

    for my $selector (
        "ul li",
        "ul\tli",
        "ul \tli",
        "ul\t li",
    ) {
        my $blitz = HTML::Blitz->new([ $selector => [replace_inner_text => 'xyzzy'] ]);
        my $got = $blitz->apply_to_html('html~' . __LINE__, $html)->process;
        is $got, "<ul> <li>xyzzy</li> </ul>", 'selector "' . $selector =~ s/\t/\\t/r . '" matches';
    }
}

{
    my $html = '<div> ' x 100 . '</div> ' x 100;

    {
        my $blitz = HTML::Blitz->new([ '#no-such-thing' . ' *' x 10 => [replace_inner_text => 'xyzzy'] ]);
        my $got = $blitz->apply_to_html('html~' . __LINE__, $html)->process;
        is $got, $html, 'non-existent element has no descendants';
    }

    {
        my $blitz = HTML::Blitz->new([ '* ' x 10 . '#no-such-thing' => [replace_inner_text => 'xyzzy'] ]);
        my $got = $blitz->apply_to_html('html~' . __LINE__, $html)->process;
        is $got, $html, 'non-existent element has no ancestors';
    }
}

done_testing;
