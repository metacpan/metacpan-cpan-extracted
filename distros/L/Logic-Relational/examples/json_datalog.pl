#!/usr/bin/env perl

use v5.38;
use feature 'try';
no warnings 'experimental::try';

use lib ('../lib', 'lib');
use JSON::PP ();
use Logic::Relational::Syntax;

# Helper to print formatted section titles
sub print_section ($title) {
    say "\n" . ('=' x 70);
    say "  $title";
    say('=' x 70);
    return;
}

# =============================================================================
# 1. Declare Knowledge Base with Metadata & Docstrings
# =============================================================================
logic HospitalStaffKB {
    description 'Hospital Staffing & Clinical Duty Knowledge Base';
    program_version '1.0.0';

    predicate employee => (
        doc  => 'Active or inactive hospital staff member',
        args => ['name'],
    );

    predicate role => (
        doc  => 'Clinical role classification (doctor, nurse, surgeon)',
        args => ['name', 'title'],
    );

    predicate department => (
        doc  => 'Assigned hospital department (e.g. ICU, Pediatrics, Emergency)',
        args => ['name', 'dept'],
    );

    predicate on_leave => (
        doc  => 'Staff members currently on approved leave and unavailable for duty',
        args => ['name'],
    );

    predicate colleague => (
        doc  => 'Derived relation: two staff members assigned to the same department',
        args => ['person_a', 'person_b'],
    );

    facts {
        employee('Alice');
        employee('Bob');
        employee('Charlie');
        employee('Diana');
        employee('Edward');
        employee('Fiona');

        role('Alice',   'doctor');
        role('Bob',     'doctor');
        role('Charlie', 'nurse');
        role('Diana',   'nurse');
        role('Edward',  'surgeon');
        role('Fiona',   'doctor');

        department('Alice',   'ICU');
        department('Bob',     'Pediatrics');
        department('Charlie', 'ICU');
        department('Diana',   'Emergency');
        department('Edward',  'Surgery');
        department('Fiona',   'ICU');

        on_leave('Bob');
        on_leave('Diana');
    }

    rule colleague($a, $b) {
        fresh my $dept;
        department($a, $dept);
        department($b, $dept);
    }
}

# =============================================================================
# 2. Schema Introspection (describe)
# =============================================================================
print_section('1. Schema Auto-Reflection (describe)');
say 'Inspecting knowledge base schema and predicate catalog (include_stdlib => 0):';

my $schema = HospitalStaffKB->describe(include_stdlib => 0);
say 'Program Name:        ' . $schema->{name};
say 'Program Version:     ' . $schema->{version};
say 'Program Description: ' . $schema->{description};
say "\nDiscovered Domain Predicates:";
for my $p (sort {$a->{name} cmp $b->{name}} @{ $schema->{predicates} }) {
    my $arg_str = join(', ', map {$_->{name}} @{ $p->{args} });
    printf("  - %-12s / %d  args: (%-18s)  [%s]  doc: %s\n",
        $p->{name}, $p->{arity}, $arg_str, $p->{kind}, $p->{description} // '(none)');
}

# =============================================================================
# 3. Conjunctive Query with Projection (select)
# =============================================================================
print_section('2. Positive Conjunctive Query with Projection');
say 'Query: Find all doctors and project their names';

my $query_doctors = {
    goals  => [{ pred => 'role', args => ['$who', 'doctor'] }],
    select => ['$who'],
};

my $res1 = HospitalStaffKB->query_data($query_doctors);
if ($res1->{ok}) {
    say 'Found ' . $res1->{count} . ' doctor(s):';
    for my $row (@{ $res1->{results} }) {
        say '  - ' . $row->{who};
    }
    say 'Execution steps: ' . $res1->{audit}{steps} . ' (' . $res1->{audit}{elapsed_ms} . ' ms)';
}

# =============================================================================
# 4. Multi-Goal Conjunction (Variable Joins)
# =============================================================================
print_section('3. Multi-Goal Conjunction (Variable Joins)');
say 'Query: Find all staff members in the ICU along with their roles';

my $query_icu = {
    goals => [
        { pred => 'department', args => ['$name', 'ICU'] },
        { pred => 'role',       args => ['$name', '$title'] },
    ],
    select => ['$name', '$title'],
};

my $res2 = HospitalStaffKB->query_data($query_icu);
if ($res2->{ok}) {
    say 'ICU Staff:';
    for my $row (@{ $res2->{results} }) {
        printf("  - %-10s (Role: %s)\n", $row->{name}, $row->{title});
    }
}

# =============================================================================
# 5. Negation-as-Failure (NAF)
# =============================================================================
print_section('4. Negation-as-Failure (NAF)');
say 'Query: Find active doctors available for duty (who are NOT on leave)';

my $query_active_doctors = {
    goals => [
        { pred => 'role', args => ['$name', 'doctor'] },
        { not  => { pred => 'on_leave', args => ['$name'] } },
    ],
    select => ['$name'],
};

my $res3 = HospitalStaffKB->query_data($query_active_doctors);
if ($res3->{ok}) {
    say 'Active Doctors:';
    for my $row (@{ $res3->{results} }) {
        say '  - ' . $row->{name} . ' (available)';
    }
}

# =============================================================================
# 6. Safety & Automatic Goal Reordering
# =============================================================================
print_section('5. Safety & Automatic Goal Reordering');
say 'Query: Negated goal specified BEFORE positive goal (e.g. from an LLM)';
say '  Goal 1: not on_leave($name)';
say '  Goal 2: role($name, "nurse")';

my $query_reorder = {
    goals => [
        { not  => { pred => 'on_leave', args => ['$name'] } },
        { pred => 'role', args => ['$name', 'nurse'] },
    ],
    select => ['$name'],
};

my $res4 = HospitalStaffKB->query_data($query_reorder);
if ($res4->{ok}) {
    say 'Planner safely reordered goals to bind $name first:';
    say '  Planned execution order: ' . join(' -> ', @{ $res4->{audit}{planned_goals} });
    say 'Active Nurses:';
    for my $row (@{ $res4->{results} }) {
        say '  - ' . $row->{name};
    }
}

# =============================================================================
# 7. Set Deduplication (distinct) & Limits
# =============================================================================
print_section('6. Set Deduplication (distinct) & Row Limits');
say 'Query: Unique departments derived from all staff members, limited to 3';

my $query_distinct = {
    goals    => [{ pred => 'department', args => ['$_', '$dept'] }],
    select   => ['$dept'],
    distinct => 1,
    limit    => 3,
};

my $res5 = HospitalStaffKB->query_data($query_distinct);
if ($res5->{ok}) {
    say 'Departments (distinct=true, limit=3, truncated='
        . ($res5->{truncated} ? 'true' : 'false') . '):';
    for my $row (@{ $res5->{results} }) {
        say '  - ' . $row->{dept};
    }
}

# =============================================================================
# 8. Raw JSON Interface (query_json)
# =============================================================================
print_section('7. Raw JSON Interface (query_json)');
say 'Simulating an external API/MCP client sending a raw JSON query string:';

my $json_payload = <<'JSON';
{
    "goals": [
        { "pred": "department", "args": ["$person", "ICU"] },
        { "pred": "role",       "args": ["$person", "$role"] }
    ],
    "select": ["$person", "$role"]
}
JSON

say "Input JSON:\n$json_payload";

my $json_response = HospitalStaffKB->query_json($json_payload, pretty => 1);
say "Output JSON Response:\n$json_response";

# =============================================================================
# 9. Safety Error Handling (Unground Negation & Unknown Predicates)
# =============================================================================
print_section('8. Safety & Validation Error Handling');
say 'Testing safety validation: Querying with unground negation';

my $invalid_negation = {
    goals  => [{ not => { pred => 'on_leave', args => ['$ghost'] } }],
    select => ['$ghost'],
};

my $err_res = HospitalStaffKB->query_data($invalid_negation);
say 'Result ok:         ' . $err_res->{ok};
say 'Error Code:        ' . $err_res->{error_code};
say 'Rejection Reason:  ' . $err_res->{error};
