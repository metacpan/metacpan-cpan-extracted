#!/usr/bin/env perl

use v5.38;
use feature 'try';
no warnings 'experimental::try';

use lib ('../lib', 'lib');
use Test2::V0 '!call';

use Logic::Relational          qw(variable call);
use Logic::Relational::Program ();
use Logic::Relational::Syntax;

# -----------------------------------------------------------------------------
# 1. Programmatic API: Name, Version, Description, and Metadata
# -----------------------------------------------------------------------------
subtest 'Programmatic metadata accessors and defaults' => sub {
    my $prog = Logic::Relational::Program->new();

    is($prog->name,            'LogicProgram', 'Default program name');
    is($prog->program_version, '1.0.0',        'Default user version');
    is($prog->description,     '',             'Default description is empty');

    $prog->name('AcuLogic');
    $prog->program_version('0.4.0');
    $prog->description('Acupuncture relational knowledge base');

    is($prog->name,            'AcuLogic',                              'Updated name');
    is($prog->program_version, '0.4.0',                                 'Updated program_version');
    is($prog->description,     'Acupuncture relational knowledge base', 'Updated description');

    my $custom = Logic::Relational::Program->new(
        name        => 'CustomKB',
        version     => '2.0.1',
        description => 'Custom logic engine',
    );
    is($custom->name,            'CustomKB',            'Constructor sets name');
    is($custom->program_version, '2.0.1',               'Constructor sets version');
    is($custom->description,     'Custom logic engine', 'Constructor sets description');
};

# -----------------------------------------------------------------------------
# 2. Predicate Metadata Registration & Normalization
# -----------------------------------------------------------------------------
subtest 'Predicate metadata registration variations' => sub {
    my $prog = Logic::Relational::Program->new();

    # Form A: name, arity, hashref
    my $k1 = $prog->set_predicate_metadata(
        'parent', 2,
        {
            doc             => 'Relates parent to child',
            args            => ['parent', 'child'],
            ground_required => [0],
        }
    );
    is($k1, 'parent/2', 'Normalized key is parent/2');

    my $m1 = $prog->predicate_metadata('parent', 2);
    is($m1->{doc}, 'Relates parent to child', 'Doc preserved');
    is(
        $m1->{args},
        [{ name => 'parent' }, { name => 'child' }],
        'String args normalized to array of hashrefs'
    );
    is($m1->{ground_required}, [0], 'ground_required preserved');

    # Form B: name/arity, hashref
    my $k2 = $prog->set_predicate_metadata(
        'treats/2',
        {
            description => 'Acupoint treats indication',
            args        => [
                { name => 'point',      type => 'acupoint_code' },
                { name => 'indication', type => 'string' },
            ],
        }
    );
    is($k2, 'treats/2', 'name/arity key accepted');
    my $m2 = $prog->predicate_metadata('treats/2');
    is($m2->{args}[0]{type}, 'acupoint_code', 'Custom argument types preserved');

    # Form C: name with inferred arity from args
    my $k3 = $prog->set_predicate_metadata(
        'near',
        {
            doc  => 'Points near each other',
            args => ['p1', 'p2'],
        }
    );
    is($k3, 'near/2', 'Arity inferred from args array length');

    # Wildcard lookup fallback
    $prog->set_predicate_metadata(
        'wildcard_pred',
        {
            doc => 'Wildcard metadata',
        }
    );
    my $mw = $prog->predicate_metadata('wildcard_pred', 3);
    ok(defined $mw, 'Wildcard lookup succeeds for arbitrary arity');
    is($mw->{doc}, 'Wildcard metadata', 'Wildcard doc retrieved');
};

# -----------------------------------------------------------------------------
# 3. Auto-Reflection & Describe on Programmatic Knowledge Base
# -----------------------------------------------------------------------------
subtest 'describe() auto-reflection of facts, rules, generators, and tabling' => sub {
    my $prog = Logic::Relational::Program->new(
        name        => 'HospitalKB',
        version     => '1.5.0',
        description => 'Hospital patients and staff',
    );

    # Extensional facts (kind: fact, mutable: true)
    $prog->fact(patient => 'Alice', 'Room101');
    $prog->fact(patient => 'Bob',   'Room102');

    # Intensional rule (kind: rule, mutable: false)
    my $p = variable('P');
    my $r = variable('R');
    $prog->rule(
        head => call(in_room => $p, $r),
        body => call(patient => $p, $r),
    );

    # Tabled rule (tabled: true)
    $prog->table('reachable/2');
    my $x = variable('X');
    my $y = variable('Y');
    $prog->rule(
        head => call(reachable => $x, $y),
        body => call(patient   => $x, $y),
    );

    # Generator (kind: generator, mutable: false)
    $prog->generator(
        nurse_on_duty => 2,
        sub ($shift, $nurse) {
            return sub {return ()};
        }
    );

    # Explicit metadata for patient/2
    $prog->set_predicate_metadata(
        'patient/2',
        {
            doc  => 'Patient name and room assignment',
            args => ['patient_name', 'room_id'],
        }
    );

    my $desc = $prog->describe();

    is($desc->{name},        'HospitalKB',                  'Schema name matches');
    is($desc->{version},     '1.5.0',                       'Schema version matches');
    is($desc->{description}, 'Hospital patients and staff', 'Schema description matches');

    my %by_key = map {("$_->{name}/$_->{arity}" => $_)} @{ $desc->{predicates} };

    # Check patient/2 (facts)
    ok(exists $by_key{'patient/2'}, 'patient/2 discovered');
    is($by_key{'patient/2'}{kind},    'fact',            'patient/2 is fact');
    is($by_key{'patient/2'}{mutable}, JSON::PP::true(),  'facts are mutable');
    is($by_key{'patient/2'}{tabled},  JSON::PP::false(), 'patient/2 not tabled');
    is(
        $by_key{'patient/2'}{description},
        'Patient name and room assignment',
        'patient/2 doc present'
    );
    is($by_key{'patient/2'}{args}[0]{name}, 'patient_name', 'Custom arg name used');

    # Check in_room/2 (rule)
    ok(exists $by_key{'in_room/2'}, 'in_room/2 discovered');
    is($by_key{'in_room/2'}{kind},          'rule',            'in_room/2 is rule');
    is($by_key{'in_room/2'}{mutable},       JSON::PP::false(), 'rules are not mutable');
    is($by_key{'in_room/2'}{tabled},        JSON::PP::false(), 'in_room/2 not tabled');
    is($by_key{'in_room/2'}{args}[0]{name}, 'arg0',            'Default arg0 assigned');

    # Check reachable/2 (tabled rule)
    ok(exists $by_key{'reachable/2'}, 'reachable/2 discovered');
    is($by_key{'reachable/2'}{tabled}, JSON::PP::true(), 'reachable/2 is tabled');

    # Check nurse_on_duty/2 (generator)
    ok(exists $by_key{'nurse_on_duty/2'}, 'nurse_on_duty/2 discovered');
    is($by_key{'nurse_on_duty/2'}{kind},    'generator',       'generator identified');
    is($by_key{'nurse_on_duty/2'}{mutable}, JSON::PP::false(), 'generator not mutable');
};

# -----------------------------------------------------------------------------
# 4. StdLib Filtering with include_stdlib
# -----------------------------------------------------------------------------
subtest 'StdLib predicates and include_stdlib filtering' => sub {
    my $prog = Logic::Relational::Program->new();
    require Logic::Relational::StdLib;
    Logic::Relational::StdLib::export_to_program($prog);

    $prog->fact(custom_fact => 1);

    my $desc_all  = $prog->describe(include_stdlib => 1);
    my %preds_all = map {("$_->{name}/$_->{arity}" => $_)} @{ $desc_all->{predicates} };

    ok(exists $preds_all{'append/3'}, 'append/3 present in full describe');
    ok(exists $preds_all{'member/2'}, 'member/2 present in full describe');
    is($preds_all{'append/3'}{builtin}, JSON::PP::true(), 'append/3 marked builtin');
    ok(exists $preds_all{'custom_fact/1'}, 'custom_fact/1 present');
    is($preds_all{'custom_fact/1'}{builtin}, JSON::PP::false(), 'custom_fact/1 not builtin');

    # Filter out stdlib
    my $desc_user  = $prog->describe(include_stdlib => 0);
    my %preds_user = map {("$_->{name}/$_->{arity}" => $_)} @{ $desc_user->{predicates} };

    ok(!exists $preds_user{'append/3'},     'append/3 excluded when include_stdlib=0');
    ok(!exists $preds_user{'member/2'},     'member/2 excluded when include_stdlib=0');
    ok(exists $preds_user{'custom_fact/1'}, 'custom_fact/1 retained when include_stdlib=0');
};

# -----------------------------------------------------------------------------
# 5. Declarative Syntax Integration (Logic::Relational::Syntax)
# -----------------------------------------------------------------------------
logic MedicalRecords {
    description 'Hospital clinical records and diagnostic logic';
    program_version '3.2.1';

    predicate diagnosis => (
        doc             => 'Clinical diagnosis for a patient',
        args            => ['patient_id', 'condition'],
        ground_required => [0],
    );

    predicate 'prescribed/3' => (
        doc  => 'Medication prescription details',
        args => [
            { name => 'patient_id', type => 'string' },
            { name => 'drug_name',  type => 'string' },
            { name => 'dosage_mg',  type => 'integer' },
        ],
    );

    table high_risk;

    fact diagnosis('P001', 'Hypertension');
    fact diagnosis('P002', 'Asthma');
    fact prescribed('P001', 'Lisinopril', 10);

    rule high_risk($p) {
        diagnosis($p, 'Hypertension');
    }
}

subtest 'Syntax extensions: logic, description, program_version, predicate' => sub {
    my $prog = MedicalRecords->program;
    ok(defined $prog, 'MedicalRecords->program returns Logic::Relational::Program');
    is($prog->name, 'MedicalRecords', 'Package name automatically applied as program name');
    is(
        $prog->description,
        'Hospital clinical records and diagnostic logic',
        'description keyword populated program description'
    );
    is($prog->program_version, '3.2.1', 'program_version keyword populated version');

    my $desc = MedicalRecords->describe(include_stdlib => 0);
    is($desc->{name},    'MedicalRecords', 'describe name correct');
    is($desc->{version}, '3.2.1',          'describe version correct');
    is(
        $desc->{description},
        'Hospital clinical records and diagnostic logic',
        'describe desc correct'
    );

    my %preds = map {("$_->{name}/$_->{arity}" => $_)} @{ $desc->{predicates} };

    ok(exists $preds{'diagnosis/2'}, 'diagnosis/2 found in describe');
    is($preds{'diagnosis/2'}{description}, 'Clinical diagnosis for a patient', 'diagnosis/2 doc');
    is($preds{'diagnosis/2'}{ground_required}, [0],    'diagnosis/2 ground_required');
    is($preds{'diagnosis/2'}{kind},            'fact', 'diagnosis/2 is fact');

    ok(exists $preds{'prescribed/3'}, 'prescribed/3 found in describe');
    is($preds{'prescribed/3'}{args}[2]{name}, 'dosage_mg', 'prescribed/3 dosage_mg arg name');
    is($preds{'prescribed/3'}{args}[2]{type}, 'integer',   'prescribed/3 dosage_mg arg type');

    ok(exists $preds{'high_risk/1'}, 'high_risk/1 found in describe');
    is($preds{'high_risk/1'}{kind},   'rule',           'high_risk/1 is rule');
    is($preds{'high_risk/1'}{tabled}, JSON::PP::true(), 'high_risk/1 is tabled');
};

# -----------------------------------------------------------------------------
# 6. Snapshot Serialization and Metadata Persistence
# -----------------------------------------------------------------------------
subtest 'Snapshot save and load preserves program metadata and predicate descriptions' => sub {
    my $source = Logic::Relational::Program->new(
        name        => 'SnapshotSource',
        version     => '4.0.0',
        description => 'KB to be serialized',
    );
    $source->fact(item => 'A', 10);
    $source->set_predicate_metadata(
        'item/2',
        {
            doc  => 'Inventory items and quantities',
            args => ['sku', 'qty'],
        }
    );

    my $snapshot_json;
    $source->save_snapshot(\$snapshot_json);
    ok(length($snapshot_json) > 0, 'Snapshot serialized to string');

    my $restored = Logic::Relational::Program->new();
    $restored->load_snapshot(\$snapshot_json);

    is($restored->name,            'SnapshotSource',      'Restored program name');
    is($restored->program_version, '4.0.0',               'Restored user version');
    is($restored->description,     'KB to be serialized', 'Restored description');

    my $meta = $restored->predicate_metadata('item/2');
    ok(defined $meta, 'item/2 metadata restored');
    is($meta->{doc}, 'Inventory items and quantities', 'item/2 doc preserved across snapshot');
    is($meta->{args}[0]{name}, 'sku',                  'item/2 sku arg name preserved');
};

done_testing();
