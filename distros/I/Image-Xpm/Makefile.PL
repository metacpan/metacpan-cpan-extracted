use ExtUtils::MakeMaker;

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
    'NAME'         => 'Image::Xpm',
    'VERSION_FROM' => 'Xpm.pm', # finds $VERSION
    'DISTNAME'     => 'Image-Xpm',
    ($] >= 5.005 ?
        (
            ABSTRACT => 'Load, create, manipulate and save xpm image files.',
            AUTHOR   => 'Mark Summerfield <summer@perlpress.com>',
        ) : () ),
    'LIBS'         => [''],   # e.g., '-lm'
    'DEFINE'       => '',     # e.g., '-DHAVE_SOMETHING'
    'INC'          => '',     # e.g., '-I/usr/include/other'
    'PREREQ_PM'    => { 'Image::Base' => '1.06',
			($] < 5.008001 ? ('IO::String' => 0) : ()),
		      },
    'dist'         => { COMPRESS => "gzip -9", SUFFIX => "gz" },
    ($eumm_recent_enough ?
      (META_ADD => { resources => { repository => 'git://github.com/eserte/image-xpm.git' },
		     author => ['Mark Summerfield <summer@perlpress.com>',
				'Slaven Rezic <srezic@cpan.org',
			       ],
		   },
		MIN_PERL_VERSION => '5.5.0',
		LICENSE          => 'gpl_2') : ()),
) ;

sub MY::postamble {
    my $postamble = '';
    if (defined $ENV{USER} && $ENV{USER} eq 'eserte' && $^O =~ /bsd/i && -f "../../perl.release.mk") {
	$postamble .= <<'EOF';

.include "../../perl.release.mk"
.include "../../perl.git.mk"

EOF
    }

    $postamble;
}
