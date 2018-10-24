=head1 NAME

Deliantra::Util - utility cruft

=head1 SYNOPSIS

   use Deliantra::Util;

=head1 DESCRIPTION

Various utilities that come in handy when dealing with Deliantra.

=over 4

=cut

package Deliantra::Util;

use common::sense;

use Digest::SHA;

# helepr function to wrok around bugs in Digest::SHA
sub dgst {
   my $s = shift;
   utf8::downgrade $s;
   Digest::SHA::sha512 $s
}

=item Deliantra::Util::hash_pw $cleartext

Hashes a cleartext password into the binary password used in the protocol.

=cut

sub hash_pw($) {
   # we primarily want to protect the password itself, and
   # secondarily want to protect us against pre-image attacks.
   # we don't want to overdo it, to keep implementation simple.

   my $pass = shift;
   utf8::encode $pass;
   $pass = substr $pass, 0, 512 / 8;

   my $hash; # first iteration is just dgst $pass

   $hash = dgst $hash ^ $pass
      for 0..499;

   $hash
}

=item Deliantra::Util::auth_pw $hash, $nonce1, $nonce2

Authenticates a (hashed) password using the given nonce.

=cut

sub auth_pw($$$) {
   my ($hash, $nonce1, $nonce2) = @_;

   # simple HMAC application
   dgst $nonce1 . dgst $nonce2 . $hash
}

=back

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

1
