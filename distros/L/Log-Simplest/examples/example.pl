#!/usr/bin/perl
# $Id: example.pl 2461 2009-03-20 05:05:25Z dk $
# $Author: dk $
# $Date: 2009-03-20 14:05:25 +0900 (Fri, 20 Mar 2009) $
# $URL: svn://svn/dmytro/Development/perl/modules/Log-Simplest/trunk/examples/example.pl $

# This is example script for Log::Simplest module.

push @INC, ".";

use Log::Simplest;

Log("This is normal log message");

Fatal("After printing this I will die");

__END__

Running this script should produce output similar to:

09/03/18 13:34:26:  *** example *** starting *** 
09/03/18 13:34:26: Log file: /tmp/example.090318:13:34:26.9941.log
09/03/18 13:34:26: This is normal log message
09/03/18 13:34:26: FATAL ERROR: After printing this I will die
FATAL : After printing this I will die at Log/Simplest.pm line 157.
09/03/18 13:34:26:  ***  Closing file /tmp/example.090318:13:34:26.9941.log *** 
09/03/18 13:34:26:  *** example *** Completed *** 

=head1 Example script for Log::Simplest module

=head1 AUTHOR 

Dmytro Kovalov, dmytro.kovalov@gmail.com

=head3 HISTORY

=head4 First public release: March, 2009

Although I have been using this module for quite a while in my
scripts, I have never though about publishing it itn thу wild. Finally
I have decided to write little bit longer POD description and put it
on CPAN.


=cut

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2009 by Dmytro Koval'ov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.





