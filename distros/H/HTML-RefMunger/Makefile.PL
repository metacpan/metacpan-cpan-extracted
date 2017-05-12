###
### Makefile.PL
### 
### Meta-Makefile for HTML::RefMunger
###

BEGIN { require 5.003 }

use ExtUtils::MakeMaker 5.16, qw(WriteMakefile $Verbose);
use Config;

%opts = (
	'NAME'=> 'HTML::RefMunger',
	'VERSION_FROM' => 'RefMunger.pm',
	'EXE_FILES' => [ 'refmunger' ],
	'dist' => { 'COMPRESS' => 'gzip -v -9 -f', 'SUFFIX' => '.gz' },
  );

warn <<EOM;

EOM

WriteMakefile( %opts );

warn <<EOM;

    To read this module, type:

        make install

    and if this is successful, read the instructions by typing:

        perldoc refmunger

EOM

exit;

__END__
