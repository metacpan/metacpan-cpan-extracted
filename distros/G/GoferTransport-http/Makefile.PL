use strict;
use warnings;
use ExtUtils::MakeMaker;

unless (eval { require Apache::Constants }
     or eval { require Apache2::Const    }) {
    warn "Can't load Apache::Constants or Apache2::Const module.\n";
    exit 0 if $ENV{AUTOMATED_TESTING} or $ENV{PERL5_CPAN_IS_RUNNING}; # cpan-testers
}

WriteMakefile(
    VERSION             => '1.017', # XXX update lib/DB?/Gofer/Transport/*pm
    NAME                => 'GoferTransport-http',
    AUTHOR              => 'Tim Bunce <Tim.Bunce@pobox.com>',
    ABSTRACT            => 'HTTP transport for DBI stateless proxy driver DBD::Gofer',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'    => 0,
        DBI             => 1.605,
        URI             => 0,
        'LWP::UserAgent'=> 0,
        'HTTP::Request' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'GoferTransport-http-*' },
);


sub MY::post_constants {
    # Because http and mod_perl were first released as part of the DBI
    # and the DBI is compiled extension, those old modules would have
    # been installed into the arch-lib directories. So they won't be
    # overwritten by this new install because this a pure perl distibution.
    # So we explicitly delete the files from the various possible arch dirs.
    q{
install :: rm_old_dbi_http
install_perl :: rm_old_dbi_http
install_site :: rm_old_dbi_http
install_vendor :: rm_old_dbi_http

rm_old_dbi_http:
	$(NOECHO) $(RM_F) $(DESTINSTALLARCHLIB)/DBD/Gofer/Transport/http.pm
	$(NOECHO) $(RM_F) $(DESTINSTALLSITEARCH)/DBD/Gofer/Transport/http.pm
	$(NOECHO) $(RM_F) $(DESTINSTALLVENDORARCH)/DBD/Gofer/Transport/http.pm
	$(NOECHO) $(RM_F) $(DESTINSTALLARCHLIB)/DBI/Gofer/Transport/mod_perl.pm
	$(NOECHO) $(RM_F) $(DESTINSTALLSITEARCH)/DBI/Gofer/Transport/mod_perl.pm
	$(NOECHO) $(RM_F) $(DESTINSTALLVENDORARCH)/DBI/Gofer/Transport/mod_perl.pm

checkkeywords:
	$(RM_RF) blib
	find . -type f \( -name .svn -prune -o -name \*.pm -o -name \*.PL -o -name \*.pl \) \
	    -exec bash -c '[ -z "$$(svn pg svn:keywords {})" ] && echo svn propset svn:keywords \"Id Revision\" {}' \;

checkpod:
	$(RM_RF) blib
	find . -type f \( -name .svn -prune -o -name \*.pm -o -name \*.PL -o -name \*.pl \) \
	    -exec podchecker {} \; 2>&1 | grep -v "pod syntax OK"
}
}
