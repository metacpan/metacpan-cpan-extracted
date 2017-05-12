
package My::MessageAssembler;

use strict;
use warnings 'all';
use base 'Email::Blaster::MessageAssembler';
use Apache2::ASP::Test::Base;

our $asp;

#==============================================================================
sub assemble
{
  my ($s, $blaster, $sendlog, $transmission) = @_;
  
  $asp ||= Apache2::ASP::Test::Base->new();
  
  my $res = $asp->ua->get("/email.asp?sendlog_id=" . $sendlog->id);
  return {
    subject => $transmission->subject,
    content => $res->content,
  };
}# end assemble()

1;# return true:

