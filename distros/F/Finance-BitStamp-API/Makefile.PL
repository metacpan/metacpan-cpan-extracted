use 5.014002;
use ExtUtils::MakeMaker;

use constant NAME             => 'Finance::BitStamp::API';
use constant VERSION_FROM     => 'lib/Finance/BitStamp/API.pm';
use constant PREREQ_PM        => {};
use constant KEYWORD_VERSION  => '5.005';
use constant ABSTRACTION_FROM => 'lib/Finance/BitStamp/API.pm';
use constant AUTHOR           => 'Jeff Anderson <peawormsworth@gmail.com>';

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => NAME,
    VERSION_FROM => VERSION_FROM,
    # e.g., Module::Name => 1.1
    PREREQ_PM    => PREREQ_PM,
    ($] >= KEYWORD_VERSION ? (ABSTRACT_FROM  => ABSTRACT_FROM, AUTHOR => AUTHOR) : ()),
);
