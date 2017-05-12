package Log::Saftpresse::CountersOutput::Dump;

use Moose;

# ABSTRACT: plugin to dump counters to stdout
our $VERSION = '1.6'; # VERSION

extends 'Log::Saftpresse::CountersOutput';

use JSON;
use Data::Dumper;
use Sys::Hostname;

has 'format' => ( is => 'rw', isa => 'Str', default => 'graphit' );

sub output {
	my ( $self, $counters ) = @_;
	my %data = map {
		$_ => $counters->{$_}->counters,
	} keys %$counters;

	if( lc $self->format eq 'graphit' ) {
		$self->_output_graphit( \%data );
	} elsif ( lc $self->format eq 'json' ) {
		$self->_output_json( \%data );
	} elsif ( lc $self->format eq 'perl' ) {
		$self->_output_perl( \%data );
	}

	return;
}

has 'graphit_prefix' => (
	is => 'rw', isa => 'Str', lazy => 1,
	default => sub {
		return 'server.'.hostname;
	},
);

sub _proc_hash {
	my ( $path, $hash, $now ) = @_;
	foreach my $key ( keys %$hash ) {
		my $value = $hash->{$key};
		my $type = ref $value;
		my $graphit_key = $key;
		$graphit_key =~ s/\./_/g;
		my $this_path = $path.'.'.$graphit_key;
		if( ! defined $value ) {
			# noop
		} elsif( $type eq 'HASH' ) {
			_proc_hash($this_path, $value, $now);
		} elsif( $type eq '' ) {
			print $this_path.' '.$value.' '.$now."\n";
		} else {
			die('unhandled data structure!');
		}
	}
	return;
}

sub _output_graphit { 
	my ( $self, $data ) = @_;
	my $now = time;
	
	_proc_hash($self->graphit_prefix, $data, $now);

	return;
}

sub _output_perl { 
	my ( $self, $data ) = @_;
	print Dumper( $data );	
	return;
}
sub _output_json { 
	my ( $self, $data ) = @_;
	my $json = JSON->new;
	$json->pretty(1);
	print $json->encode( $data );	
	return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Saftpresse::CountersOutput::Dump - plugin to dump counters to stdout

=head1 VERSION

version 1.6

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998 by James S. Seymour, 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
