#!/usr/bin/env perl

# t/regression.t — Guards against recurrence of specific bugs fixed in this
# codebase.  Each subtest names the defect and the file that was changed.
#
# REG-1  Utils.pm: _normalize/_abbreviate placed after __END__ — never compiled
# REG-2  Utils.pm: _normalize/_abbreviate absent from @EXPORT_OK — explicit
#         import croaked
# REG-3  t/lib/MyLogger.pm (since removed, replaced by Test::Log::Abstraction): error() called itself — deep recursion fatal
# REG-4  admin2.db + Makefile.PL: GB.ENG.G5 had 13 corrupt Tooting rows
#         appended on every Makefile.PL run; non-Linux sort returned Tooting
# REG-5  Local.pm: bare require Geo::Address::Parser died when module absent;
#         eval guard was missing

use strict;
use warnings;

use Test::Most;
use Test::Exception;

use Test::Log::Abstraction;
use Geo::Coder::Free::Local;
use Geo::Coder::Free::Utils;

# One Local object shared across subtests — __DATA__ filehandle is one-shot.
my $LOCAL = Geo::Coder::Free::Local->new();

# -----------------------------------------------------------------------
# REG-1: _normalize and _abbreviate were placed after __END__ in Utils.pm
#         and were therefore never compiled by the Perl parser.
#         perl -c reports "syntax OK" even in this case, so the bug is
#         invisible until the functions are actually called at runtime.
# -----------------------------------------------------------------------
subtest 'REG-1: Utils::_normalize and _abbreviate are compiled and callable' => sub {
	plan tests => 4;

	ok(defined(&Geo::Coder::Free::Utils::_normalize),
		'_normalize sub is defined — was absent when placed after __END__');
	ok(defined(&Geo::Coder::Free::Utils::_abbreviate),
		'_abbreviate sub is defined — was absent when placed after __END__');

	my $n = Geo::Coder::Free::Utils::_normalize('04TH AVENUE');
	ok(defined $n, '_normalize returns a defined value');
	unlike($n, qr/^0/, '_normalize strips leading zeros (04TH → 4TH)');
};

# -----------------------------------------------------------------------
# REG-2: _normalize and _abbreviate were in @EXPORT but not @EXPORT_OK.
#         Exporter allows default export but rejects explicit named import
#         (use Module qw(name)) for symbols absent from @EXPORT_OK.
# -----------------------------------------------------------------------
subtest 'REG-2: explicit import of _normalize and _abbreviate does not croak' => sub {
	plan tests => 2;

	# Before the fix: "\"_normalize\" is not exported by ... module"
	lives_ok {
		Geo::Coder::Free::Utils->import('_normalize');
	} 'explicit import of _normalize succeeds (@EXPORT_OK populated)';

	lives_ok {
		Geo::Coder::Free::Utils->import('_abbreviate');
	} 'explicit import of _abbreviate succeeds (@EXPORT_OK populated)';
};

# -----------------------------------------------------------------------
# REG-3: the old t/lib/MyLogger.pm error() called error(@_) — unconditional self-recursion.
#         Database::Abstraction calls $logger->error() on init failures,
#         which caused the test process to exhaust the call stack on BSD
#         CI runners where the database file was absent.
# -----------------------------------------------------------------------
subtest 'REG-3: error() does not recurse into itself (old MyLogger defect)' => sub {
	plan tests => 2;

	my $logger = Test::Log::Abstraction->new();

	# Before the fix this would die: "Deep recursion on subroutine Test::Log::Abstraction::error"
	lives_ok { $logger->error('test error') }
		'Test::Log::Abstraction::error completes without deep-recursion fatal';

	lives_ok { $logger->error(undef) }
		'Test::Log::Abstraction::error handles undef without croak';
};

# -----------------------------------------------------------------------
# REG-4: Makefile.PL was appending "GB.ENG.G5\tTooting" to admin2.db on
#         every build.  GB.ENG.G5 is Kent's GeoNames admin2 code; Tooting is
#         a South London suburb and has no business under that code.  On BSD/
#         macOS the appended row was returned first, shadowing Kent.
#         Fix: removed the wrong line from the Makefile.PL append block.
#
#         We test two things independently:
#           (a) Makefile.PL source no longer contains the bad append — this
#               is stable regardless of what GeoNames ships for GB.ENG.G5.
#           (b) admin2.db (whether committed or freshly downloaded) has no
#               Tooting entry under GB.ENG.G5; and if the code is present at
#               all, it maps to Kent.
# -----------------------------------------------------------------------
subtest 'REG-4: Makefile.PL no longer appends Tooting under GB.ENG.G5' => sub {
	plan tests => 1;

	open(my $fh, '<', 'Makefile.PL') or BAIL_OUT("Cannot open Makefile.PL: $!");
	my $src = do { local $/; <$fh> };
	close $fh;

	# Match the Perl string-literal form used in print statements:
	#   "GB.ENG.G5\tTooting..."
	# A comment mentioning both names is not a match; the escaped \t is key.
	unlike($src, qr["GB\.ENG\.G5\\tTooting],
		'Makefile.PL source has no GB.ENG.G5/Tooting append (root-cause line removed)');
};

subtest 'REG-4b: admin2.db has no Tooting entry under GB.ENG.G5' => sub {
	my $db = 'lib/Geo/Coder/Free/MaxMind/databases/admin2.db';
	unless(-f $db) {
		plan tests => 1;
		pass('admin2.db not present — skipping data-integrity check');
		return;
	}
	plan tests => 2;

	open(my $fh, '<', $db) or BAIL_OUT("Cannot open $db: $!");
	my @g5 = grep { /^GB\.ENG\.G5\t/ } <$fh>;
	close $fh;

	my @tooting = grep { /Tooting/ } @g5;
	is(scalar @tooting, 0,
		'no Tooting rows under GB.ENG.G5 in admin2.db');

	# If the GeoNames download still carries GB.ENG.G5, verify it is Kent.
	# If the entry is absent from the current upstream data, that is also fine.
	ok(!@g5 || $g5[0] =~ /\tKent\t/,
		'GB.ENG.G5, if present, maps to Kent (not overridden by wrong append)');
};

# -----------------------------------------------------------------------
# REG-5: Local.pm line ~470 called `require Geo::Address::Parser` without
#         an eval guard.  When the optional module is not installed, the bare
#         require propagated "Can't locate ..." as a fatal error even though
#         the unless(->can) guard ran first (it returned false, so the
#         require executed, and it died).
#         Fix: wrapped in eval { require ...; ->import() }.
# -----------------------------------------------------------------------
subtest 'REG-5: missing Geo::Address::Parser does not kill UK geocode' => sub {
	# If the module IS installed, the eval path is never reached; skip gracefully.
	if(eval { require Geo::Address::Parser; 1 }) {
		plan tests => 1;
		pass('Geo::Address::Parser is installed — eval guard path not exercisable here');
		return;
	}
	plan tests => 1;

	# "10 High Street, Canterbury, Kent, England" has 3 commas (4 parts) so it
	# bypasses the early-return guard and reaches the require at line ~470.
	# Before the fix this died: "Can't locate Geo/Address/Parser.pm in @INC"
	lives_ok {
		$LOCAL->geocode(location => '10 High Street, Canterbury, Kent, England');
	} 'UK geocode returns cleanly when Geo::Address::Parser is absent (eval guard)';
};

done_testing();
