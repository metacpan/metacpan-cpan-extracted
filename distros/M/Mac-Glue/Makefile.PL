#!perl
use strict;
use warnings;

use ExtUtils::MakeMaker;
use File::Basename;
use File::Spec::Functions;

my @scripts = map { catfile(curdir(), 'scripts', $_) }
	qw(gluedialect gluedoc glueedit gluemac gluescriptadds);
my %scripts = map { ("$_.PL" => $_) } @scripts;

WriteMakefile(
	'NAME'			=> 'Mac::Glue',
	'VERSION_FROM'		=> 'Glue.pm',
	'PL_FILES'		=> \%scripts,
	'EXE_FILES'		=> \@scripts,
	'MAN1PODS'		=> {},
	'PREREQ_PM'	=> {
		'Mac::Errors'                => 0.91,
		'Mac::Apps::Launch'          => 1.92,
		'Mac::AppleEvents::Simple'   => 1.18,
		'Mac::Carbon'                => 0.77,
		'MLDBM'                      => 0,
		'Storable'                   => 0,
		'Test::More'                 => 0,
		'Time::Epoch'                => 0.02,
# not required, but recommended
#		'Encode'                     => 0,
	},
	'clean'	=> {
		'FILES'	=> "Mac-Glue-* @scripts .makeglues"
	},
	'NO_META'		=> 1,
);

sub MY::postamble {
	return <<'MAKE_FRAG';
.makeglues: $(INST_SCRIPT)/gluedialect $(INST_SCRIPT)/gluescriptadds $(INST_SCRIPT)/gluemac
	@$(PERL) "-I$(INST_LIB)" make_glues "-I$(INST_LIB)" "$(INST_SCRIPT)"
	@$(TOUCH) .makeglues

all :: .makeglues

MAKE_FRAG
}


__END__
