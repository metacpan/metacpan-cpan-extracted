package MyApp::MasonPlusSession;

use strict;
use warnings;

use HTML::Mason::ApacheHandler;
# This does not come with the Mason core code.  It must be installed
# from CPAN separately.
use MasonX::Request::PlusApacheSession;

my $ah =
    new HTML::Mason::ApacheHandler
        ( request_class => 'MasonX::Request::PlusApacheSession',
          session_class => 'Apache::Session::File',
          # Let MasonX::Request::PlusApacheSession automatically
          # set and read cookies containing the session id
          session_use_cookie => 1,
          session_directory => '/tmp/sessions',
          session_lock_directory => '/tmp/session-locks',
          comp_root => '<component root>',
          data_dir => '<data directory>' );

sub handler
{
    my ($r) = @_;

    my $status = $ah->handle_request($r);
    return $status;
}

1;


__END__

In your httpd.conf, add something like this:

 PerlRequire MyApp::MasonPlusSession

 <LocationMatch "\.html$">
   SetHandler perl-script
   PerlHandler MyApp::MasonPlusSession
 </LocationMatch>
