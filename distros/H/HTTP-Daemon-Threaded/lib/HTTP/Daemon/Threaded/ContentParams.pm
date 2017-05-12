=pod

=begin classdoc

Abstract base container class for
application specific Content handler parameters.
<p>
Copyright&copy 2006-2008, Dean Arnold, Presicient Corp., USA<br>
All rights reserved.
<p>
Licensed under the Academic Free License version 3.0, as specified at
<a href='http://www.opensource.org/licenses/afl-3.0.php'>OpenSource.org</a>.

@author D. Arnold
@since 2006-08-21
@self	$self



=end classdoc

=cut
package HTTP::Daemon::Threaded::ContentParams;

use strict;
use warnings;

our $VERSION = '0.91';
=pod

=begin classdoc

Constructor. Populates itself with any handler
parameters.

@param $class	name of concrete class
@param @handlerParams	any handler-specific parameters

@return		HTTP::Daemon::Threaded::ContentParams subclass object


=end classdoc

=cut
sub new {
	my $class = shift;
}

1;
