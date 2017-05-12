package Mail::Karmasphere::Parser::Base;

use strict;
use warnings;
use Data::Dumper;
use Mail::Karmasphere::Parser::Record;
use Carp qw(confess);

sub new {
	my $class = shift;
	my $self = ($#_ == 0) ? { %{ (shift) } } : { @_ };
	die "No input mechanism (fh)" unless exists $self->{fh};
	die "No stream metadata (Streams)" unless exists $self->{Streams};
	return bless $self, $class;
}

sub warning {
	my $self = shift;
	if (++$self->{Warnings} < 10) {
		warn @_;
	}
}

sub error {
	my $self = shift;
	++$self->{Errors};
	die @_;
}

sub fh {
	return $_[0]->{fh};
}

sub _parse {
	die "Subclass must implement _parse routine";
}

sub streams {
	return $_[0]->{Streams};
}

sub parse {
	my $self = shift;
	return if $self->{Done};
  RECORDS:
	for (;;) {
#		print STDERR "> > parsing...\n";
		my @records = $self->_parse;
		my @toreturn;
	  RECORD:
		for my $record (@records) {
#			print STDERR "  > record: $record\n";
			last RECORD unless defined $record;
			print Dumper($record) if $self->debug;
			my $stream = $record->stream;
			my $type = $self->{Streams}->[$stream];

			if (!defined $type) {
				$self->warning("Ignoring record: " .
							   "Invalid stream: " .
							   $stream);
				next RECORDS;
			}
			elsif ($type ne $record->type) {
				$self->warning("Ignoring record: " .
							   "Stream type mismatch: " .
							   "Expected $type, got " . $record->type .
							   ": " . $record->as_string);
				next RECORDS;
			}
			else {
				push @toreturn, $record;
			}
		}

		if (wantarray) {
			return @toreturn;
		}
		elsif (@toreturn <= 1) {
			return $toreturn[0];
		}
		else {
			croak("Parser has @{[scalar @toreturn]} records to return, but parse() was called in scalar context");
		}
	}
	$self->{Done} = 1;
	return;
}

sub debug { $ENV{DEBUG} }

1;
