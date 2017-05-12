package Mail::SRS::Limit;

use strict;
use warnings;
use base 'Mail::SRS';
use Carp;
use MLDBM qw(DB_File Storable);
use Fcntl;

=head1 NAME

Mail::SRS::Limit - A Sender Rewriting Scheme which limits bounces

=head1 SYNOPSIS

	use Mail::SRS::Limit;
	my $srs = new Mail::SRS::Limit(
		Database => '/var/run/srs.db',
		Limit    => 10,
		...
			);

=head1 DESCRIPTION

See Mail::SRS for details of the standard SRS subclass interface.

This module requires two extra parameters to the constructor: a
filename for a Berkeley DB_File database, and the maximum number of
bounces to allow for any mail.

=head1 BUGS

This code relies on not getting collisions in the cryptographic
hash. This can and should be fixed.

The database is not garbage collected.

=head1 SEE ALSO

L<Mail::SRS>

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	die "No database specified for Mail::SRS::DB"
					unless $self->{Database};
	my %data;
	my $dbm = tie %data, 'MLDBM',
			$self->{Database}, O_CREAT|O_RDWR, 0640
					or die "Cannot open $self->{Database}: $!";
	$self->{Data} = \%data;
	return $self;
}

sub compile {
	my ($self, $sendhost, $senduser) = @_;

	my $time = time();

	my $data = {
		Time		=> $time,
		Limit		=> $self->{Limit},
		SendHost	=> $sendhost,
		SendUser	=> $senduser,
			};

	# We rely on not getting collisions in this hash.
	my $hash = $self->hash_create($sendhost, $senduser);

	$self->{Data}->{$hash} = $data;

	# Note that there are 4 fields here and that sendhost may
	# not contain a + sign. Therefore, we do not need to escape
	# + signs anywhere in order to reverse this transformation.
	return $hash;
}

sub parse {
	my ($self, $user) = @_;

	my $hash = $user;
	my $data;

	unless ($data = $self->{Data}->{$hash}) {
		die "No data found";
	}

	my $sendhost = $data->{SendHost};
	my $senduser = $data->{SendUser};

	unless ($self->hash_verify($hash, $sendhost, $senduser)) {
		die "Invalid hash";
	}

	unless ($self->time_check($data->{Time})) {
		die "Invalid timestamp";
	}

	unless ($data->{Limit} > 0) {
		die "Limit expired";
	}
	$data->{Limit}--;
	$self->{Data}->{$hash} = $data;	# Trigger rewrite in MLDBM

	return ($sendhost, $senduser);
}

1;
