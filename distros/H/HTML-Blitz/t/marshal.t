use Test2::V0;
use HTML::Blitz ();

my $blitz = HTML::Blitz->new(
    [ '.box' =>
        [ repeat_inner => 'values',
            [ '.ca'  => [remove_if => 'del_a'] ],
            [ '.cb'  => [replace_inner_var => 'text'] ],
            [ '.sep' => ['separator'] ],
        ],
    ],
);

my $template = $blitz->apply_to_html('(test)', <<'_EOT_');
<div class=box>
    <p class=sep>>>></p> <p class=ca>AAA</p> <p class=cb>BBB</p>
</div>
_EOT_

my $data = {
    values => [
        { del_a => 0, text => 'd1' },
        { del_a => 1, text => 'd2' },
        { del_a => 0, text => 'd3' },
    ],
};

my $expected = <<'_EOT_';
<div class=box>
     <p class=ca>AAA</p> <p class=cb>d1</p>

    <p class=sep>>>></p>  <p class=cb>d2</p>

    <p class=sep>>>></p> <p class=ca>AAA</p> <p class=cb>d3</p>
</div>
_EOT_
is $template->process($data), $expected, 'sanity check';

SKIP: {
    eval { require Sereal::Encoder; Sereal::Encoder->VERSION(4.024); 1 }
        or skip 'Sereal::Encoder >=4.024 is not available', 2;

    my $enc = Sereal::Encoder->new({ freeze_callbacks => 1 });
    my $blob = $enc->encode($template);
    note $blob =~ s/([^ -~]|\\)/sprintf '\\x%02x', ord $1/egr;

    eval { require Sereal::Decoder; Sereal::Decoder->VERSION(4.024); 1 }
        or skip 'Sereal::Decoder >=4.024 is not available', 2;

    my $tnew = Sereal::Decoder::decode_sereal $blob;
    isa_ok $tnew, 'HTML::Blitz::Template';
    #note $tnew->compile_to_string;

    is $tnew->process($data), $expected, 'Sereal deserialized template works';
}

SKIP: {
    eval { require Cpanel::JSON::XS; Cpanel::JSON::XS->VERSION(3.0103); 1 }
        or skip 'Cpanel::JSON::XS >=3.0103 is not available', 2;

    my $enc = Cpanel::JSON::XS->new->allow_tags;
    my $blob = $enc->encode($template);
    note $blob;

    my $tnew = $enc->decode($blob);
    isa_ok $tnew, 'HTML::Blitz::Template';
    #note $tnew->compile_to_string;

    is $tnew->process($data), $expected, 'JSON deserialized template works';
}

done_testing;
