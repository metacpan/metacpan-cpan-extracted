package Email::AutoReply::DB;
our $rcsid = '$Id: DB.pm 3002 2008-06-05 20:23:24Z adam $';

use strict;
use warnings;

use Spiffy '-Base';

=head1 NAME

Email::AutoReply::DB - interface defining Email::AutoReply database interaction

=head1 DESCRIPTION

Email::AutoReply keeps track of who it's sent email to and when. Any subclass
of this class can be used for this purpose. Subclassers must implement all
methods.

=head2 METHODS

=over 4

=item B<store>

Store an Email::AutoReply::Recipient in the database.

Input: Takes one argument, a (populated) Email::AutoReply::Recipient object.

Output: none.

=cut

stub 'store';

=item B<fetch>

Fetch an Email::AutoReply::Recipient from the database, if one exists.

Input: Takes one string argument, an email address.

Output: A populated Email::AutoReply::Recipient or 0 if none could be
found matching the given string.

=cut

stub 'fetch';

=item B<fetch_all>

Fetch all Email::AutoReply::Recipient objects from the database, if any exist.

Input: none.

Output: A list of Email::AutoReply::Recipient objects, or zero.

=cut

stub 'fetch_all';

return 1;

__END__

=back

=head1 AUTHOR

Adam Monsen, <haircut@gmail.com>

=head1 SEE ALSO

L<Email::AutoReply>, L<Email::AutoReply::Recipient>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2008 by Adam Monsen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
