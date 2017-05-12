# -*- perl -*-

use ExtUtils::MakeMaker ();
use Getopt::Long ();

use lib "lib";
use vars qw($cfg $debug);

Getopt::Long::GetOptions('debug' => \$debug);


# Make sure a Makefile is generated, so that the CPAN module
# can detect dependencies
eval {
    require HTML::EP::Glimpse::Install;
    $cfg = HTML::EP::Glimpse::Install->new(undef, 1);
    $cfg->Save("lib/HTML/EP/Glimpse/Config.pm");
};
my $status = $@;

my %opts =
( 'NAME' => 'HTML-EP-Glimpse',
  'VERSION_FROM' => 'lib/HTML/EP/Glimpse.pm',
  'dist' =>
  { 'SUFFIX' => '.gz',
    'DIST_DEFAULT' => 'all tardist',
    'COMPRESS' => 'gzip -best -vf',
  },
  'realclean' =>
  { 'FILES' => 'lib/HTML/EP/Glimpse/Config.pm'
  }
);

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{'ABSTRACT'} = 'A simple search engine using Glimpse';
    $opts{'AUTHOR'} = 'Jochen Wiedmann';
    $opts{'PREREQ_PM'} = { 'HTML::EP' => 0.20 };
}

ExtUtils::MakeMaker::WriteMakefile(%opts);

die $status if $status;


package MY;

sub libscan {
    my $self = shift; my $path = shift;
    $path =~ /~$/ ? undef : $path;
}

sub postamble {
    my $pa = qq{

all :: README

README : lib/HTML/EP/Glimpse.pm
\tpod2text lib/HTML/EP/Glimpse.pm >README

};
    $pa .= qq{install ::
\t\$(PERL) -I\$(PERL_ARCHLIB) -I\$(PERL_LIB) -MHTML::EP::Glimpse::Install -e Install

} if $main::cfg->{'install_html_files'};
    $pa;
}
