use strict;
use warnings;

use subs qw ( _which );

use Config         qw( %Config );
use File::Basename qw( basename );
use File::Spec     qw();

my ( $blib_lib, $local_lib_root, $local_bin, $local_lib, $prove_rc_file, $t_lib );

BEGIN {
  $blib_lib       = File::Spec->catfile( $ENV{ PWD },     qw( blib lib ) );
  $local_lib_root = File::Spec->catfile( $ENV{ PWD },     'local' );
  $local_bin      = File::Spec->catfile( $local_lib_root, qw( bin ) );
  $local_lib      = File::Spec->catfile( $local_lib_root, qw( lib perl5 ) );
  $prove_rc_file  = File::Spec->catfile( $ENV{ PWD },     qw( t .proverc ) );
  $t_lib          = File::Spec->catfile( $ENV{ PWD },     qw( t lib ) );
}
use lib $local_lib;

# do not use "local" in the following line because then _which() will no see
# the modified PATH
$ENV{ PATH } = ## no critic (RequireLocalizedPunctuationVars)
  exists $ENV{ PATH }
  ? "$local_bin$Config{ path_sep }$ENV{ PATH }"
  : $local_bin; ## no critic (RequireLocalizedPunctuationVars)

{
  no warnings 'once'; ## no critic (ProhibitNoWarnings)
  *MY::postamble = sub {
    my $make_fragment = '';

    $make_fragment .= <<"MAKE_FRAGMENT" if _which 'cpanm';
export PATH := $ENV{ PATH }

ifdef PERL5LIB
  PERL5LIB := @{ [ -d $t_lib ? "$t_lib:" : () ] }$blib_lib:$local_lib:\$(PERL5LIB)
else
  export PERL5LIB := @{ [ -d $t_lib ? "$t_lib:" : () ] }$blib_lib:$local_lib
endif

$local_lib_root: cpanfile
	\$(NOECHO) rm -fr \$@
	\$(NOECHO) cpanm --no-man-pages --local-lib-contained \$@ --installdeps .

.PHONY: installdeps
installdeps: $local_lib_root
MAKE_FRAGMENT

    $make_fragment .= <<"MAKE_FRAGMENT";

# runs the last modified test script
.PHONY: testlm
testlm:
	\$(NOECHO) \$(MAKE) TEST_FILES=\$\$(find t -name '*.t' -printf '%T@ %p\\n' | sort -nr | head -1 | cut -d' ' -f2) test
MAKE_FRAGMENT

    my $prove = _which 'prove';
    $make_fragment .= <<"MAKE_FRAGMENT" if $prove;

# runs test scripts through TAP::Harness (prove) instead of Test::Harness (ExtUtils::MakeMaker)
.PHONY: testp
testp: pure_all
	\$(NOECHO) \$(FULLPERLRUN) $prove\$(if \$(TEST_VERBOSE:0=), --verbose) --norc@{ [ -f $prove_rc_file ? " --rc $prove_rc_file"  : () ] } --recurse --shuffle \$(TEST_FILES)
MAKE_FRAGMENT

    $make_fragment .= <<"MAKE_FRAGMENT" if _which 'cover';

.PHONY: cover
cover:
	\$(NOECHO) cover -test -ignore @{ [ basename( $local_lib_root ) ] } -report vim
MAKE_FRAGMENT

    $make_fragment .= <<"MAKE_FRAGMENT" if _which 'cpantorpm';

# this definition of the CPAN to RPM target does not require that the
# environment variables PERL_MM_OPT, and PERL_MB_OPT are undefined
.PHONY: torpm
torpm: tardist
	\$(NOECHO) cpantorpm --debug --NO-DEPS --install-base $Config{ prefix } --install-type site \$(DISTVNAME).tar\$(SUFFIX)
MAKE_FRAGMENT

    return $make_fragment;
  };
}

sub _which ( $ ) {
  my ( $executable ) = @_;
  for ( split /$Config{ path_sep }/, $ENV{ PATH } ) { ## no critic (RequireExtendedFormatting)
    my $file = File::Spec->catfile( $_, $executable );
    return $file if -x $file;
  }
  return;
}
