# -*- perl -*-
use ExtUtils::MakeMaker;

$is_devel_host = defined $ENV{USER} && $ENV{USER} eq 'eserte' && $^O =~ /bsd/i && -f "../../perl.release.mk";
$eumm_recent_enough = $ExtUtils::MakeMaker::VERSION >= 6.54;

if (!$eumm_recent_enough) {
    *MY::dist_core = sub {
	<<'EOF';
dist :
	$(NOECHO) $(ECHO) "Sorry, use a newer EUMM!"

EOF
    };
}

WriteMakefile
  (
    NAME		=> 'GraphViz::Makefile',
    VERSION_FROM	=> 'Makefile.pm', # finds $VERSION
    EXE_FILES		=> ['tkgvizmakefile'],
    PREREQ_PM		=> {'GraphViz' => 0, 'Make' => 0},
    LICENSE	      => 'perl',
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'Makefile.pm', # retrieve abstract from module
       AUTHOR         => 'Slaven Rezic <srezic@cpan.org>') : ()),
    ($eumm_recent_enough ?
      (META_ADD => { resources => { repository => 'git://github.com/eserte/graphviz-makefile.git' } }) : ()),
);

sub MY::postamble {
    my $postamble = '';

    if ($is_devel_host) {
	$postamble .= <<'EOF';

.include "../../perl.release.mk"
.include "../../perl.git.mk"

EOF
    }

    $postamble;
}
