package Device::ISDN::OCLM::UserAgent;

#
# Translates 'POST' redirects into 'GET'
#

use strict;

require LWP::UserAgent;

use vars qw (@ISA $VERSION);

$VERSION = "0.40";
@ISA = qw (LWP::UserAgent);

sub
redirect_ok
{
  my ($self, $request) = @_;

  if ($request->method eq 'POST') {
    $request->method ('GET');
  }

  1;
}
