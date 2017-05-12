require 5.005;
use ExtUtils::MakeMaker;

sub MY::libscan {
  my($self,$path) = @_;

  return '' if ($path =~ /windows_install/
		|| $path =~ /fixpath/
		);

  $path;
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'HTML::WebMake',
    'VERSION_FROM' => 'lib/HTML/WebMake.pm', # finds $VERSION

    'EXE_FILES'	=> ['webmake', 'webmake_cvs_import'],

    'PMLIBDIRS' => [ 'lib' ],

    'PREREQ_PM' => {
      			'File::Spec' => 0,
			'Text::EtText' => 0,
		  },

    'dist' => { COMPRESS => 'gzip -9f', SUFFIX => 'gz',
	      DIST_DEFAULT => 'tardist' },

    'clean' => { FILES =>
	't/log t/.webmake doc/.webmake examples/.webmake pod2html* '.
	'examples/*html WebMake.spec doc/pod2html* webmake webmake.cgi wmview.cgi'
    },

    'AUTHOR' => 'Justin Mason <jm@jmason.org>',
    'ABSTRACT' => 'A simple CMS with templating and metadata'

);

package MY;

sub postamble {
  q{

pm_to_blib: webmake webmake.cgi wmview.cgi

webmake: webmake.raw
	$(PERL) fixpath.pl webmake.raw $@
	$(CHMOD) $(PERM_RWX) $@

webmake.cgi: webmake_cgi.raw
	$(PERL) fixpath.pl webmake_cgi.raw $@
	$(CHMOD) $(PERM_RWX) $@

wmview.cgi: wmview_cgi.raw
	$(PERL) fixpath.pl wmview_cgi.raw $@
	$(CHMOD) $(PERM_RWX) $@

  };
}

