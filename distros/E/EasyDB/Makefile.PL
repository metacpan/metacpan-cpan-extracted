
# We really need DBI to work here
require DBI 
or die "You must have DBI installed on this system to use EasyDB\n";

# Currently we only support MySQL as well
require DBD::mysql
or die "You must have DBD::mysql installed on this system to use EasyDB
Further database support will be included in later versions\n";

# Write the makefile
use ExtUtils::MakeMaker;
WriteMakefile( NAME => "EasyDB" );
