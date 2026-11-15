use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

# Ekorn::Pipeline::JSON: from_json, from_jsonl, to_json and to_jsonl,
# each a source or a sink given a file or a filehandle, and a stage
# otherwise (roadmap 2026-0034). Each is run with JSON::MaybeXS's encoder
# and with JSON::PP's, given as an object.

use File::Temp qw(tempdir);

# A close that fails when asked, as one does on a full disk, in place of
# Perl's for the code compiled after it, Ekorn::Pipeline::JSON included.
our $FAIL_CLOSE;


BEGIN {
    *CORE::GLOBAL::close = sub : prototype(;*) ($fh = *ARGV) {
        my $closed = CORE::close($fh);
        return $closed unless $FAIL_CLOSE;
        $! = 28;    # No space left on device
        return 0;
    };
}

# A filehandle whose reads and writes fail, as on a failing disk.
package My::Failing::Handle {
    sub TIEHANDLE ($class)   { return bless {}, $class }
    sub READ      ($self, @) { $! = 5;  return }      # Input/output error
    sub PRINT     ($self, @) { $! = 28; return 0 }    # No space left on device
}

# An encoder of the caller's own, offering only what writing needs.
package My::Encoder {
    sub new    ($class)        { return bless {}, $class }
    sub encode ($self, $value) { return "<$value>" }
}

use JSON::PP qw();
use Ekorn::Pipeline;
use Ekorn::Pipeline::JSON         qw(:all);
use Ekorn::Pipeline::Sinks        qw(keep_all to_file);
use Ekorn::Pipeline::Stages::Flow qw(take);

my $class = 'Ekorn::Pipeline';
my $file  = __FILE__;
my $dir   = tempdir(CLEANUP => 1);
my $n     = 0;

# Return the path of a new file in $dir, named to end in $suffix,
# holding $content, if given.
sub path ($suffix, $content = undef) {
    my $path = sprintf '%s/%d%s', $dir, ++$n, $suffix;
    if (defined $content) {
        open my $fh, '>:raw', $path or die "Can't write $path: $!";
        print { $fh } $content;
        close $fh or die "Can't write $path: $!";
    }
    return $path;
}


# Return what the file at $path holds.
sub slurp ($path) {
    open my $fh, '<:raw', $path or die "Can't read $path: $!";
    local $/ = undef;
    return scalar readline $fh;
}


# Return every value read from the source $from makes, given the options.
sub read_all ($from, @options) {
    return [$class->new->iterator($from->(@options))->all];
}


# Return an error's message without the place it was raised.
sub message ($error) {
    return ($error // '') =~ s( \ at \ \S+ \ line \ \d+ \. \n \z )()xr;
}

# The encoders each subtest is run with: JSON::MaybeXS's, by default, and
# JSON::PP's, given as an object.
my @encoders = (
    ['JSON::MaybeXS' => sub { () }],
    [
        'JSON::PP' =>
            sub { (json => JSON::PP->new->utf8->allow_nonref->canonical) },
    ],
);

subtest 'Nothing is exported by default' => sub {

    package My::Plain {
        use Ekorn::Pipeline::JSON;
    }
    ok !My::Plain->can($_), "not $_"
        for qw(from_json from_jsonl to_json to_jsonl);
};

for my $encoder (@encoders) {
    my($name, $json) = @$encoder;
    my $from_json  = sub (@options) { from_json(@options, $json->()) };
    my $from_jsonl = sub (@options) { from_jsonl(@options, $json->()) };

    subtest "$name: from_json reads one document" => sub {
        is read_all($from_json, file => path('.json', qq([{"a":1},{"a":2}]\n))),
            [{a => 1}, {a => 2}], 'an array: its elements';
        is read_all($from_json, file => path('.json', qq({"a":1}\n))), [{a => 1}],
            'an object: itself';
        is read_all($from_json, file => path('.json', '7')), [7],
            'a number: itself';
        is read_all($from_json, file => path('.json', '')), [],
            'an empty file: none';
        is read_all($from_json, file => path('.json', qq([]\n))), [],
            'an empty array: none';
        is read_all($from_json, file => path('.json', " \n\t\n")), [],
            'only whitespace: none';
        like dies { read_all($from_json, file => path('.json', qq(1\n2\n))) },
            qr(\ACan't decode JSON from \S+: it holds more than one document; read JSON Lines with from_jsonl at \Q$file\E line),
            'more than one croaks, pointing to from_jsonl';
    };

    subtest "$name: from_jsonl reads a document a line" => sub {
        is read_all(
            $from_jsonl,
            file => path('.jsonl', qq({"a":1}\n{"a":2}\n[3,4]\n)),
            ),
            [{a => 1}, {a => 2}, [3, 4]], 'each, an array as it is';
        is read_all($from_jsonl, file => path('.jsonl', qq([1,2]\n))), [[1, 2]],
            'an array alone, as it is';
        is read_all($from_jsonl, file => path('.jsonl', qq([1] [2]))), [[1], [2]],
            'documents one after another, on one line';
        is read_all($from_jsonl, file => path('.jsonl', qq(1\n2\n3))), [1, 2, 3],
            'the last with no newline';
        is read_all($from_jsonl, file => path('.jsonl', '')), [],
            'an empty file: none';
    };

    subtest "$name: reading a block at a time never cuts a document" => sub {
        local $Ekorn::Pipeline::JSON::BLOCK = 3;
        my @rows    = map { {n => $_, text => 'x' x $_} } 1 .. 20;
        my $encoder = JSON::PP->new->canonical;
        my $lines   = join '', map { $encoder->encode($_) . "\n" } @rows;
        is read_all($from_jsonl, file => path('.jsonl', $lines)), \@rows,
            'JSON Lines';
        is read_all($from_json, file => path('.json', $encoder->encode(\@rows))),
            \@rows,
            'one array, on one line';
        is read_all(
            $from_json,
            file => path('.json', $encoder->pretty->encode(\@rows)),
            ),
            \@rows, 'one array, over many lines';
        is read_all($from_jsonl, file => path('.jsonl', "12345\n678\n9")),
            [12345, 678, 9],
            'numbers, each whole';
    };

    subtest "$name: from_jsonl reads only as it's pulled" => sub {
        my $lines = join '', map { "$_\n" } 1 .. 10;
        is [$class->new(take(2))
                ->iterator($from_jsonl->(file => path('.jsonl', $lines)))
                ->all],
            [1, 2], 'a stop ends the reading';
        my $next
            = $class->new->iterator($from_jsonl->(file => path('.jsonl', $lines)));
        is [$next->(), $next->()], [1, 2], 'one at a time';
    };

    subtest "$name: reading a filehandle leaves it open" => sub {
        open my $fh, '<:raw', path('.jsonl', qq({"a":1}\n{"b":2}\n)) or die $!;
        is read_all($from_jsonl, fh => $fh), [{a => 1}, {b => 2}], 'each document';
        ok defined fileno($fh), 'still open';
        close $fh;
        open $fh, '<:raw', path('.json', qq([1,2]\n)) or die $!;
        is read_all($from_json, fh => $fh), [1, 2], 'one document';
        close $fh;
    };

    subtest "$name: each run reads afresh" => sub {
        my $source = $from_json->(file => path('.json', qq([1,2]\n)));
        is [$class->new->iterator($source)->all], [1, 2], 'the first run';
        is [$class->new->iterator($source)->all], [1, 2], 'the second';
        my $broken = $from_jsonl->(file => path('.jsonl', qq({"a":)));
        ok dies { $class->new->iterator($broken)->all }, 'a run that dies';
        is read_all($from_jsonl, file => path('.jsonl', qq([3]\n))), [[3]],
            'leaves nothing behind';
    };

    subtest "$name: from_json as a stage decodes one document a value" => sub {
        my $stage = $class->new($from_json->());
        is [$stage->(q({"a":1}), '[5,6]', '[]', '7')], [{a => 1}, 5, 6, 7],
            'an array gives its elements';
        like dies { $stage->('[1] [2]') }, qr(Can't decode JSON from a value: \S),
            'more than one croaks';
        like dies { $stage->('{"a":') }, qr(Can't decode JSON from a value: \S),
            'incomplete';
        is [$stage->('[7]')], [7], 'and goes on';
    };

    subtest "$name: from_jsonl as a stage gives each line's document" => sub {
        my $stage = $class->new($from_jsonl->());
        is [$stage->(q({"a":1}), "1\n2\n", '[5,6]', '')], [{a => 1}, 1, 2, [5, 6]],
            'one, or each of several; an array as it is; none from none';
        like dies { $stage->('{"a":1}}') }, qr(Can't decode JSON from a value: \S),
            'malformed';
        like dies { $stage->('{"a":') },
            qr(Can't decode JSON from a value: it ends inside a document), 'incomplete';
        is [$stage->('[7]')], [[7]], 'and the next run is afresh';
    };

    subtest "$name: stages pass on what a file would hold" => sub {
        my %to = (
            to_json  => sub { to_json($json->()) },
            to_jsonl => sub { to_jsonl($json->()) },
        );
        is [$class->new($to{to_jsonl}->())->({a => 1}, [2], 3)],
            ['{"a":1}', '[2]', '3'],
            'to_jsonl: each value, one line';
        is [$class->new($to{to_json}->())->(1, 2, 3)], ['[1,2,3]'],
            'to_json: every value, as one array';
        is [$class->new($to{to_json}->())->()], ['[]'], 'none: an empty array';
        is [$class->new($to{to_json}->(), $from_json->())->({a => 1}, [2])],
            [{a => 1}, [2]],
            'from_json undoes to_json';
        is [$class->new($to{to_jsonl}->(), $from_jsonl->())->({a => 1}, [2])],
            [{a => 1}, [2]], 'from_jsonl undoes to_jsonl';
        like dies {
            $class->new($to{to_jsonl}->())->(sub { })
        },
            qr(Can't encode a value as JSON: \S), 'a value that cannot be encoded';
    };

    subtest "$name: sinks write a file, and give how many" => sub {
        my $values    = [{a => 1}, [2], 'three'];
        my $json_file = path('.json');
        is scalar $class->new(to_json(file => $json_file, $json->()))->(@$values),
            3,
            'to_json';
        is slurp($json_file), qq([{"a":1},[2],"three"]\n),    'one array';
        is read_all($from_json, file => $json_file), $values, 'read back';

        my $lines_file = path('.jsonl');
        is scalar $class->new(to_jsonl(file => $lines_file, $json->()))->(@$values),
            3,
            'to_jsonl';
        is slurp($lines_file), qq({"a":1}\n[2]\n"three"\n),     'JSON Lines';
        is read_all($from_jsonl, file => $lines_file), $values, 'read back';

        my $empty = path('.json');
        is scalar $class->new(to_json(file => $empty, $json->()))->(), 0, 'none';
        is slurp($empty), qq([]\n), 'an empty array';

        my $stopped = path('.json');
        $class->new(take(2), to_json(file => $stopped, $json->()))->(1, 2, 3);
        is slurp($stopped), qq([1,2]\n), 'a stop before it still closes the array';
    };

    subtest "$name: sinks write a filehandle, and leave it open" => sub {
        my $out = '';
        open my $fh, '>:raw', \$out or die $!;
        is scalar $class->new(to_jsonl(fh => $fh, $json->()))->(1, [2]), 2,
            'gives how many';
        is $out, qq(1\n[2]\n), 'to_jsonl: JSON Lines';
        print { $fh } 'more' or die $!;
        $class->new(to_json(fh => $fh, $json->()))->(3);
        is $out, qq(1\n[2]\nmore[3]\n), 'to_json: one array, and still open';
        close $fh;
    };
}

subtest 'to_json indents an array of values, if its encoder does' => sub {
    my $path = path('.json');
    $class->new(to_json(file => $path, json => {pretty => 1, canonical => 1}))
        ->({a => 1}, [2]);
    is slurp($path), <<~'JSON', 'each value indented in the array';
        [
           {
              "a" : 1
           },
           [
              2
           ]
        ]
        JSON
    is read_all(\&from_json, file => $path), [{a => 1}, [2]], 'read back';
    is [$class->new(to_json(json => {pretty => 1}))->(1, 2)],
        ["[\n   1,\n   2\n]"],
        'the stage, as the encoder makes it, without its newline';
};

subtest 'json: options over the defaults, or an object as it is' => sub {
    is [$class->new(to_jsonl(json => {canonical => 1}))->({b => 1, a => 2})],
        ['{"a":2,"b":1}'], 'options';
    is [$class->new(to_jsonl)->("\x{e9}")], [qq("\xc3\xa9")],
        'UTF-8 bytes by default';
    is [$class->new(to_jsonl(json => {utf8 => 0}))->("\x{e9}")], [qq("\x{e9}")],
        'characters, with utf8 off';
    is [$class->new(from_json)->(qq("\xc3\xa9"))], ["\x{e9}"],
        'decoding UTF-8 bytes';
    my $object = JSON::PP->new->allow_nonref->canonical->space_after;
    is [$class->new(to_jsonl(json => $object))->({b => 1, a => 2})],
        ['{"a": 2,"b": 1}'],
        'an object';
};

subtest 'Mistakes are reported at the caller\'s line' => sub {
    my %error = (
        'Expected options as name => value pairs'             => [qw(file)],
        'Expected the options file, fh and json, not flie'    => [flie => 1],
        'Expected the options file, fh and json, not a, type' =>
            [type => 1, a => 2],
        'Expected file to be a path'                => [file => undef],
        'Expected a file or a filehandle, not both' => [file => 'x', fh => \*STDIN],
        'Expected an open filehandle'               => [fh   => undef],
        'Expected json to be a hash reference of options, or an encoder object' =>
            [json => [1]],
    );
    for my $function (\&from_json, \&from_jsonl, \&to_json, \&to_jsonl) {
        for my $expected (sort keys %error) {
            is message(dies { $function->(@{ $error{$expected} }) }), $expected,
                $expected;
        }
        like dies { $function->(json => {nonsense => 1}) },
            qr(\AExpected json options the encoder knows: \S.* at \Q$file\E line \d+\.\n\z),
            'an option the encoder does not know';
    }
    like dies { to_jsonl(file => path('.jsonl'), json => {pretty => 1}) },
        qr(\AExpected an encoder that doesn't indent, to write JSON Lines at \Q$file\E line),
        'JSON Lines, indented, as a sink';
    like dies { to_jsonl(json => {pretty => 1}) },
        qr(\AExpected an encoder that doesn't indent), 'or as a stage';
    ok lives { to_json(json => {pretty => 1}) }, 'but not one document';
};

subtest 'Files that cannot be read or written' => sub {
    my $missing = "$dir/missing/x.json";
    like dies { read_all(\&from_json, file => $missing) },
        qr(\ACan't read \Q$missing\E: \S.* at \Q$file\E line), 'read';
    like dies { $class->new(to_json(file => $missing))->(1) },
        qr(\ACan't write \Q$missing\E: \S.* at \Q$file\E line), 'write';
    like dies { read_all(\&from_jsonl, file => path('.jsonl', '{"a":1}}')) },
        qr(\ACan't decode JSON from \S+: \S.* at \Q$file\E line), 'malformed';
    like dies { read_all(\&from_json, file => path('.json', '[1,')) },
        qr(\ACan't decode JSON from \S+: it ends inside a document at \Q$file\E line),
        'incomplete';
    open my $fh, '<:raw', path('.json', '{') or die $!;
    like dies { read_all(\&from_jsonl, fh => $fh) },
        qr(\ACan't decode JSON from the filehandle: it ends inside a document),
        'a filehandle';
};

subtest 'Reads, writes and closes that fail' => sub {
    tie *FAILING, 'My::Failing::Handle';
    like dies { read_all(\&from_jsonl, fh => \*FAILING) },
        qr(\ACan't read the filehandle: \S.* at \Q$file\E line), 'a read';
    like dies { $class->new(to_jsonl(fh => \*FAILING))->(1) },
        qr(Pipeline stage #1 failed .*\n\s+Can't write the filehandle: \S.* at \Q$file\E line),
        'a write';
    my $path = path('.json');
    local $FAIL_CLOSE = 1;
    like dies { $class->new(to_json(file => $path))->(1) },
        qr(Pipeline end of stage #1 failed .*\n\s+Can't write \Q$path\E: \S.* at \Q$file\E line),
        'a close';
};

subtest 'An encoder of your own needs only encode, to write' => sub {
    is [$class->new(to_jsonl(json => My::Encoder->new))->(1, 2)],
        ['<1>', '<2>'],
        'one that cannot say whether it indents is taken not to';
};

subtest 'In a chain, with Ekorn::Pipeline::Sinks' => sub {
    my $path = path('.jsonl');
    $class->new(to_jsonl(json => {canonical => 1}), to_file($path))
        ->({a => 1}, {b => 2});
    # to_file writes in the platform's text mode: "\r\n" on Windows.
    is slurp($path) =~ s( \r\n )(\n)gxr, qq({"a":1}\n{"b":2}\n),
        'the stage, written by to_file';
    is [$class->new(keep_all)->iterator(from_jsonl(file => $path))->all],
        [{a => 1}, {b => 2}], 'read back';
};

done_testing;
