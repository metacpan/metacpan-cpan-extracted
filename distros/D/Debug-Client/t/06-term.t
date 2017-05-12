use strict;
use warnings FATAL => 'all';

use English qw( -no_match_vars );
local $OUTPUT_AUTOFLUSH = 1;

use version;
use Test::More tests => 7;

BEGIN {
	use_ok( 'Term::ReadLine', '1.07' );
}

diag("\nInfo: Perl $PERL_VERSION");
diag("Info: OS $OSNAME");

SKIP: {
	skip 'Skipping Columns & Lines as we are not running on win32', 2 if $OSNAME ne 'MSWin32';
	is( $ENV{COLUMNS}, undef, '$ENV{COLUMS} is undefined' );
	is( $ENV{LINES},   undef, '$ENV{LINES} is undefined' );
}

is( $ENV{PERL_RL}, undef, '$ENV{PERL_RL} is undefined' );

{
	eval 'use Term::ReadLine::Gnu';
	if ($EVAL_ERROR) {
		diag 'Info: Term::ReadLine::Gnu is not installed';
	} else {
		diag 'Info: Term::ReadLine::Gnu installed';
	}
}

SKIP: {
	eval { require Term::ReadLine::Gnu };
	skip 'Term::ReadLine::Gnu not installed', 2 if $EVAL_ERROR;
	use_ok('Term::ReadLine::Gnu');
	cmp_ok(
		version->parse($Term::ReadLine::Gnu::VERSION), 'ge', 0,
		'Term::ReadLine::Gnu version = ' . version->parse($Term::ReadLine::Gnu::VERSION)
	);

}

{
	my $term;
	eval { $term = Term::ReadLine->new('none') };
	if ($EVAL_ERROR) {
		diag 'Warning: If test fail consider installing Term::ReadLine::Gnu' if $OSNAME ne 'MSWin32';
		local $ENV{PERL_RL} = ' ornaments=0';
		diag 'INFO: Setting $ENV{PERL_RL} -> ' . $ENV{PERL_RL};
	} else {
		diag 'Info: Using ReadLine implementation -> ' . $term->ReadLine;
	}
}

# Patch for Debug::Client ticket #831 (MJGARDNER)
# Turn off ReadLine ornaments
##local $ENV{PERL_RL} = ' ornaments=0';
if ( !exists $ENV{TERM} ) {
	if ( $OSNAME eq 'MSWin32' ) {
		$ENV{TERM} = 'dumb';
		diag 'INFO: Setting $ENV{TERM} -> ' . $ENV{TERM};
	} else {
		local $ENV{PERL_RL} = ' ornaments=0';
		diag 'INFO: Setting $ENV{PERL_RL} -> ' . $ENV{PERL_RL};
	}
}

diag 'INFO: $ENV{TERM} -> ' . $ENV{TERM};
ok( $ENV{TERM} !~ /undef/, '$ENV{TERM} is set to -> ' . $ENV{TERM} );


done_testing();

__END__
