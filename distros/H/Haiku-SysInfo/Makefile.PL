use strict;
use ExtUtils::MakeMaker;

$^O eq 'haiku'
  or die "OS unsupported: This is only for Haiku-OS\n";

my %opts = 
  (
   NAME => 'Haiku::SysInfo',
   VERSION_FROM => 'lib/Haiku/SysInfo.pm',
   OBJECT => 'SysInfo.o',
   PREREQ_PM =>
   {
    'Test::More' => '0.47',
    XSLoader => 0,
   },
  );
my $eu_mmv = eval $ExtUtils::MakeMaker::VERSION;
if ($eu_mmv > 6.06) {
  $opts{AUTHOR} = 'Tony Cook <tonyc@cpan.org>';
  $opts{ABSTRACT} = 'System information for Haiku-OS';
}
if ($eu_mmv > 6.30) {
  $opts{LICENSE} = 'perl';
}

WriteMakefile(%opts);
