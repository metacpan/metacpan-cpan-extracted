use Test2::Bundle::Extended -target => 'Export::Declare';

subtest declare_meta => sub {
    is(
        Export::Declare::Meta->new($CLASS),
        {
            export      => [],
            export_ok   => [qw/export exports export_tag export_gen export_magic export_meta import/],
            export_fail => [],
            export_tags => {
                ALL     => [qw/export exports export_tag export_gen export_magic export_meta import/],
                FAIL    => [],
                DEFAULT => [],
            },
            export_anon => {import => T()},
            export_gen => {},
            export_magic => {},

            package => $CLASS,
            vars    => 1,
            menu    => 0,
        },
        "Got meta"
    );
};

BEGIN {
    $INC{'Fake/Exporter.pm'} = 1;
    package Fake::Exporter;
    use Export::Declare qw/-vars -menu import export exports export_tag export_gen export_magic/;

    ::imported_ok(qw/import export exports export_tag export_gen export_magic/);

    export foo => sub { 'foo' };
    export 'bar';
    exports qw/baz bat/;

    export_tag f       => qw/foo fiz/;
    export_tag FAIL    => qw/fiz/;
    export_tag DEFAULT => qw/bar/;

    export_gen fiz => sub { sub { 'fiz' } };

    export_magic foo => sub { $main::FOO = 1 };

    sub bar { 'bar' }
    sub baz { 'baz' }
    sub bat { 'bat' }

    sub export_fail { () }
}

subtest import => sub {
    use Fake::Exporter ':ALL';

    ok($main::FOO, "magic ran");
    can_ok('Fake::Exporter', qw/IMPORTER_MENU/);
    ok(@Fake::Exporter::EXPORT, "Variables set");

    imported_ok(qw/foo bar baz bat fiz/);
    is(foo(), 'foo', "imported foo");
    is(bar(), 'bar', "imported bar");
    is(baz(), 'baz', "imported baz");
    is(bat(), 'bat', "imported bat");
    is(fiz(), 'fiz', "imported fiz");

    is(
        Export::Declare::Meta->new('Fake::Exporter'),
        {
            export      => ['bar'],
            export_ok   => [qw/foo bar baz bat fiz/],
            export_fail => ['fiz'],
            export_tags => {
                DEFAULT => ['bar'],
                FAIL    => ['fiz'],
                ALL     => [qw/foo bar baz bat fiz/],
                f       => [qw/foo fiz/],
            },
            export_anon  => {foo => T()},
            export_gen   => {fiz => T()},
            export_magic => {foo => T()},

            package => 'Fake::Exporter',
            vars    => 1,
            menu    => 1,
        },
        "Test package meta"
    );
};

done_testing;
