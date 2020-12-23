# -*- perl -*-
use ExtUtils::MakeMaker;

$is_devel_host = defined $ENV{USER} && $ENV{USER} eq 'eserte' && ($^O =~ /bsd/i || $ENV{PERL_RELEASE_READY}) && -f "../../perl.release.mk";
$eumm_recent_enough = $ExtUtils::MakeMaker::VERSION >= 6.54;

if (!$eumm_recent_enough) {
    *MY::dist_core = sub {
	<<'EOF';
dist :
	$(NOECHO) $(ECHO) "Sorry, use a newer EUMM!"

EOF
    };
}

my $repo = 'eserte/graphviz-makefile';
WriteMakefile(
  NAME => 'GraphViz::Makefile',
  VERSION_FROM	=> 'lib/GraphViz/Makefile.pm',
  EXE_FILES => [ glob 'scripts/*' ],
  PREREQ_PM => {
    'GraphViz2' => '2.62', # fixed label-quoting
    'Make' => '2.009', # Make.as_graph with recursive_makes
    'Graph' => '0.9708', # rename_vertex method
  },
  TEST_REQUIRES => {
    'Test::More' => '1.001002',
    'Test::Snapshot' => '0.06',
  },
  LICENSE => 'perl',
  MIN_PERL_VERSION => '5.008008', # GraphViz2
  ABSTRACT_FROM => 'lib/GraphViz/Makefile.pm', # retrieve abstract from module
  AUTHOR => 'Slaven Rezic <srezic@cpan.org>',
  (!$eumm_recent_enough ? () : (META_MERGE => {
    "meta-spec" => { version => 2 },
    dynamic_config => 0,
    resources => {
      x_IRC => 'irc://irc.perl.org/#graphql-perl',
      repository => {
        type => 'git',
        url => "git\@github.com:$repo.git",
        web => "https://github.com/$repo",
      },
      bugtracker  => {
        web => "https://github.com/$repo/issues",
      },
      license => [ 'http://dev.perl.org/licenses/' ],
    },
    prereqs => {
      runtime => {
        recommends => {
          'Tk::GraphViz' => '1.08', # scrollTo
        },
      },
    },
  })),
);

sub MY::postamble {
    my $postamble = '';

    if ($is_devel_host) {
	$postamble .= <<'EOF';

PERL_TEST_DISTRIBUTION_OPTS=not podcover

.include "../../perl.release.mk"
.include "../../perl.git.mk"

EOF
    }

    $postamble;
}
