use 5.008008;
use strict;
use warnings;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Finance::Quote::Moex',
    VERSION_FROM      => 'lib/Finance/Quote/Moex.pm', 
    PREREQ_PM         => { 'Finance::Quote' => 0 },
      ($] >= 5.005 ?     
      (ABSTRACT_FROM  => 'lib/Finance/Quote/Moex.pm', # retrieve abstract from module
       AUTHOR         => 'Partizand <partizand@gmail.com>') : ()),
); 

#, 'LWP::UserAgent' => 0, 'HTTP::Request::Common' => 0
