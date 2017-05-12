# -*- perl -*-

use strict;
$^W = 1;

use ExtUtils::MakeMaker;
use Getopt::Long ();


use lib "lib";
use vars qw($cfg);


use vars qw($debug $config);
Getopt::Long::GetOptions('debug' => \$debug, 'config' => \$config);
# Make sure a Makefile is generated, so that the CPAN module
# can detect dependencies.
eval {
    require HTML::EP::Explorer::Install;
    $cfg = HTML::EP::Explorer::Install->new();
    $cfg->Save("lib/HTML/EP/Explorer/Config.pm");
};
my $status = $@;

my %opts = (
    'NAME'	=> 'HTML-EP-Explorer',
    'dist'      => { SUFFIX   => '.gz', DIST_DEFAULT => 'all tardist',
                     COMPRESS => 'gzip -9vf' },
    'VERSION_FROM' => 'lib/HTML/EP/Explorer.pm',
    'clean' => { FILES => 'lib/HTML/EP/Explorer/Config.pm' },
);


if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{'AUTHOR'} = 'Jochen Wiedmann (joe@ispsoft.de)';
    $opts{'PREREQ_PM'} = { 'HTML::EP' => 0.2003,
			   'Data::Dumper' => 0};
    $opts{'ABSTRACT'} = 'Web driven browsing of a filesystem';
}

WriteMakefile(%opts);

if ($status) {
    die $status;
}


package MY;

sub libscan { my($self, $path) = @_; ($path =~ /\~$/) ? undef : $path }

sub postamble {
    my $postamble = <<"END_OF_POSTAMBLE";

pm_to_blib: README

README: lib/HTML/EP/Explorer.pm
\tperldoc -t lib/HTML/EP/Explorer.pm >README

END_OF_POSTAMBLE

    $postamble .= <<"END_OF_POSTAMBLE" if ($main::cfg->{'install_html_files'});

install ::
\t\$(PERL) -I\$(INST_ARCHLIB) -I\$(INST_LIB) -MHTML::EP::Explorer::Install -e Install

END_OF_POSTAMBLE
    return $postamble;
}
