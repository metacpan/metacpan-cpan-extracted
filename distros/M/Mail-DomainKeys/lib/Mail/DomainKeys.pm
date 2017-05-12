# Copyright (c) 2005, Anthony D. Urso. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Mail::DomainKeys;

use strict;

our $VERSION = "1.0";

1;

__END__

=head1 NAME

Mail::DomainKeys - A perl implementation of DomainKeys

=head1 CAVEAT

THIS MODULE IS OFFICIALLY UNSUPPORTED.

Please move on to DKIM like a responsible Internet user.  I have.

I will leave this module here on CPAN for a while, just in case someone
has grown to depend on it.  It is apparent that DK will not be the way
of the future. Thus, it is time to put this module to ground before it
causes any further harm.

Thanks for your support,
Anthony

=head1 SYNOPSIS

Mail::DomainKeys is a perl implementation of Yahoo's mail signature
protocol.

This library allows one to sign and verify signatures as per draft
03 of the DomainKeys specification:

http://www.ietf.org/internet-drafts/draft-delany-domainkeys-base-03.txt

=head2 A Simple Example

This example shows the simplest possible DomainKeys signature verifier.

  require Mail::DomainKeys::Message;

  # load a message from a filehandle glob
  my $mail = load Mail::DomainKeys::Message(File => \*STDIN) or
    die "unable to load message\n";

  # check to make sure the sender has a fully qualified domain    
  $mail->senderdomain or
    die "unable to verify message: no sender domain\n";  

  # check if the mail is signed by DomainKeys
  $mail->signed or
    die "no signature\n";

  # check the signature  
  if ($mail->verify) {
    print STDERR "signature valid\n";
    exit 0;
  }

  # the signature was not valid
  die "unable to verify signature\n";

This example shows the simplest possible DomainKeys signer.

  require Mail::DomainKeys::Message;
  require Mail::DomainKeys::Key::Private;

  # load the message, or die trying
  my $mail = load Mail::DomainKeys::Message(File => \*STDIN) or
    die "unable to load message";

  # load the private key, or die trying
  my $priv = load Mail::DomainKeys::Key::Private(File => "private.key") or
    die "unable to load key";

  # sign the message using the "simple" canonifier and selector "test"	
  $mail->sign(Method => "simple", Selector => "test", Private => $priv);

  # print out the signature
  print $mail->signature->as_string;

=head1 SEE ALSO

=item Mail::DomainKeys::Message

=item Mail::DomainKeys::Policy

=back

=head1 COPYRIGHT

Copyright (c) 2005, Anthony D. Urso. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AVAILABILITY

The latest version of Mail::DomainKeys will be available on CPAN and at:

http://killa.net/infosec/Mail-DomainKeys/

=cut  
