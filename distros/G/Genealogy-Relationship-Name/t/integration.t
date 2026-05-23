#!/usr/bin/env perl

# integration.t - end-to-end black-box integration tests for
# Genealogy::Relationship::Name.  Tests multi-method workflows and stateful
# interactions across the entire module, per the POD documentation.

use strict;
use warnings;

use Test::Most;

use Log::Abstraction;
use lib 'lib', '../lib';

BEGIN {
	use_ok('Genealogy::Relationship::Name')
		or BAIL_OUT('Cannot load Genealogy::Relationship::Name');
}

# =========================================================================
# Test 1: Full lifecycle – construct, query, confirm helpers match
# =========================================================================

subtest 'Full lifecycle: construct -> query -> helper validation' => sub {
	plan tests => 11;

	# Step 1: construct
	my $namer = new_ok('Genealogy::Relationship::Name');

	# Step 2: confirm supported languages are what we expect
	my @langs = $namer->supported_languages();
	ok((grep { $_ eq 'en' } @langs), 'en listed as supported');

	# Step 3: confirm known sexes
	my @sexes = $namer->known_sexes();
	ok((grep { $_ eq 'M' } @sexes), 'M is a known sex');
	ok((grep { $_ eq 'F' } @sexes), 'F is a known sex');

	# Step 4: call name() for each language × sex combination
	for my $lang (@langs) {
		my $r = $namer->name(
			steps_to_ancestor   => 1,
			steps_from_ancestor => 1,
			sex                 => 'M',
			language            => $lang,
		);
		ok(defined $r, "name() defined for sibling in '$lang'");
	}
};

# =========================================================================
# Test 2: Stateful default-language use across multiple calls
# =========================================================================

subtest 'Stateful: default language persists across calls' => sub {
	plan tests => 4;

	my $namer = Genealogy::Relationship::Name->new(language => 'fr');

	# Multiple consecutive calls — each should use the fr default
	is($namer->name(steps_to_ancestor => 0, steps_from_ancestor => 1, sex => 'M'),
		'fils',   'Call 1: fr default -> fils');
	is($namer->name(steps_to_ancestor => 1, steps_from_ancestor => 0, sex => 'F'),
		'mere',   'Call 2: fr default -> mere');
	is($namer->name(steps_to_ancestor => 1, steps_from_ancestor => 1, sex => 'M'),
		"fr\N{U+00E8}re",  'Call 3: fr default -> frère');

	# Now override once without changing the stored default
	my $en_r = $namer->name(
		steps_to_ancestor   => 1,
		steps_from_ancestor => 1,
		sex                 => 'M',
		language            => 'en',
	);
	is($en_r, 'brother', 'Per-call en override works without mutating default');
};

# =========================================================================
# Test 3: Cross-language equivalence for gender-neutral terms
# =========================================================================

subtest 'Cross-language: first cousin is gender-neutral in English' => sub {
	plan tests => 2;

	my $namer = Genealogy::Relationship::Name->new();

	my $m = $namer->name(steps_to_ancestor => 2, steps_from_ancestor => 2, sex => 'M');
	my $f = $namer->name(steps_to_ancestor => 2, steps_from_ancestor => 2, sex => 'F');

	is($m, 'first cousin', 'Male first cousin is "first cousin"');
	is($f, 'first cousin', 'Female first cousin is "first cousin"');
};

# =========================================================================
# Test 4: Reciprocal relationship asymmetry
# A->B and B->A use swapped step counts; names need not be the same
# =========================================================================

subtest 'Asymmetry: A-to-B vs B-to-A give different names for uncle/nephew' => sub {
	plan tests => 3;

	my $namer = Genealogy::Relationship::Name->new();

	# From A's viewpoint: A is 1 step up, B is 2 steps down => nephew
	my $a_to_b = $namer->name(steps_to_ancestor => 1, steps_from_ancestor => 2, sex => 'M');

	# From B's viewpoint: B is 2 steps up, A is 1 step down => uncle
	my $b_to_a = $namer->name(steps_to_ancestor => 2, steps_from_ancestor => 1, sex => 'M');

	# uncle and nephew are genuinely different names (true asymmetry)
	isnt($a_to_b, $b_to_a, 'Reciprocal uncle/nephew queries give different names');
	is($a_to_b, 'nephew', 'A->B (1,2) M => nephew');
	is($b_to_a, 'uncle',  'B->A (2,1) M => uncle');

	# Note: first-cousin-once-removed (2,3) and (3,2) are intentionally
	# the same term in English — that is correct genealogical behaviour.
};

# =========================================================================
# Test 5: Symmetry of same-step (cousin) relationships
# =========================================================================

subtest 'Symmetry: equal-step cousin lookups are identical for same sex' => sub {
	plan tests => 3;

	my $namer = Genealogy::Relationship::Name->new();

	# Second cousin: both sides 3 steps
	my $r1 = $namer->name(steps_to_ancestor => 3, steps_from_ancestor => 3, sex => 'M');
	my $r2 = $namer->name(steps_to_ancestor => 3, steps_from_ancestor => 3, sex => 'M');
	is($r1, $r2, 'Repeated call with same args gives same result');

	# Third cousin
	my $r3 = $namer->name(steps_to_ancestor => 4, steps_from_ancestor => 4, sex => 'F');
	is($r3, 'third cousin', '4,4 F => third cousin');

	# Fifth cousin
	my $r4 = $namer->name(steps_to_ancestor => 6, steps_from_ancestor => 6, sex => 'M');
	is($r4, 'fifth cousin', '6,6 M => fifth cousin');
};

# =========================================================================
# Test 6: Integration with supported_languages() — all languages produce
#         a valid result for sibling
# =========================================================================

subtest 'Integration: all supported languages return defined sibling' => sub {
	my $namer = Genealogy::Relationship::Name->new();
	my @langs = $namer->supported_languages();

	plan tests => scalar(@langs) * 2;

	for my $lang (@langs) {
		for my $sex (qw(M F)) {
			my $r = $namer->name(
				steps_to_ancestor   => 1,
				steps_from_ancestor => 1,
				sex                 => $sex,
				language            => $lang,
			);
			ok(defined $r, "sibling defined for lang=$lang sex=$sex");
		}
	}
};

# =========================================================================
# Test 7: Integration with known_sexes() — all sexes produce a result
#         for a known relationship
# =========================================================================

subtest 'Integration: all known_sexes() return defined result' => sub {
	my $namer  = Genealogy::Relationship::Name->new();
	my @sexes  = $namer->known_sexes();

	plan tests => scalar @sexes;

	for my $sex (@sexes) {
		my $r = $namer->name(
			steps_to_ancestor   => 2,
			steps_from_ancestor => 0,
			sex                 => $sex,
		);
		ok(defined $r, "grandparent defined for sex=$sex");
	}
};

# =========================================================================
# Test 8: Construct multiple objects; they do not share state
# =========================================================================

subtest 'Multiple objects share no state' => sub {
	plan tests => 2;

	my $namer_en = Genealogy::Relationship::Name->new(language => 'en');
	my $namer_fr = Genealogy::Relationship::Name->new(language => 'fr');

	is($namer_en->name(steps_to_ancestor => 0, steps_from_ancestor => 1, sex => 'M'),
		'son',  'Object 1 stays English');
	is($namer_fr->name(steps_to_ancestor => 0, steps_from_ancestor => 1, sex => 'M'),
		'fils', 'Object 2 stays French');
};

# =========================================================================
# Test 9: Returned value is usable in string context
# =========================================================================

subtest 'Return value is usable in string operations' => sub {
	plan tests => 3;

	my $namer = Genealogy::Relationship::Name->new();
	my $name  = $namer->name(steps_to_ancestor => 2, steps_from_ancestor => 3, sex => 'F');

	ok(defined $name, 'name is defined');
	ok(length($name) > 0, 'name has length > 0');
	is(lc($name), lc('first cousin once-removed'), 'name matches expected lowercased');
};

# =========================================================================
# Test 10: Step-chain trace through a lineage
# Simulate tracing A->grandchild B and checking each node
# =========================================================================

subtest 'Lineage step-chain trace' => sub {
	plan tests => 5;

	my $namer = Genealogy::Relationship::Name->new();

	# A is the reference person; common ancestor is A's parent (1 step up).
	# B at 0 steps from ancestor = A's parent = father/mother
	# B at 1 step from ancestor = A's sibling
	# B at 2 steps from ancestor = A's nephew/niece
	# B at 3 steps from ancestor = A's great-nephew/great-niece

	is($namer->name(steps_to_ancestor => 1, steps_from_ancestor => 0, sex => 'M'),
		'father', 'trace: step 0 from ancestor = father');
	is($namer->name(steps_to_ancestor => 1, steps_from_ancestor => 1, sex => 'M'),
		'brother', 'trace: step 1 from ancestor = brother');
	is($namer->name(steps_to_ancestor => 1, steps_from_ancestor => 2, sex => 'M'),
		'nephew', 'trace: step 2 from ancestor = nephew');
	is($namer->name(steps_to_ancestor => 1, steps_from_ancestor => 3, sex => 'M'),
		'great-nephew', 'trace: step 3 from ancestor = great-nephew');
	is($namer->name(steps_to_ancestor => 1, steps_from_ancestor => 4, sex => 'M'),
		'great-great-nephew', 'trace: step 4 from ancestor = great-great-nephew');
};




# FakeIndividual: shared fake class for logger+ctx integration tests.
# Defined once here at file scope to avoid "Subroutine redefined" warnings.
{
	no strict 'refs';
	*{'FakeIndividual::as_string'} = sub { $_[0]->{name} };
}

# =========================================================================
# Test 11: Integration with gedcom/ged2site-style complain() pattern
# Simulates the intended usage: on_error dispatches to complain()
# =========================================================================

subtest 'Integration: on_error simulating complain() pattern' => sub {
	plan tests => 4;

	# Simulate a Gedcom::Individual-like person object
	my $person = bless { name => 'Jane Doe' }, 'FakeIndividual';
	my @complaints;

	# Build a namer wired to a complain()-style handler
	my $logger = Log::Abstraction->new(
		logger => sub {
			my $args = $_[0];
			# Replicate complain()'s core behaviour: format person + warning
			my $msg = $args->{person}
				? $args->{person}->as_string() . ': ' . $args->{warning}
				: $args->{warning};
			push @complaints, $msg;
		},
		ctx => $person
	);
	my $namer = Genealogy::Relationship::Name->new(logger => $logger);
	isa_ok($namer, 'Genealogy::Relationship::Name');

	# Normal successful call — no complaints
	my $rel = $namer->name(
		steps_to_ancestor   => 2,
		steps_from_ancestor => 2,
		sex                 => 'F',
		person              => $person,
	);
	is($rel, 'first cousin', 'Successful call returns correct result');
	is(scalar @complaints, 0, 'No complaints on success');

	# Error call with person — handler formats person name into message
	throws_ok {
		my $bad = $namer->name(
			steps_to_ancestor   => undef,
			steps_from_ancestor => 1,
			sex                 => 'M',
			person              => $person,
		)
	} qr/steps_to_ancestor not given/, 'throws error when steps_to_ancestor is not given';
};

# =========================================================================
# Test 12: Full gedcom/ged2site integration pattern with logger + ctx
# =========================================================================

subtest 'Integration: Log::Abstraction logger+ctx simulating gedcom/ged2site complain()' => sub {
	plan tests => 5;

	# Simulate a Gedcom::Individual with as_string()
	my $individual = bless { name => 'Mary Queen of Scots' }, 'FakeIndividual';
	my @complaints;

	# Caller constructs Log::Abstraction with ctx and logger coderef;
	# Name.pm simply calls $logger->error() -- Log::Abstraction handles the rest
	my $la = Log::Abstraction->new(
		logger => sub {
			my $args = shift;
			# Replicate complain(): format person name + warning message
			my $msg = $args->{ctx}
				? $args->{ctx}->as_string() . ': ' . join('', @{$args->{message}})
				: join('', @{$args->{message}});
			push @complaints, {
				message => $msg,
				level   => $args->{level},
				person  => $args->{ctx},
			};
		},
		ctx => $individual,
	);
	my $namer = Genealogy::Relationship::Name->new(logger => $la);
	isa_ok($namer, 'Genealogy::Relationship::Name');

	# Successful call — no complaints, correct result
	my $rel = $namer->name(
		steps_to_ancestor   => 1,
		steps_from_ancestor => 1,
		sex                 => 'F',
	);
	is($rel, 'sister', 'Successful call returns correct result');
	is(scalar @complaints, 0, 'No complaints on success');

	# undef arg — logger is invoked (not validate_strict, which allows undef through)
	eval { $namer->name(steps_to_ancestor => undef, steps_from_ancestor => 1, sex => 'F') };
	ok($@, 'undef arg throws');
	is(scalar @complaints, 1, 'Complaints logged');
};

# =========================================================================
# Test 13: per-call person overrides ctx across multiple calls
# =========================================================================

subtest 'Integration: Log::Abstraction object stored; valid calls unaffected' => sub {
	plan tests => 4;

	my $ctx_person = bless { name => 'Default Person' }, 'FakeIndividual';
	my $la = Log::Abstraction->new(
		logger => sub {},
		ctx    => $ctx_person,
	);
	my $namer = Genealogy::Relationship::Name->new(logger => $la);
	isa_ok($namer, 'Genealogy::Relationship::Name');
	isa_ok($namer->{logger}, 'Log::Abstraction');

	# Successful calls work normally regardless of logger being set
	is($namer->name(steps_to_ancestor => 1, steps_from_ancestor => 1, sex => 'M'),
		'brother', 'Successful call unaffected by logger');
	is($namer->name(steps_to_ancestor => 2, steps_from_ancestor => 0, sex => 'F'),
		'grandmother', 'Second successful call also unaffected');
};

done_testing();
