# Beware, major cargo-culting below from DBD::SQLite & XML::Parser

# From ExtUtils::MakeMaker 6.48 and DBI 1.43
use 5.006;
use strict;
use ExtUtils::MakeMaker;
use Config;

{
    require ExtUtils::MakeMaker;
    use strict;
    no strict 'refs';

    my $libscan = \&{"ExtUtils::MM_Any::libscan"};
    *{"ExtUtils::MM_Any::libscan"} = sub {
        return '' unless $libscan->(@_);
        return '' if $_[1] =~ /\.sw[p-z]$/;
        return $_[1];
    };
}

if (-e '.screenrc') {
    my $all_from = join '/', 'lib', qw/Diff LibXDiff.pm/;
    `perldoc -tF $all_from > README` if ! -e 'README' || (stat $all_from)[9] > (stat 'README')[9];
}

# Some dependencies need to be more aggressive on Windows
sub WINLIKE () {
	return 1 if $^O eq 'MSWin32';
	return 1 if $^O eq 'cygwin';
	return '';
}

my $xdiff_libpath = $ENV{XDIFF_LIB_PATH};
my $xdiff_incpath = $ENV{XDIFF_INC_PATH};

my @ARGV_;
foreach (@ARGV) {
  if (/^XDIFF_(LIB|INC)_PATH=(.+)/) {
    if ($1 eq 'LIB') {
      $xdiff_libpath = $2;
    }
    else {
      $xdiff_incpath = $2;
    }
  }
  else {
    push(@ARGV_, $_);
  }
}
@ARGV = @ARGV_;

my $use_xdiff_c;
if (not $xdiff_libpath and $] >= 5.006001 and $^O ne 'MSWin32') {

  # User did not specify XDIFF_* so we'll see if something exists on the system

  my $found = 0;
  require ExtUtils::Liblist;        # Buggy before this
  ($xdiff_libpath) = ExtUtils::Liblist->ext('-lxdiff');
  # Test for existence of libxdiff
  my $found = 0;
  foreach (split(/\s+/, $Config{libpth})) {
    if (-f "$_/libxdiff." . $Config{so}) {
      $found = 1;
      last;
    }
  }

  unless ($found) {
    $use_xdiff_c = 1;
    warn <<_END_;
    Could not find LibXDiff installed on your system
    You can download it from:

    http://www.xmailserver.org/xdiff-lib.html

    If it is installed, but in a non-standard directory, then set the
    following options in the environment (ENV) or pass them to Makefile.PL:

        XDIFF_LIB_PATH=...  To set the directory in which to find libxdiff

        XDIFF_INC_PATH=...  To set the directory in which to find xdiff.h

    For now, we'll use a bundle version of LibXDiff
_END_
    }
}

# Make setting optional MakeMaker parameters more readable
sub OPTIONAL {
	return () unless $ExtUtils::MakeMaker::VERSION ge shift;
	return @_;
}

my (@CC_LIBS, @CC_INC, @CC_DEFINE, @O_FILES);

push @O_FILES, 'LibXDiff.o';

if ($use_xdiff_c) {
    push @CC_INC, '-Ixdiff';
    push @CC_DEFINE, '-DNULL=0';
    push @O_FILES, 'xdiff.o'
}
else {
    push @CC_INC, "-I$xdiff_incpath";
    push @CC_LIBS, "-L$xdiff_libpath";
    push @CC_LIBS, '-lxdiff';
}

my @CC_OPTIONS = (
	INC => join( ' ', @CC_INC    ),
	DEFINE => join( ' ', @CC_DEFINE ),
	OBJECT => join( ' ', @O_FILES ),
    @CC_LIBS ?  (LIBS => join( ' ', @CC_LIBS )) : (),
);

WriteMakefile(
	NAME => 'Diff::LibXDiff',
	ABSTRACT => 'Calculate a diff with LibXDiff (via XS)',
	VERSION_FROM => 'lib/Diff/LibXDiff.pm',
	PREREQ_PM => {
		'Test::More' => '0.42',
		'Carp::Clan' => 0,
        'Test::Most' => 0,
	},
	OPTIONAL( '6.48',
		MIN_PERL_VERSION => '5.006',
	),
	OPTIONAL( '6.31',
		LICENSE => 'perl',	
	),
	OPTIONAL( '6.11',
		AUTHOR  => 'Robert Krimen <rkrimen@cpan.org>',
	),
	OPTIONAL( '6.46',
		META_MERGE => {
            configure_requires => {
                'ExtUtils::MakeMaker' => '6.48',
            },
            build_requires => {
                'Test::More' => '0.42',
                'Test::Most' => 0,
            },
            requires => {
                'Carp::Clan' => 0,
            },
            resources => {
                repository => 'http://github.com/robertkrimen/Diff-LibXDiff/tree/master',
            },
			no_index => {
				directory => [ qw{
					t inc util
				} ],
			}
		},
	),
	OPTIMIZE => '-O2',
	clean => {
	},
	PL_FILES => {},
	EXE_FILES => [],
	@CC_OPTIONS,
);

package MY;

use Config;

1;
