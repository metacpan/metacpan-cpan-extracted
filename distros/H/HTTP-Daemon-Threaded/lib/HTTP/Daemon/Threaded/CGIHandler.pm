=pod

=begin classdoc

 Base class for CGIHandler classes.
 Provides an interface definition for the single handleCGI() method.
 <p>
 Copyright&copy 2008, Dean Arnold, Presicient Corp., USA<br>
 All rights reserved.
 <p>
 Licensed under the Academic Free License version 3.0, as specified in the
 License.txt file included in this software package, or at
 <a href='http://www.opensource.org/licenses/afl-3.0.php'>OpenSource.org</a>.

 @author D. Arnold
 @since 2008-03-21
 @self	$self

=end classdoc

=cut

package HTTP::Daemon::Threaded::CGIHandler;

use HTTP::Daemon::Threaded::Logable;
use base qw(HTTP::Daemon::Threaded::Logable);

use strict;
use warnings;

our $VERSION = '0.91';

=pod

=begin classdoc


 Constructor. Stores ContentParams, SessionCache, and Logger objects,
 and performs any content-specific initialization.

 @param LogLevel		<i>(optional)</i> logging level; 1 => errors only; 2 => errors and warnings only; 3 => errors, warnings,
						and info messages; default 1
 @param EventLogger 	<i>(optional)</i> Instance of a HTTP::Daemon::Threaded::Logger to receive
						event notifications (except for web requests)
 @param SessionCache	<i>(optional)</i> threads::shared object implementing HTTP::Daemon::Threaded::SessionCache
 @param ContentParams	<i>(optional)</i> name of a ContentsParam concrete implementation

 @returns a HTTP::Daemon::Threaded::CGIHandler object

=end classdoc

=cut

sub new {
	my ($class, %args) = @_;
	return bless \%args, $class;
}


=pod

=begin classdoc


 Generate and send content. Uses CGI protocol to extract request information
 from either <code>%ENV</code> or the provided <cpan>CGI</cpan> object,
 read additional content from STDIN, and write generated content to STDOUT.
 <p>
 <b.NOTE</b> CGI handlers should <b>NOT</b> <code>exit()</code> here, but
 simply return <i>(ala FastCGI)</i>. In all other respects, this behaves like
 regular CGI protocol. However, be advised that STDOUT is redirected to a scalar
 <i>(via PerlIO :scalar layer)</i> until the complete response is generated, and 
 so the handler should be judicious about the size of content returned. Finally,
 be advised that <code>%ENV</code> has been <code>local</code>'ized; thus,
 any changes to it will <b>not</b> be seen by forked processes.

 @xs
 @param $cgi		<cpan>CGI</cpan> object for the client
 @param $session	<i>(optional)</i> a HTTP::Daemon::Threaded::Session object,
					if the application configured a SessionCache class, and if WebClient
					was able to recover an existing session from such a SessionCache.
=end classdoc

=cut

sub handleCGI {
	my ($self, $cgi, $session) = @_;
}

1;
