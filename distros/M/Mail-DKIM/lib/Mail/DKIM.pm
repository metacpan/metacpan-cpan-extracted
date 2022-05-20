package Mail::DKIM;
use strict;
use warnings;
our $VERSION = '1.20220520'; # VERSION
# ABSTRACT: Signs/verifies Internet mail with DKIM/DomainKey signatures

#require 5.010;


our $SORTTAGS = 0;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::DKIM - Signs/verifies Internet mail with DKIM/DomainKey signatures

=head1 VERSION

version 1.20220520

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

=head1 AUTHORS

=over 4

=item *

Jason Long <jason@long.name>

=item *

Marc Bradshaw <marc@marcbradshaw.net>

=item *

Bron Gondwana <brong@fastmailteam.com> (ARC)

=back

=head1 CONTRIBUTORS

=for stopwords Aaron Thompson Bron Gondwana Christian Jaeger Damien MASCRÉ jasonlong José Borges Ferreira Marc Bradshaw Martijn van de Streek Martin H. Sluka Mohammad S Anwar

=over 4

=item *

Aaron Thompson <dev@aaront.org>

=item *

Bron Gondwana <brong@fastmail.fm>

=item *

Christian Jaeger <ch@christianjaeger.ch>

=item *

Damien MASCRÉ <damienmascre@free.fr>

=item *

jasonlong <jasonlong@f38efd27-133c-0410-a3cc-a5f95e9cf04f>

=item *

José Borges Ferreira <jose.ferreira@bitsighttech.com>

=item *

Marc Bradshaw <marc@fastmailteam.com>

=item *

Martijn van de Streek <martijn@vandestreek.net>

=item *

Martin H. Sluka <martin@sluka.de>

=item *

Mohammad S Anwar <mohammad.anwar@yahoo.com>

=back

=head1 THANKS

Work on ensuring that this module passes the ARC test suite was
generously sponsored by Valimail (https://www.valimail.com/)

=head1 COPYRIGHT AND LICENSE

=over 4

=item *

Copyright (C) 2013 by Messiah College

=item *

Copyright (C) 2010 by Jason Long

=item *

Copyright (C) 2017 by Standcore LLC

=item *

Copyright (C) 2020 by FastMail Pty Ltd

=back

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
