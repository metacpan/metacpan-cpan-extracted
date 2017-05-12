package Mail::SRS::Reversible;

use strict;
use warnings;
use vars qw(@ISA);
use Carp;
use Mail::SRS qw(:all);
use Mail::SRS::Shortcut;

@ISA = qw(Mail::SRS::Shortcut);

=head1 NAME

Mail::SRS::Reversible - A fully reversible Sender Rewriting Scheme

=head1 SYNOPSIS

	use Mail::SRS::Reversible;
	my $srs = new Mail::SRS::Reversible(...);

=head1 DESCRIPTION

See Mail::SRS for details of the standard SRS subclass interface.
This module provides the methods compile() and parse(). It operates
without store.

=head1 SEE ALSO

L<Mail::SRS>

=cut

sub compile {
	my ($self, $sendhost, $senduser) = @_;

	my $timestamp = $self->timestamp_create();

	# This has to be done in compile, because we might need access
	# to it for storing in a database.
	my $hash = $self->hash_create($timestamp, $sendhost, $senduser);

	# Note that there are 4 fields here and that sendhost may
	# not contain a + sign. Therefore, we do not need to escape
	# + signs anywhere in order to reverse this transformation.
	return $SRS0TAG . $self->separator .
			join($SRSSEP, $hash, $timestamp, $sendhost, $senduser);
}

1;
