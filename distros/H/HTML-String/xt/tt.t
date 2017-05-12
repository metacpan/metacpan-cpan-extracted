use strictures 1;
use Test::More;
use HTML::String::TT;

my $tt = HTML::String::TT->new;

sub do_tt {
    my $output;
    $tt->process(\$_[0], $_[1], \$output) or die $tt->error;
    return "$output";
}

is(
    do_tt('<tag>[% foo %]</tag>', { foo => 'Hi <bob>' }),
    '<tag>Hi &lt;bob&gt;</tag>',
);

is(
    do_tt(q{[%
        VIEW myview; BLOCK render; '<tag>'; foo; '</tag>'; END; END;
        myview.include('render');
    %]}, { foo => 'Hi <bob>' }),
    '<tag>Hi &lt;bob&gt;</tag>',
);

is(
    do_tt('<tag>[% foo | no_escape %]</tag>', { foo => 'Hi <bob>' }),
    '<tag>Hi <bob></tag>',
);

# Check we aren't nailed by https://rt.perl.org/rt3/Ticket/Display.html?id=49594

is(
    do_tt('<foo>"$b\\ar"</foo>'."\n"),
    '<foo>"$b\\ar"</foo>'."\n"
);

{ # non-ASCII characters can also trigger the bug

    use utf8;

    is(
        do_tt('<li>foo – bar.</li>', {}),
        '<li>foo – bar.</li>',
    );
}

is(
    do_tt(
        '[% FOREACH item IN items %][% item %][% END %]',
        { items => [ '<script>alert("lalala")</script>', '-> & so "on" <-' ] }
    ),
    '&lt;script&gt;alert(&quot;lalala&quot;)&lt;/script&gt;'          
        .'-&gt; &amp; so &quot;on&quot; &lt;-'
);

is( do_tt('"0"', {}), '"0"' );

{
    my $tmpl = q[
        [%- MACRO test(name, value) BLOCK;
            IF !value.length;
               "ok";
            END;
        END; -%]
[%- test("foo", "") -%]
];

    my $with_html_string_tt = do_tt($tmpl, {});

    $tt = Template->new(STASH => Template::Stash->new);
    my $with_template = do_tt($tmpl, {});

    is $with_html_string_tt, $with_template;
}

done_testing;
