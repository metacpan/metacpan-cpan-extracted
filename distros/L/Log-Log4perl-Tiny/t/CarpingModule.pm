package CarpingModule;
use Log::Log4perl::Tiny qw< :easy :dead_if_first >;
sub somesub {
   LOGCARP "sent from somesub in " . __PACKAGE__;
   anothersub();
}
sub anothersub {
   LOGCROAK "sent from anothersub in " . __PACKAGE__;
}
1;

