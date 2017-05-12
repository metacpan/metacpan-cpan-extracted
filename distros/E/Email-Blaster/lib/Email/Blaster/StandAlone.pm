
package Email::Blaster::StandAlone;

use strict;
use warnings 'all';
use base 'Email::Blaster';


#==============================================================================
sub find_new_transmission
{
  my ($s) = @_;
  
  my $sth = Email::Blaster::Transmission->db_Main->prepare(<<"SQL");
SELECT *
FROM transmissions
WHERE is_queued = 1
AND (
  is_started = 0
)
OR (
  is_started = 1
  AND is_completed = 0
)
ORDER BY queued_on DESC
LIMIT 0, 1
SQL
  $sth->execute();
  return unless my ($trans) = Email::Blaster::Transmission->sth_to_objects( $sth );
  
  return $trans;
}# end find_new_transmission()

1;# return true:

__END__

=pod

=head1 NAME

Email::Blaster::StandAlone - Standalone email blaster.

=head1 DESCRIPTION

Email::Blaster::StandAlone is used by L<sbin/email-blaster-standalone.pl>.

=head1 SUPPORT

Visit L<http://www.devstack.com/contact/> or email the author at <jdrago_999@yahoo.com>

Commercial support and installation is available.

=head1 AUTHOR

John Drago <jdrago_999@yahoo.com>
 
=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by John Drago

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

