use strict ;
use ExtUtils::MakeMaker ;

my $is_devel_host = defined $ENV{USER} && $ENV{USER} eq 'eserte' && ($^O =~ /bsd/i || $ENV{PERL_RELEASE_READY}) && -f "../../perl.release.mk";
my $eumm_recent_enough = $ExtUtils::MakeMaker::VERSION >= 6.54 ;

if (!$eumm_recent_enough) {
    *MY::dist_core = sub {
	<<'EOF' ;
dist :
	$(NOECHO) $(ECHO) "Sorry, use a newer EUMM!"

EOF
    } ;
}

WriteMakefile(
    'NAME'         => 'Image::Xbm',
    'VERSION_FROM' => 'Xbm.pm', # finds $VERSION
    'DISTNAME'     => 'Image-Xbm',
    ($] >= 5.005 ?
        (
            ABSTRACT => 'Load, create, manipulate and save xbm image files.',
            AUTHOR   => 'Mark Summerfield <summer@perlpress.com>',
        ) : () ),
    'LIBS'         => [''],   # e.g., '-lm'
    'DEFINE'       => '',     # e.g., '-DHAVE_SOMETHING'
    'INC'          => '',     # e.g., '-I/usr/include/other'
    'PREREQ_PM'    => {
        'Image::Base' => '1.06',
        'Test::More'  => 0,
        'File::Temp'  => 0,
    },
    ($eumm_recent_enough ?
      (META_ADD => { resources => { repository => 'git://github.com/eserte/Image-Xbm.git' } }) : ()),
) ;

sub MY::postamble {
    my $postamble = '' ;

    if ($is_devel_host) {
	$postamble .= <<'EOF' ;

PERL_TEST_DISTRIBUTION_CHANGES=yes

.include "../../perl.release.mk"
.include "../../perl.git.mk"

EOF
    }

    $postamble ;
}
