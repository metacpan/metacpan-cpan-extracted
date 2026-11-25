use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

# Ekorn::Pipeline::CSV: from_csv and to_csv, each a source or a sink
# given a file or a filehandle, and a stage otherwise (roadmap
# 2026-0049). Each is run with Text::CSV's parser, made from options,
# and with Text::CSV_PP's, given as an object.

use File::Temp qw(tempdir);

# A close that fails when asked, as one does on a full disk, and counts
# the closes it's asked for, in place of Perl's for the code compiled
# after it, Ekorn::Pipeline::CSV included.
our($FAIL_CLOSE, $CLOSES);


BEGIN {
    *CORE::GLOBAL::close = sub : prototype(;*) ($fh = *ARGV) {
        $CLOSES++;
        my $closed = CORE::close($fh);
        return $closed unless $FAIL_CLOSE;
        $! = 28;    # No space left on device
        return 0;
    };
}

# A filehandle whose writes fail, as on a failing disk.
package My::Failing::Handle {


    sub TIEHANDLE ($class) { return bless {}, $class }


    sub PRINT ($self, @) { $! = 28; return 0 }    # No space left on device
}

use Text::CSV    qw();
use Text::CSV_PP qw();
use Ekorn::Pipeline;
use Ekorn::Pipeline::CSV          qw(:all);
use Ekorn::Pipeline::Factories    qw(source);
use Ekorn::Pipeline::Sinks        qw(to_file);
use Ekorn::Pipeline::Stages::Flow qw(take);

my $class = 'Ekorn::Pipeline';
my $file  = __FILE__;
my $dir   = tempdir(CLEANUP => 1);
my $n     = 0;

# Return the path of a new file in $dir, named to end in $suffix,
# holding $content, as bytes, if given.
sub path ($suffix, $content = undef) {
    my $path = sprintf '%s/%d%s', $dir, ++$n, $suffix;
    if (defined $content) {
        open my $fh, '>:raw', $path or die "Can't write $path: $!";
        print { $fh } $content;
        close $fh or die "Can't write $path: $!";
    }
    return $path;
}

# Return what the file at $path holds, as bytes.
sub slurp ($path) {
    open my $fh, '<:raw', $path or die "Can't read $path: $!";
    local $/ = undef;
    return scalar readline $fh;
}

# Return every row read from the source from_csv makes, given the
# options.
sub read_all (@options) {
    return [$class->new->iterator(from_csv(@options))->all];
}

# Return the context each value of the source from_csv makes saw, given
# the options, as the run's stages see it.
sub contexts (@options) {
    my @seen;
    $class->new(sub ($row) {
        push @seen, Ekorn::Pipeline::run_context();
        $row;
    })
        ->iterator(from_csv(@options))
        ->all;
    return \@seen;
}

# Return an error's message without the place it was raised.
sub message ($error) {
    return ($error // '') =~ s( \ at \ \S+ \ line \ \d+ \. \n \z )()xr;
}

# The parsers each subtest is run with: Text::CSV's, made from options,
# by default, and Text::CSV_PP's, given as an object.
my @parsers = (
    ['Text::CSV' => sub { () }],
    [
        'Text::CSV_PP' =>
            sub { (csv => Text::CSV_PP->new({binary => 1, auto_diag => 0})) },
    ],
);

my $tracks = qq(title,plays\nIntro,10\n"Hello, ""World""",7\n"Two\nlines",3\n);

subtest 'Nothing is exported by default' => sub {

    package My::Plain {
        use Ekorn::Pipeline::CSV;
    }
    ok !My::Plain->can($_), "not $_" for qw(from_csv to_csv);
};

for my $parser (@parsers) {
    my($name, $csv) = @$parser;

    subtest "$name: from_csv reads rows from a file" => sub {
        is read_all(file => path('.csv', $tracks), $csv->()),
            [
                [qw(title plays)],     [qw(Intro 10)],
                ['Hello, "World"', 7], ["Two\nlines", 3],
            ],
            'as arrays, quotes, commas and newlines in fields';
        is read_all(file => path('.csv', "a,b\n1,2"), $csv->()),
            [[qw(a b)], [1, 2]],
            'the last with no newline';
        is read_all(file => path('.csv', ''), $csv->()), [], 'an empty file: none';
    };

    subtest "$name: a header names each row's fields, or is skipped" => sub {
        my $path = path('.csv', $tracks);
        is read_all(file => $path, header => 1, $csv->()),
            [
                {title => 'Intro',          plays => 10},
                {title => 'Hello, "World"', plays => 7},
                {title => "Two\nlines",     plays => 3},
            ],
            'header true: hashes';
        is read_all(file => $path, header => 'skip', $csv->()),
            [[qw(Intro 10)], ['Hello, "World"', 7], ["Two\nlines", 3]],
            'skip: arrays, without the header';
        is read_all(file => path('.csv', "a,b\n1\n2,3,4\n"), header => 1, $csv->()),
            [{a => 1, b => undef}, {a => 2, b => 3}],
            'a short row has undef, and a long one loses its extra fields';
        is read_all(file => path('.csv', ''), header => 1, $csv->()), [],
            'an empty file: none';
        is read_all(file => path('.csv', "a,b\n"), header => 1, $csv->()), [],
            'only a header: none';
    };

    subtest "$name: the header's names are the run's context" => sub {
        my $path = path('.csv', $tracks);
        is contexts(file => $path, header => 1, $csv->()),
            [({columns => [qw(title plays)]}) x 3], 'header true';
        is contexts(file => $path, header => 'skip', $csv->()),
            [({columns => [qw(title plays)]}) x 3], 'skip';
        is contexts(file => $path, $csv->()), [(undef) x 4], 'no header: none';
    };

    subtest "$name: given no file, a stage parsing each value whole" => sub {
        is [$class->new(from_csv($csv->()))->("a,b\n1,\"x\ny\"\n", "3,4")],
            [[qw(a b)], [1, "x\ny"], [3, 4]], 'every row of each value';
        is [
            $class->new(from_csv(header => 1, $csv->()))->("a,b\n1,2\n3,4", "b,a\n5,6")
            ],
            [{a => 1, b => 2}, {a => 3, b => 4}, {b => 5, a => 6}],
            'each value with its own header';
        is [$class->new(from_csv($csv->()))->('')], [], 'an empty value: none';
        is [$class->new(from_csv($csv->()))->("\x{263a},\x{e9}")],
            [["\x{263a}", "\x{e9}"]], 'characters, as they are';
    };

    subtest "$name: to_csv writes rows to a file" => sub {
        my $path = path('.csv');
        is
            scalar $class->new(to_csv(file => $path, $csv->()))
            ->([qw(title plays)], ['Hello, "World"', 7], ["Two\nlines", undef]), 3,
            'giving how many';
        is slurp($path), qq(title,plays\n"Hello, ""World""",7\n"Two\nlines",\n),
            'quoting what needs it, undef as empty';
        is scalar $class->new(to_csv(file => $path, $csv->()))->(), 0,  'none';
        is slurp($path),                                            '', 'an empty file';
    };

    subtest "$name: to_csv writes a header, and hashes in its order" => sub {
        my $path = path('.csv');
        is
            scalar $class->new(to_csv(file => $path, header => [qw(b a)], $csv->()))
            ->({a => 1, b => 2}, [3, 4], {a => 5}), 3, 'names given';
        is slurp($path), "b,a\n2,1\n3,4\n,5\n", 'the header first, then each row';
        $class->new(to_csv(file => $path, header => [qw(b a)], $csv->()))->();
        is slurp($path), "b,a\n", 'with no rows, the header alone';
        my $copy = path('.csv');
        is [$class->new(to_csv(file => $copy, header => 1, $csv->()))
                ->iterator(from_csv(file => path('.csv', $tracks), header => 1, $csv->()))
                ->all],
            [3], 'true: from the run\'s context';
        is slurp($copy), $tracks, 'the same columns, in the same order';
    };

    subtest "$name: given no file, a stage giving each row's line" => sub {
        is [$class->new(to_csv($csv->()))->([1, 'a b'], ['x,y', "\x{263a}"])],
            ['1,"a b"', qq("x,y","\x{263a}")],
            'without an end of line, as characters, quoting as Text::CSV does';
        is [$class->new(to_csv(header => [qw(b a)], $csv->()))
                ->({a => 1, b => 2}, [3, 4])
            ],
            ['b,a', '2,1', '3,4'], 'the header\'s first, once';
        is [$class->new(to_csv(header => [qw(b a)], $csv->()))->()], ['b,a'],
            'with no rows, the header alone';
        is [$class->new(to_csv(header => 1, $csv->()))
                ->iterator(from_csv(file => path('.csv', "x,y\n1,2\n"), header => 1))
                ->all],
            ['x,y', '1,2'], 'true: from the run\'s context';
    };
}

subtest 'TSV, and other separators, by csv\'s options' => sub {
    my $path = path('.tsv', qq(id\ttitle\n1\tA, B\n2\t"Q\tR"\n));
    is read_all(file => $path, header => 1, csv => {sep_char => "\t"}),
        [{id => 1, title => 'A, B'}, {id => 2, title => "Q\tR"}], 'read';
    my $copy = path('.tsv');
    $class->new(to_csv(file => $copy, header => 1, csv => {sep_char => "\t"}))
        ->iterator(from_csv(file => $path, header => 1, csv => {sep_char => "\t"}))
        ->all;
    is slurp($copy), qq(id\ttitle\n1\t"A, B"\n2\t"Q\tR"\n),
        'and written back, quoting as Text::CSV does';
    is [$class->new(to_csv(csv => {sep_char => ';'}))->([1, 2])], ['1;2'],
        'a semicolon';
};

subtest 'munge changes the header\'s names' => sub {
    my $path   = path('.csv', qq(Track Name,  Plays!,-id-\n1,2,3\n));
    my %munged = (
        lc   => {'track name' => 1, '  plays!' => 2, '-id-' => 3},
        uc   => {'TRACK NAME' => 1, '  PLAYS!' => 2, '-ID-' => 3},
        db   => {track_name   => 1, 'plays_'   => 2, 'id_'  => 3},
        none => {'Track Name' => 1, '  Plays!' => 2, '-id-' => 3},
    );
    for my $munge (sort keys %munged) {
        is read_all(file => $path, header => 1, munge => $munge), [$munged{$munge}],
            $munge;
    }
    is read_all(file => $path, header => 1, munge => {'Track Name' => 'title'}),
        [{title => 1, '  Plays!' => 2, '-id-' => 3}],
        'a hash: the names it maps, and the rest as they are';
    is read_all(file => $path, header => 1, munge => sub ($name) { "<$_>" }),
        [{'<Track Name>' => 1, '<  Plays!>' => 2, '<-id->' => 3}],
        'a code reference, given each name, as $_ too';
    is contexts(file => $path, header => 'skip', munge => 'db'),
        [{columns => [qw(track_name plays_ id_)]}], 'the context\'s names too';
    is [$class->new(from_csv(header => 1, munge => 'uc'))->("a\n1")],
        [{A => 1}],
        'in the stage too';
};

subtest 'A header naming a column twice croaks, when rows are hashes' => sub {
    like dies { read_all(file => path('.csv', "a,b,a\n1,2,3\n"), header => 1) },
        qr( \AExpected\ a\ header\ naming\ each\ column\ once,\ not\ "a"\ twice\ at\ \Q$file\E\ line )x,
        'named twice';
    like dies {
        read_all(file => path('.csv', "A,a\n1,2\n"), header => 1, munge => 'lc')
    },
        qr( \AExpected\ a\ header\ naming\ each\ column\ once,\ not\ "a"\ twice )x,
        'once munged';
    is read_all(file => path('.csv', "a,b,a\n1,2,3\n"), header => 'skip'),
        [[1, 2, 3]],
        'skipped, nothing is checked';
    is read_all(file => path('.csv', "a,,b\n1,2,3\n"), header => 1),
        [{a => 1, '' => 2, b => 3}], 'an empty name, once, is a name';
};

subtest 'Files are read and written as UTF-8, unless encoding says' => sub {
    my $utf8
        = path('.csv', "\xef\xbb\xbfname,n\n\xc3\xa9t\xc3\xa9,\xe2\x98\xba\n");
    is read_all(file => $utf8, header => 1),
        [{name => "\x{e9}t\x{e9}", n => "\x{263a}"}],
        'UTF-8, as characters, the byte order mark dropped';
    is read_all(file => path('.csv', "\xef\xbb\xbfa\n")), [['a']],
        'the mark dropped without a header too';
    is read_all(file => $utf8, encoding => 'raw')->[0][0], "\xef\xbb\xbfname",
        'raw: bytes, the mark kept';
    is read_all(file => path('.csv', "caf\xe9\n"), encoding => 'latin1'),
        [["caf\x{e9}"]], 'latin1';
    like dies { read_all(file => path('.csv', "caf\xe9\n")) },
        qr( \ACan't\ read\ \S+:\ UTF-8\ "\\xE9"\ does\ not\ map\ to\ Unicode\ at\ \Q$file\E\ line )x,
        'text that isn\'t UTF-8 croaks';

    my $path = path('.csv');
    $class->new(to_csv(file => $path))->(["\x{e9}", "\x{263a}"]);
    is slurp($path), qq(\xc3\xa9,"\xe2\x98\xba"\n), 'written as UTF-8';
    $class->new(to_csv(file => $path, encoding => 'latin1'))->(["caf\x{e9}"]);
    is slurp($path), "caf\xe9\n", 'latin1';
    $class->new(to_csv(file => $path, encoding => 'raw'))->(["caf\xc3\xa9"]);
    is slurp($path), "caf\xc3\xa9\n", 'raw: bytes, as they are';
    like dies {
        $class->new(to_csv(file => $path, encoding => 'latin1'))->(["\x{263a}"])
    },
        qr( \n\s+Can't\ write\ \Q$path\E:\ "\\x\{263a\}"\ does\ not\ map\ to\ iso-8859-1\ at\ \Q$file\E\ line )x,
        'a character the encoding can\'t hold croaks';
    like dies {
        $class->new(to_csv(file => $path, encoding => 'raw'))->(["\x{263a}"])
    },
        qr( \n\s+Can't\ write\ a\ row\ as\ CSV:\ field\ 1\ holds\ a\ wide\ character,\ and\ the\ file\ is\ written\ raw\ at\ \Q$file\E\ line )x,
        'as does a wide character, raw';
};

# An undefined first field has no byte order mark to drop, and warned
# from inside Ekorn::Pipeline::CSV (roadmap 2026-0053).
subtest 'A first field undefined, as blank_is_undef makes it' => sub {
    my $csv = {blank_is_undef => 1};
    is read_all(file => path('.csv', ",b\n1,2\n"), csv => $csv),
        [[undef, 'b'], [1, 2]], 'from a file';
    is [$class->new(from_csv(csv => $csv))->(",b\n")], [[undef, 'b']],
        'from a value';
};

subtest 'A row that won\'t parse croaks, saying where' => sub {
    my $path = path('.csv', qq(a,b\n1,2\n3,"x\n5,6\n));
    like dies { read_all(file => $path) },
        qr( \ACan't\ parse\ CSV\ from\ \Q$path\E,\ record\ 3,\ field\ 2:\ EIQ\ -\ .*\ at\ \Q$file\E\ line )x,
        'a file';
    like dies { read_all(file => $path, header => 1) },
        qr( \ACan't\ parse\ CSV\ from\ \Q$path\E,\ record\ 3,\ field\ 2:\  )x,
        'the header counted';
    open my $fh, '<', $path or die $!;
    like dies { read_all(fh => $fh) },
        qr( \ACan't\ parse\ CSV\ from\ the\ filehandle,\ record\ 3,\ field\ 2:\  )x,
        'a filehandle';
    like dies { $class->new(from_csv)->("1,2", qq(1,"x)) },
        qr( \n\s+Can't\ parse\ CSV\ from\ a\ value,\ record\ 1,\ field\ 2:\  )x,
        'a value';
};

subtest 'Each run reads the file afresh, and closes it as it ends' => sub {
    my $source = from_csv(file => path('.csv', $tracks), header => 1);
    my @first  = $class->new->iterator($source)->all;
    is [$class->new->iterator($source)->all], \@first,
        'a second run reads the header again, not as data';
    local $CLOSES = 0;
    is [$class->new(take(1))->iterator($source)->all], [$first[0]],
        'stopped early';
    is $CLOSES, 1, 'the file closed';
};

subtest 'A filehandle is read and written as it is, and left open' => sub {
    open my $in, '<:encoding(UTF-8)', path('.csv', "a\n\xc3\xa9\n") or die $!;
    is [$class->new->iterator(from_csv(fh => $in, header => 1))->all],
        [{a => "\x{e9}"}], 'read, with its own layers';
    ok defined fileno $in, 'and left open';
    open my $out, '>', \my $written or die $!;
    is
        scalar $class->new(to_csv(fh => $out, csv => {eol => "\r\n"}))
        ->([1, 2], [3]),
        2, 'written';
    ok defined fileno $out, 'and left open';
    close $out;
    is $written, "1,2\r\n3\r\n", 'with csv\'s eol';
};

subtest 'Rows to_csv can\'t write' => sub {
    like dies { $class->new(to_csv)->('a,b') },
        qr( \n\s+Expected\ a\ row\ as\ an\ array\ or\ a\ hash\ reference\ at\ \Q$file\E\ line )x,
        'not a reference';
    like dies { $class->new(to_csv)->({a => 1}) },
        qr( \n\s+Expected\ a\ header\ naming\ the\ columns,\ to\ write\ a\ hash\ at\ \Q$file\E\ line )x,
        'a hash with no header';
    like dies { $class->new(to_csv(header => 1))->([1]) },
        qr( \n\s+Expected\ the\ run's\ context\ to\ name\ its\ columns,\ for\ to_csv's\ header\ at\ \Q$file\E\ line )x,
        'header true, with no context';
    my $other
        = source { {step => sub { return }, context => {statement => 'x'}} };
    like dies { $class->new(to_csv(header => 1))->iterator($other)->all },
        qr( \n\s+Expected\ the\ run's\ context\ to\ name\ its\ columns )x,
        'or one without columns';
    like dies { $class->new(to_csv)->([1, [2]]) },
        qr( \n\s+Can't\ write\ a\ row\ as\ CSV:\ field\ 2\ is\ a\ reference\ at\ \Q$file\E\ line )x,
        'a field that is a reference';
    like dies { $class->new(to_csv(csv => {binary => 0}))->(["a\nb"]) },
        qr( \n\s+Can't\ write\ a\ row\ as\ CSV:\ \S.*\ at\ \Q$file\E\ line )x,
        'one the parser won\'t write';
};

subtest 'Mistakes are reported at the caller\'s line' => sub {
    my %error = (
        'Expected options as name => value pairs'   => [qw(file)],
        'Expected file to be a path'                => [file => undef],
        'Expected a file or a filehandle, not both' => [file => 'x', fh => \*STDIN],
        'Expected an open filehandle'               => [fh   => undef],
        'Expected csv to be a hash reference of options, or a parser object' =>
            [csv => [1]],
        'Expected encoding only with a file'           => [encoding => 'latin1'],
        'Expected an encoding Perl knows, not klingon' =>
            [file => 'x', encoding => 'klingon'],
        'Expected an encoding Perl knows, not undef' =>
            [file => 'x', encoding => undef],
    );
    for my $function (\&from_csv, \&to_csv) {
        for my $expected (sort keys %error) {
            is message(dies { $function->(@{ $error{$expected} }) }), $expected,
                $expected;
        }
        is message(dies { $function->(fh => \*STDIN, encoding => 'latin1') }),
            'Expected encoding only with a file', 'encoding, with a filehandle';
        like message(dies { $function->(file => 'x', encoding => []) }),
            qr( \AExpected\ an\ encoding\ Perl\ knows,\ not\ ARRAY )x,
            'encoding, a reference';
        like dies { $function->(csv => {nonsense => 1}) },
            qr( \AExpected\ csv\ options\ the\ parser\ knows:\ \S.*\ at\ \Q$file\E\ line\ \d+\.\n\z )x,
            'an option the parser does not know';
    }
    is message(dies { from_csv(flie => 1, a => 2) }),
        'Expected the options file, fh, csv, header, munge and encoding, not a, flie',
        'from_csv: an option it does not know';
    is message(dies { to_csv(munge => 'lc') }),
        'Expected the options file, fh, csv, header and encoding, not munge',
        'to_csv: one it does not know';
    is message(dies { from_csv(header => $_) }),
        q(Expected header to be true, false or 'skip'),
        'from_csv: header ' . ($_ // 'undef')
        for 'yes', [1];
    is message(dies { to_csv(header => $_) }),
        'Expected header to be true, false or an array reference of names',
        'to_csv: header ' . (ref $_ || $_)
        for 'skip', {}, ['a', undef], ['a', ['b']];
    is message(dies { from_csv(munge => 'lc') }),
        'Expected munge only with a header',
        'munge, without a header';
    is message(dies { from_csv(header => 1, munge => $_) }),
        'Expected munge to be lc, uc, db, none, a hash reference or a code reference',
        'munge ' . ($_ // 'undef')
        for 'upper', undef, [];
    ok lives { from_csv(header => $_) }, 'header ' . ($_ // 'undef')
        for undef, '', 0, 1;
};

subtest 'Files that cannot be read or written' => sub {
    my $missing = "$dir/missing/x.csv";
    like dies { read_all(file => $missing) },
        qr( \ACan't\ read\ \Q$missing\E:\ \S.*\ at\ \Q$file\E\ line )x, 'read';
    like dies { $class->new(to_csv(file => $missing))->([1]) },
        qr( \ACan't\ write\ \Q$missing\E:\ \S.*\ at\ \Q$file\E\ line )x, 'write';
};

subtest 'Writes and closes that fail' => sub {
    tie *FAILING, 'My::Failing::Handle';
    like dies { $class->new(to_csv(fh => \*FAILING))->([1]) },
        qr( Pipeline\ stage\ \#1\ failed\ .*\n\s+Can't\ write\ the\ filehandle:\ \S.*\ at\ \Q$file\E\ line )x,
        'a write';
    my $path = path('.csv');
    local $FAIL_CLOSE = 1;
    like dies { $class->new(to_csv(file => $path))->([1]) },
        qr( Pipeline\ end\ of\ stage\ \#1\ failed\ .*\n\s+Can't\ write\ \Q$path\E:\ \S.*\ at\ \Q$file\E\ line )x,
        'a close';
};

subtest 'In a chain, with Ekorn::Pipeline::Sinks' => sub {
    my $path = path('.csv');
    $class->new(to_csv(header => [qw(a b)]), to_file($path))
        ->({a => 1, b => 2});
    # to_file writes in the platform's text mode: "\r\n" on Windows.
    is slurp($path) =~ s( \r\n )(\n)gxr, "a,b\n1,2\n",
        'the stage, written by to_file';
    is read_all(file => $path, header => 1), [{a => 1, b => 2}], 'read back';
};

done_testing;
