use 5.00503;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		    => 'File::Locate',
    'VERSION_FROM'	=> 'Locate.pm', 
    'PREREQ_PM'		=> {
	'Test::More' => 0,
    }, 
    ($] >= 5.005 ?    
      (ABSTRACT_FROM => 'Locate.pm', # retrieve abstract from module
       AUTHOR     => 'Tassilo von Parseval ' .
                      '<tassilo.von.parseval@rwth-aachen.de>') : ()),
    'LIBS'		=> [''], 
    'DEFINE'		=> '',
    'INC'		=> '-I.', 
);

if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw());
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'File::Locate',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}
