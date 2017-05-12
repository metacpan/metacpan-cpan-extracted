use strict;
use 5.6.0;
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
    NAME              => 'Geo::Coder::Googlev3',
    VERSION_FROM      => 'lib/Geo/Coder/Googlev3.pm',
    PREREQ_PM         => {
	'Encode'		=> 0,
	'JSON::XS'		=> 0,
	'LWP::UserAgent'	=> 0,
	'URI'			=> 0,
    },
    LICENSE	      => 'perl',
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Geo/Coder/Googlev3.pm',
       AUTHOR         => 'Slaven Rezic <srezic@cpan.org>') : ()),
    ($eumm_recent_enough ?
      (META_ADD => { resources => { repository => 'git://github.com/eserte/Geo-Coder-Googlev3.git' } }) : ()),
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
