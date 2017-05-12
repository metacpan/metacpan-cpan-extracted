package Mail::SRS::Guarded;

use strict;
use warnings;
use vars qw(@ISA);
use Carp;
use Mail::SRS qw(:all);
use Mail::SRS::Shortcut;

@ISA = qw(Mail::SRS::Shortcut);

=head1 NAME

Mail::SRS::Guarded - A guarded Sender Rewriting Scheme (recommended)

=head1 SYNOPSIS

	use Mail::SRS::Guarded;
	my $srs = new Mail::SRS::Guarded(...);

=head1 DESCRIPTION

This is the default subclass of Mail::SRS. An instance of this subclass
is actually constructed when "new Mail::SRS" is called.

Note that allowing variable separators after the SRS\d token means that
we must preserve this separator in the address for a possible reversal.
SRS1 does not need to understand the SRS0 address, just preserve it,
on the assumption that it is valid and that the host doing the final
reversal will perform cryptographic tests. It may therefore strip just
the string SRS0 and not the separator. This explains the appearance
of a double separator in SRS1<sep><hostname>=<sep>.

See Mail::SRS for details of the standard SRS subclass interface.
This module provides the methods compile() and parse(). It operates
without store, and guards against gaming the shortcut system.

=head1 SEE ALSO

L<Mail::SRS>

=cut

sub compile {
	my ($self, $sendhost, $senduser) = @_;

	if ($senduser =~ s/$SRS1RE//io) {

		# We could do a sanity check. After all, it might NOT be
		# an SRS address, unlikely though that is. We are in the
		# presence of malicious agents. However, since we don't need
		# to interpret it, it doesn't matter if it isn't an SRS
		# address. Our malicious SRS0 party gets back the garbage
		# he spat out.

		# Actually, it turns out that we can simplify this
		# function considerably, although it should be borne in mind
		# that this address is not opaque to us, even though we didn't
		# actually process or generate it.

		# hash, srshost, srsuser
		my (undef, $srshost, $srsuser) =
						split(qr/\Q$SRSSEP\E/, $senduser, 3);

		my $hash = $self->hash_create($srshost, $srsuser);

		return $SRS1TAG . $self->separator .
						join($SRSSEP, $hash, $srshost, $srsuser);
	}
	elsif ($senduser =~ s/$SRS0RE/$1/io) {
		my $hash = $self->hash_create($sendhost, $senduser);
		return $SRS1TAG . $self->separator .
						join($SRSSEP, $hash, $sendhost, $senduser);
	}

	return $self->SUPER::compile($sendhost, $senduser);
}

sub parse {
	my ($self, $user) = @_;

	if ($user =~ s/$SRS1RE//oi) {
		my ($hash, $srshost, $srsuser) =
						split(qr/\Q$SRSSEP\E/, $user, 3);

		if ($hash =~ /\Q.\E/) {
			die "Hashless SRS1 address received when " .
					"AllowUnsafeSrs is not set"
							unless $self->{AllowUnsafeSrs};
			# Reconstruct the parameters as they were in the old format.
			$srsuser = $srshost . $SRSSEP . $srsuser;
			$srshost = $hash;
		}
		else {
			unless ($self->hash_verify($hash, $srshost, $srsuser)) {
				die "Invalid hash";
			}
		}

		unless (defined $srshost and defined $srsuser) {
			die "Invalid SRS1 address";
		}
		return ($srshost, $SRS0TAG . $srsuser);
	}

	return $self->SUPER::parse($user);
}

1;
