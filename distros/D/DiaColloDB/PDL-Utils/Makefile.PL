use PDL::Core::Dev;
use ExtUtils::MakeMaker;
PDL::Core::Dev->import();

my $package = ["pdlutils.pd","Utils","DiaColloDB::PDL::Utils"];
%hash = pdlpp_stdargs($package);

$hash{AUTHOR} = 'Bryan Jurish';
$hash{ABSTRACT} = 'Low-level PDL utilities for DiaColloDB';
$hash{VERSION_FROM} = 'pdlutils.pd';
$hash{LICENSE} = 'perl';

my %prereq = (PDL => 0, 'PDL::CCS'=>'1.23.1', 'PDL::VectorValued'=>'1.0.5');
$hash{PREREQ_PM} = {%prereq};
$hash{CONFIGURE_REQUIRES} = {%prereq};

push(@{$hash{LIBS}}, '-lm');
#$hash{INC} .= '';
$hash{DIR} = [];
#$hash{OBJECT} .= '';
#$hash{realclean}{FILES} .= '*~ *.tmp README.txt';

WriteMakefile(%hash);
sub MY::postamble { pdlpp_postamble($package); }
