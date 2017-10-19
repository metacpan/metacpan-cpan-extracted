#!/usr/bin/perl

use strict;
use warnings;

package Mail::DKIM;
our $VERSION = 0.44;

our $SORTTAGS = 0;

1;
__END__

=head1 NAME

Mail::DKIM - Signs/verifies Internet mail with DKIM/DomainKey signatures

=head1 SYNOPSIS

  # verify a message
  use Mail::DKIM::Verifier;

  # create a verifier object
  my $dkim = Mail::DKIM::Verifier->new();

  # read an email from stdin, pass it into the verifier
  while (<STDIN>)
  {
      # remove local line terminators
      chomp;
      s/\015$//;

      # use SMTP line terminators
      $dkim->PRINT("$_\015\012");
  }
  $dkim->CLOSE;

  # what is the result of the verify?
  my $result = $dkim->result;

=head1 DESCRIPTION

This module implements the various components of the DKIM and
DomainKeys message-signing and verifying standards for Internet mail.
It currently tries to implement these specifications:

=over

=item RFC4871, for DKIM

=item RFC4870, for DomainKeys

=item draft-ietf-dmarc-arc-protocol-06, for ARC

=back

The module uses an object-oriented interface. You use one of
two different classes, depending on whether you are signing or verifying
a message. To sign, use the L<Mail::DKIM::Signer> class. To verify, use
the L<Mail::DKIM::Verifier> class. Simple, eh?

Likewise for ARC, use the ARC modules L<Mail::DKIM::ARC::Signer> and
L<Mail::DKIM::ARC::Verifier>

If you're sending to test libraries which expect the tags in headers
to be sorted, you can set $Mail::DKIM::SORTTAGS to a true value, and
all created headers will get sorted keys

=head1 SEE ALSO

L<Mail::DKIM::Signer>,
L<Mail::DKIM::Verifier>

L<Mail::DKIM::ARC::Signer>,
L<Mail::DKIM::ARC::Verifier>

http://dkimproxy.sourceforge.net/

https://github.com/fastmail/authentication_milter

=head1 KNOWN BUGS

Problems passing `make test' seem to usually point at a faulty DNS
configuration on your machine, or something weird about your OpenSSL
libraries.

The "author signing policy" component is still under construction. The
author signing policy is supposed to identify the practice of the message
author, so you could for example reject a message from an author who claims
they always sign their messages. See L<Mail::DKIM::Policy>.

Please report bugs to the CPAN RT, or github issue tracker.

https://rt.cpan.org/Public/Dist/Display.html?Name=Mail-DKIM

https://github.com/fastmail/mail-dkim/issues

=head1 AUTHOR

Jason Long, E<lt>jlong@messiah.eduE<gt>

=head1 CONTRIBUTORS

Marc Bradshaw, E<lt>marc@marcbradshaw.netE<gt>
Bron Gondwana, E<lt>brong@fastmailteam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2007, 2009 by Messiah College
Copyright (C) 2017 by FastMail Pty Ltd

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
