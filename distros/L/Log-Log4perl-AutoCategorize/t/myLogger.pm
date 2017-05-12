
package myLogger;
use base 'Log::Log4perl::AutoCategorize';

Log::Log4perl::AutoCategorize
    ->import (
	      debug => 'av',
	      initfile => 'log-conf',
	      );

1;

__END__

