use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

sub MY::postamble { 
q|

html_doc:
	rm -r docs
	mkdir docs
	mkdir docs/cgi
	pod2html Site.pm > docs/Site.pm.html
	pod2html Config.pm > docs/Config.pm.html
	pod2html cgi/index.cgi > docs/cgi/index.cgi.html
	pod2html cgi/view_site.cgi > docs/cgi/view_site.cgi.html
	pod2html cgi/edit_site.cgi > docs/cgi/edit_site.cgi.html
	pod2html cgi/new_site.cgi > docs/cgi/new_site.cgi.html
	pod2html cgi/autodetect.cgi > docs/cgi/autodetect.cgi.html
	pod2html cgi/edit_conf.cgi > docs/cgi/edit_conf.cgi.html
	pod2html cgi/proc_tpl.pl > docs/cgi/proc_tpl.pl.html
|;
}

WriteMakefile(
    'NAME'	=> 'HtDig::Config',
    'VERSION_FROM' => 'Config.pm', # finds $VERSION
    'PREREQ_PM' => {'Net::SMTP'=>0, 'Date::Manip'=>0},
);
