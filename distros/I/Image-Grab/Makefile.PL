use ExtUtils::MakeMaker qw(prompt WriteMakefile);

$r = prompt("Do you want to perform tests\nthat require an active Network connection?", "N");
if(lc(substr($r, 0, 1)) eq 'y' && open(C, ">t/have_network")) {
  print C "ok";
  close C;
} else {
  unlink "t/have_network";
}

sub MY::postamble {
q{
.PHONY: release

index.html: lib/Image/Grab.pm
	pod2html lib/Image/Grab.pm > index.html

release: README index.html $(DISTVNAME).tar$(SUFFIX)
	scp index.html superman.everybody.org:public_html/hacks/perl/Image-Grab/Image-Grab-$(VERSION).html
	scp ChangeLog superman.everybody.org:public_html/hacks/perl/Image-Grab/
	scp $(DISTVNAME).tar.$(SUFFIX) superman.everybody.org:public_html/hacks/perl/Image-Grab/
	ssh superman.everybody.org rm public_html/hacks/perl/Image-Grab/Image-Grab.tar.gz
	ssh superman.everybody.org ln -sf $(DISTVNAME).tar.$(SUFFIX) public_html/hacks/perl/Image-Grab/Image-Grab.tar.gz
	stty -echo
	perl -e 'use LWP::UserAgent;                                     \
		use HTTP::Request::Common qw(POST);                     \
		$$ua = LWP::UserAgent->new;                              \
		print "Password: "; \
		$$pass = <STDIN>; \
                chomp $$pass; \
                print "\n"; sub LWP::UserAgent::get_basic_credentials {("MAHEX", $$pass)}; \
		my $$req = $$ua->request(POST "https://pause.perl.org/pause/authenquery?ACTION=add_uri", \
			[ pause99_add_uri_uri =>                  \
			q{http://mah.everybody.org/hacks/perl/Image-Grab/Image-Grab-$(VERSION).tar.gz}, \
			submit => q{SUBMIT_pause99_add_uri_uri}]); \
		print $$req->as_string;'
	stty echo
}}


WriteMakefile(
    'NAME'	=> 'Image::Grab',
    'VERSION_FROM' => 'lib/Image/Grab.pm',
    'PREREQ_PM' => {Digest::MD5 => 2.07,
		    HTML::TreeBuilder => 0.51,
		    HTTP::Cookies => 0,
		    HTML::HeadParser => 0, # From libwww-perl
		    URI::URL => 1, # From libwww-perl
		    LWP::UserAgent => 0,
		   },
    dist        => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);

