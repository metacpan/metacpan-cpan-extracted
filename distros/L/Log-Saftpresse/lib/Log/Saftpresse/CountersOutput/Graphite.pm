package Log::Saftpresse::CountersOutput::Graphite;

use Moose;

# ABSTRACT: plugin to write counters to carbon line reciever
our $VERSION = '1.6'; # VERSION

extends 'Log::Saftpresse::CountersOutput';

use IO::Socket::INET;

sub output {
	my ( $self, $counters ) = @_;
	my %data = map {
		$_ => $counters->{$_}->counters,
	} keys %$counters;

	$self->_output_graphit( \%data );

	return;
}

has 'prefix' => ( is => 'rw', isa => 'Str', lazy => 1,
	default => 'saftpresse',
);

has '_handle' => (
	is => 'rw', isa => 'IO::Socket::INET', lazy => 1,
	default => sub {
		my $self = shift;
		my $handle = IO::Socket::INET->new(
			PeerAddr => $self->{'host'} || '127.0.0.1',
			PeerPort => $self->{'port'} || '2003',
			Proto => 'tcp',
		) or die('error opening connection to graphite line reciever: '.$@);
		return $handle;
	},
);

sub _proc_hash {
	my ( $self, $path, $now, $hash ) = @_;
	foreach my $key ( keys %$hash ) {
		my $value = $hash->{$key};
		my $type = ref $value;
		my $graphit_key = $key;
		$graphit_key =~ s/\./_/g;
		my $this_path = $path.'.'.$graphit_key;
		if( ! defined $value ) {
			# noop
		} elsif( $type eq 'HASH' ) {
			$self->_proc_hash($this_path, $now, $value);
		} elsif( $type eq '' ) {
			$self->_handle->print($this_path.' '.$value.' '.$now."\n");
		} else {
			die('unhandled data structure!');
		}
	}
	return;
}

sub _output_graphit { 
	my ( $self, $data ) = @_;
	my $now = time;
	
	$self->_proc_hash($self->prefix, $now , $data);

	return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Saftpresse::CountersOutput::Graphite - plugin to write counters to carbon line reciever

=head1 VERSION

version 1.6

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998 by James S. Seymour, 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
