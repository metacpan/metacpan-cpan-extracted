use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

sub MY::postamble {
  return <<'MAKE_FRAG';
readme :
	@command -v pod2markdown >/dev/null 2>&1 || (echo "pod2markdown not found (install Pod::Markdown)" && exit 1)
	pod2markdown lib/Google/GeoCoder/Smart.pm > README.md
MAKE_FRAG
}

my $module_file    = 'lib/Google/GeoCoder/Smart.pm';
my $module_version = MM->parse_version($module_file);

WriteMakefile(
  NAME             => 'Google::GeoCoder::Smart',
  VERSION_FROM     => $module_file,                      # finds $VERSION
  MIN_PERL_VERSION => '5.010000',
  LICENSE          => 'perl',
  PREREQ_PM        => {
    'HTTP::Tiny'  => '0',
    'JSON::PP'    => '0',
    'URI::Escape' => '0',
  },
  TEST_REQUIRES => {
    'Test2::V0' => '0',
  },
  META_MERGE => {
    resources => {
      repository => 'https://github.com/ttgrules/Google-Geocoder-Smart',
    },
    provides => {
      'Google::GeoCoder::Smart' => {
        file    => $module_file,
        version => $module_version,
      },
    },
  },
  ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
    (ABSTRACT_FROM => $module_file,    # retrieve abstract from module
      AUTHOR       => 'TTG <ttg@cpan.org>') : ()),
  LIBS   => [''],    # e.g., '-lm'
  DEFINE => '',      # e.g., '-DHAVE_SOMETHING'
  INC    => '-I.',   # e.g., '-I. -I/usr/include/other'
  # Un-comment this if you add C files to link with later:
  # OBJECT            => '$(O_FILES)', # link all the C files too
);
