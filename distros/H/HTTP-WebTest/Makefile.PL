# $Id: Makefile.PL,v 1.16 2003/04/26 15:17:20 m_ilya Exp $

use 5.005;

use strict;

use ExtUtils::MakeMaker;
use File::Spec;

# list of authors
my $AUTHOR = 'Richard Anderson <richard@richard-anderson.org>, ' .
             'Ilya Martynov <ilya@martynov.org>';

WriteMakefile( NAME         => 'HTTP::WebTest',
	       VERSION_FROM => 'lib/HTTP/WebTest.pm.in',
	       PREREQ_PM    => { 'Algorithm::Diff'       => 0,
				 'CGI::Cookie'           => 0,
				 'LWP'                   => 5.60,
				 'MIME::Base64'          => 0,
				 'Net::SMTP'             => 0,
				 'Text::Balanced'        => 0,
				 'Pod::Usage'            => 0,
				 'Pod::Man'              => 1.14,
				 'Time::HiRes'           => 0,
                                 'Test::Builder::Tester' => 0,
                                 'Test::MockObject'      => 0.07,
                                 'Test::More'            => 0,
				 'URI'                   => 0 },
	       EXE_FILES    => [ File::Spec->catfile(qw(bin wt)) ],
	       AUTHOR       => $AUTHOR,
	       ABSTRACT     => 'Testing static and dynamic web content');

package MY;

sub libscan {
    my $self = shift;
    my $path = shift;

    # ignore backup files
    return undef if $path =~ /~/;

    return $self->SUPER::libscan($path);
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

    # add pod merge target
    my $webtest_pm = File::Spec->catfile(qw(lib HTTP WebTest.pm));
    my $pod_merge_pl = File::Spec->catfile(qw(scripts pod_merge.PL));
    $make .= <<MAKE;

# we are lacking dependencies on plugin POD files yet
$webtest_pm : $webtest_pm.in $pod_merge_pl
\t\$(PERL) $pod_merge_pl lib $webtest_pm.in $webtest_pm
MAKE

    # add README generation target
    my $make_readme_pl = File::Spec->catfile(qw(scripts make_readme.PL));
    $make .= <<MAKE;

README: $webtest_pm $make_readme_pl
\t\$(PERL) $make_readme_pl $webtest_pm README
MAKE

    # add distprepare target (dist target depends on it)
    $make .= <<MAKE;

distprepare :: README
\t\@\$(NOOP)

distprepare :: $webtest_pm
\t\@\$(NOOP)
MAKE

    return $make;
}
