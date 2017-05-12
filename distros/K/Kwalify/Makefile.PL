use 5.000;
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

WriteMakefile(
    NAME              => 'Kwalify',
    VERSION_FROM      => 'lib/Kwalify.pm',
    PREREQ_PM         => {
	($] < 5.006 ? ('warnings::compat' => 0) : ()),
    },
    EXE_FILES         => ['pkwalify'],
    LICENSE	      => 'perl',
    #NO_META           => 1,
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Kwalify.pm', # retrieve abstract from module
       AUTHOR         => 'Slaven Rezic <srezic@cpan.org>') : ()),
    ($eumm_recent_enough ?
      (META_ADD => { resources => { repository => 'git://github.com/eserte/p5-Kwalify.git' } }) : ()),
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
