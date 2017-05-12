use Test2::Bundle::Extended -target => 'Export::Declare::Meta';
use Test::Fatal;

$Test::Builder::Level = 1 unless defined $Test::Builder::Level;

subtest construction_and_accessors => sub {
    like(
        exception {$CLASS->new},
        qr/Export::Declare::Meta constructor requires a package name/,
        "package is required"
    );

    my $one = $CLASS->new('Fake::Exporter1');
    isa_ok($one, $CLASS);
    can_ok($one, qw{
        export export_ok export_fail export_tags export_anon export_gen
        export_magic package vars menu
    });

    ref_is($CLASS->new('Fake::Exporter1'), $one, "new returns the same ref");

    is($one->vars, 0, "vars boolean");
    is($one->menu, 0, "menu boolean");

    is($one->package, 'Fake::Exporter1', "package accessor");

    is($one->export,      [], "export accessor and default");
    is($one->export_ok,   [], "export_ok accessor and default");
    is($one->export_fail, [], "export_fail accessor and default");
    is($one->export_anon,  {}, "export_anon accessor and default");
    is($one->export_gen,   {}, "export_gen accessor and default");
    is($one->export_magic, {}, "export_magic accessor and default");
    is(
        $one->export_tags,
        {
            DEFAULT => exact_ref $one->export,
            FAIL    => exact_ref $one->export_fail,
            ALL     => exact_ref $one->export_ok,
        },
        "export_tags accessor and default"
    );
};

subtest inject_menu => sub {
    my $one = $CLASS->new('Fake::Exporter2');
    is($one->menu, 0, "no menu");
    ok(!Fake::Exporter2->can('IMPORTER_MENU'), "No IMPORTER_MENU");

    $one->inject_menu;

    is($one->menu, 1, "Menu injected");

    like(
        {Fake::Exporter2->IMPORTER_MENU},
        {
            export       => [],
            export_ok    => [],
            export_fail  => [],
            export_tags  => {DEFAULT => [], FAIL => [], ALL => []},
            export_anon  => {},
            export_gen   => {},
            export_magic => {},
        },
        "Got menu"
    );
};

subtest inject_vars => sub {
    my $one = $CLASS->new('Fake::Exporter3');
    is($one->vars, 0, "no vars");

    unlike(
        $one,
        {
            export       => exact_ref \@Fake::Exporter3::EXPORT,
            export_ok    => exact_ref \@Fake::Exporter3::EXPORT_OK,
            export_fail  => exact_ref \@Fake::Exporter3::EXPORT_FAIL,
            export_tags  => exact_ref \%Fake::Exporter3::EXPORT_TAGS,
            export_anon  => exact_ref \%Fake::Exporter3::EXPORT_ANON,
            export_gen   => exact_ref \%Fake::Exporter3::EXPORT_GEN,
            export_magic => exact_ref \%Fake::Exporter3::EXPORT_MAGIC,
        },
        "Variables are not linked to the meta-object"
    );

    $one->inject_vars;

    like(
        $one,
        {
            export       => exact_ref \@Fake::Exporter3::EXPORT,
            export_ok    => exact_ref \@Fake::Exporter3::EXPORT_OK,
            export_fail  => exact_ref \@Fake::Exporter3::EXPORT_FAIL,
            export_tags  => exact_ref \%Fake::Exporter3::EXPORT_TAGS,
            export_anon  => exact_ref \%Fake::Exporter3::EXPORT_ANON,
            export_gen   => exact_ref \%Fake::Exporter3::EXPORT_GEN,
            export_magic => exact_ref \%Fake::Exporter3::EXPORT_MAGIC,
        },
        "Variables are linked to the meta-object"
    );
};

subtest default => sub {
    my $one = $CLASS->new('Fake::Exporter4', default => 1);
    ok($one->vars, "vars by default");
    ok(!$one->menu, "no menu by default");

    $one = $CLASS->new('Fake::Exporter5', vars => 1);
    ok($one->vars, "vars selected");
    ok(!$one->menu, "no menu");

    $one = $CLASS->new('Fake::Exporter6', menu => 1);
    ok($one->menu, "menu selected");
    ok(!$one->vars, "no vars");

    $one = $CLASS->new('Fake::Exporter7', menu => 1, vars => 1);
    ok($one->menu, "menu selected");
    ok($one->vars, "vars selected");

    $one = $CLASS->new('Fake::Exporter7', menu => 1, vars => 1, default => 1);
    ok($one->menu, "menu selected");
    ok($one->vars, "vars selected");
};

done_testing;
