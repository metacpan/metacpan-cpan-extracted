# $Id: Makefile.PL,v 1.2 2002/12/14 20:10:37 m_ilya Exp $

use 5.005;

use strict;

use ExtUtils::MakeMaker;
use File::Spec;

my $VERSION_FROM = File::Spec->catfile(qw(lib HTTP WebTest Plugin Apache.pm));
my $AUTHOR = 'Richard Anderson <richard@richard-anderson.org>, ' .
             'Ilya Martynov <ilya@martynov.org>';
my $ABSTRACT = 'HTTP::WebTest plugin for local web file test mode';

WriteMakefile( NAME         => 'HTTP::WebTest::Plugin::Apache',
	       VERSION_FROM => $VERSION_FROM,
	       PREREQ_PM    => { 'File::Temp'    => 0,
                                 'HTTP::WebTest' => 2.00 },
	       realclean    => { FILES => '.config' },
	       AUTHOR       => $AUTHOR,
	       ABSTRACT     => $ABSTRACT);

package MY;

sub libscan {
    my $self = shift;
    my $path = shift;

    # ignore backup files
    return undef if $path =~ /~/;

    return $self->SUPER::libscan($path);
}

sub test {
    my $self = shift;

    my $make = $self->SUPER::test(@_);

    # add dependencies for test targets
    $make =~ s/(test(?:db)? :: )(.*)/$1test_config $2/g;

    return $make;
}

sub dist_core {
    my $self = shift;

    my $make = $self->SUPER::dist_core();

    # add our hook for dist target
    $make =~ s/^dist : /dist : distprepare /m;

    return $make;
}

sub postamble {
    my $make = '';

    # verify standard input and output are attached to a terminal
    if(-t STDIN and -t STDOUT) {
	$make .= apache_dir_setup();

	print STDOUT "\n";
    }

    # add test_config target (test and testdb targets depend on it)
    my $test_config_pl = File::Spec->catfile(qw(scripts test_config.PL));
    $make .= <<MAKE;

test_config:
\t\$(PERL) $test_config_pl .config
MAKE

    # add README generation target
    my $make_readme_pl = File::Spec->catfile(qw(scripts make_readme.PL));
    my $apache_pm = File::Spec->catfile(qw(lib HTTP WebTest Plugin Apache.pm));
    $make .= <<MAKE;

README: $apache_pm $make_readme_pl
\t\$(PERL) $make_readme_pl $apache_pm README
MAKE

    # add distprepare target (dist target depends on it)
    $make .= <<MAKE;

distprepare :: README
\t\@\$(NOOP)

distprepare :: $apache_pm
\t\@\$(NOOP)
MAKE

    return $make;
}

# asks if http-webtest directory should be installed and adds to
# makefile target to install http-webtest directory if required
sub apache_dir_setup {
    my $apache_dir = undef;

    # verify that we don't run on Win32 system. Local web files
    # test mode is not supported on that platform
    if($^O ne 'MSWin32') {
	while(1) {
	    print_prompt(<<TEXT);

HTTP-WebTest requires installation of the http-webtest directory for
running local file tests. If you do not use local file tests you can
skip installation of this directory.

Install http-webtest directory? [Y/n]:
TEXT

	    my $response = <STDIN>;
	    chomp($response);
	    if($response =~ /^(?:y(?:es)?|)$/i) {
		# user asked for directory installation
		$apache_dir = '/usr/local/etc';

		print_prompt(<<TEXT);

Enter directory that will contain http-webtest directory.

Directory? [$apache_dir]:
TEXT

		my $response = <STDIN>;
		chomp($response);
		$apache_dir = $response if $response;
		last if -d $apache_dir;
		print STDOUT <<TEXT;

ERROR: $apache_dir is not a valid directory
TEXT
	    } else {
		last;
	    }
	}
    }

    my $make = defined $apache_dir ? <<TEXT : '';

pure_install ::
\t-\@\$(CP) -r http-webtest $apache_dir

TEXT

    return $make;
}

sub print_prompt {
    my $text = shift;
    chomp $text;
    print STDOUT $text, ' ';
}
