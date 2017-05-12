use strict;
use ExtUtils::MakeMaker;

my $is_devel_host = defined $ENV{USER} && $ENV{USER} eq 'eserte' && $^O =~ /bsd/i && -f "../../perl.release.mk";

my $eumm_recent_enough = $ExtUtils::MakeMaker::VERSION >= 6.54;
if (!$eumm_recent_enough) {
    *MY::dist_core = sub {
	<<'EOF';
dist :
	$(NOECHO) $(ECHO) "Sorry, use a newer EUMM!"

EOF
    };
}

WriteMakefile(
    NAME         => 'Imager::Image::Base',
    VERSION_FROM => 'lib/Imager/Image/Base.pm',
    PREREQ_PM    => {
	'Imager'     => 0,
	'Image::Xpm' => 0,
	'Image::Xbm' => 0,
    },
    #EXE_FILES => [
    #	'scripts/xpm2png.pl',
    #	'scripts/xbm2png.pl',
    #],
    ($eumm_recent_enough
     ? (META_MERGE => {
	    resources  => {
	        repository => 'git://github.com/eserte/imager-image-base.git' },
	    },
       )
     : ()
    ),
);

sub MY::postamble {
    my $self = shift;
    my @ret;

    if ($is_devel_host) {
	push @ret, <<'EOF';

.include "../../perl.release.mk"
.include "../../perl.git.mk"

EOF
    }

    join "\n", @ret;
}
