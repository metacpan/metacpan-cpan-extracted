package Finance::Bank::RBoS;
use strict;
use base qw/ Finance::Bank::Natwest /;
use vars qw/ $VERSION /;

$VERSION = '0.01';

use constant URL_ROOT => 'https://www.rbsdigital.com';


=head1 NAME

Finance::Bank::RBoS - Check your RBoS bank accounts from Perl

=head1 DESCRIPTION

This module provides a rudimentary interface to the RBoS online
banking system at C<https://www.rbsdigital.com/>. You will need
either C<Crypt::SSLeay> or C<IO::Socket::SSL> installed for HTTPS
support to work with LWP.

The interface is identical to that of L<Finance::Bank::Natwest>, so
please look there for how to use the module.

=head1 WARNING

This warning is from Simon Cozens' C<Finance::Bank::LloydsTSB>, and seems
just as apt here.

This is code for B<online banking>, and that means B<your money>, and
that means B<BE CAREFUL>. You are encouraged, nay, expected, to audit
the source of this module yourself to reassure yourself that I am not
doing anything untoward with your banking data. This software is useful
to me, but is provided under B<NO GUARANTEE>, explicit or implied.

=head1 NOTES

I don't have an RBoS account myself, but the backend is the same as the Natwest
one, so it I<should> work ok, but I can't guarantee this.

=head1 BUGS

There are sure to be some bugs lurking in here somewhere. If you find one, please
report it via RT

=head1 THANKS

Jonathan McDowell for both the original pointer that the RBoS online banking
system uses the same backend, and a patch that became the basis of this code.

=head1 AUTHOR

Jody Belka C<knew@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Jody Belka

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
