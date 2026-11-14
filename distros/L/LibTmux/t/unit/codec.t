use v5.44;
use Test2::V1;
use Scalar::Util qw(blessed);

my $loaded = eval { require LibTmux::Codec; 1 };
T2->ok($loaded, 'reversible tmux field codec is loadable');
unless ($loaded) { T2->diag($@); T2->done_testing; exit }

my $decoded =
    LibTmux::Codec->decode("a\\tb\tline\\nend\tback\\\\slash\t\xff\n", 4);
T2->is(
    $decoded,
    [["a\tb", "line\nend", "back\\slash", "\xff"]],
    'decode escapes before field typing without losing bytes'
);
T2->is(
    LibTmux::Codec->decode("\t\n", 2),
    [['', '']],
    'empty fields remain fields'
);
T2->is(LibTmux::Codec->decode("\n", 1), [['']], 'one empty field is a record');
T2->is(
    LibTmux::Codec->decode("\n\n", 1),
    [[''], ['']],
    'consecutive empty records preserve multiplicity'
);
T2->is(LibTmux::Codec->decode('', 1), [], 'no output means no records');

T2->is(
    LibTmux::Codec->decode('\a\b\f\v\r\$HOME\377' . "\n", 1),
    [["\a\b\f\x0b\r" . '$HOME' . "\xff"]],
    'legacy tmux print escapes compose with the field codec'
);
T2->is(LibTmux::Codec->decode('\\\\377\\\\n\\\\$HOME' . "\n", 1),
    [['\377\n\$HOME']], 'literal escape text is decoded exactly once');
for my $bad ('\400', '\38', '\12') {
    my $error;
    try { LibTmux::Codec->decode($bad . "\n", 1) } catch ($caught) {
        $error = $caught;
    }
    T2->isa_ok($error, ['LibTmux::X::Codec'],
        'invalid legacy octal escape is rejected');
}

for my $bad ("a\tb", "a\\q\tb\n", "a\\\tb\n", "a\tb\tc\n") {
    my $e;
    try { LibTmux::Codec->decode($bad, 2) } catch ($caught) {
        $e = $caught
    }
    T2->ok(blessed($e) && $e->isa('LibTmux::X::Codec'),
        'malformed frames are failures');
}
for my $case (
    [option      => "\@value \\q\n",                      '@value'],
    [option      => "status-left \"unterminated\n",       'status-left'],
    [option      => "status-left \"a\" \"b\"\n",          'status-left'],
    [environment => "VALUE=\"\\q\"; export VALUE;\n",     'VALUE'],
    [environment => "VALUE=\"text\"; export OTHER;\n",    'VALUE'],
    [environment => "VALUE=\"a\" \"b\"; export VALUE;\n", 'VALUE']
    )
{
    my ($kind, $bytes, $name) = @$case;
    my $error;
    try {
        $kind eq 'option'
            ? LibTmux::Codec->_option_value($bytes, $name)
            : LibTmux::Codec->_environment_value($bytes, $name);
    }
    catch ($caught) { $error = $caught }
    T2->isa_ok($error, ['LibTmux::X::Codec'],
        'malformed quoted value is rejected');
}
T2->done_testing;
