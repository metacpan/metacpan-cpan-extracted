package Egg::Release::Mail;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Mail.pm 333 2008-04-19 17:04:06Z lushe $
#
use strict;
use warnings;

our $VERSION = '0.06';

1;

__END__

=head1 NAME

Egg::Release::Mail - Package kit for Mail Sending.

=head1 DESCRIPTION

=over 4

=item * L<Egg::View::Mail>

..... View to transmit mail.

=item * L<Egg::View::Mail::Base>

..... Base class for E-mail controller.

=item * L<Egg::View::Mail::Mailer::CMD>

..... Mail is transmitted by the sendmail command.

=item * L<Egg::View::Mail::Mailer::SMTP>

..... Mail is transmitted with L<Net::SMPT>.

=item * L<Egg::View::Mail::Encode::ISO2022JP>

..... Component for Japanese mail.

=item * L<Egg::View::Mail::MIME::Entity>

..... The content of the transmission is generated.

=item * L<Egg::View::Mail::Plugin::EmbAgent>

..... Plugin that adds client information to content of transmission.

=item * L<Egg::View::Mail::Plugin::Jfold>

..... Plug-in with which each line of content of transmission is molded in arbitrary digit.

=item * L<Egg::View::Mail::Plugin::Lot>

..... Plugin that transmits mail of this content to two or more destinations.

=item * L<Egg::View::Mail::Plugin::PortCheck>

..... The operation of the mail server is confirmed before it transmits.

=item * L<Egg::View::Mail::Plugin::Signature>

..... Plugin that adds famous etc. to content of transmission.

=item * L<Egg::Helper::View::Mail>

..... Helper to generate E-mail controller.

=back

=head1 SEE ALSO

L<Egg::Release>,
L<Net::SMTP>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Bee Flag, Corp. E<lt>http://egg.bomcity.com/E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

