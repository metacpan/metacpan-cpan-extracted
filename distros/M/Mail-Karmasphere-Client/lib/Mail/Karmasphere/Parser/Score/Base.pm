package Mail::Karmasphere::Parser::Score::Base;

use strict;
use warnings;
use base 'Mail::Karmasphere::Parser::Base';
use Text::CSV;

sub new {
	my $class = shift;
	my $self = ($#_ == 0) ? { %{ (shift) } } : { @_ };
	my $type = $self->{Type};
	unless ($type) {
		$type = lc $class;
		$type =~ s/.*:://;
	}
	$self->{Streams} = [ $type ] unless $self->{Streams};
	$self = $class->SUPER::new($self);
	return $self;
}

sub _value {
	my $text = shift;
	return 1000 unless defined $text;
	return 1000 unless $text =~ /\S/;
	return 0+ $text;
}

sub _parse {
	my $self = shift;
	LINE: for (;;) {
		my $line = $self->fh->getline;
		return undef unless $line;
		next if $line =~ /^#/;
		next unless $line =~ /\S/;
		chomp($line);
		my $csv = new Text::CSV();
		unless ($csv->parse($line)) {
			warn "Failed to parse CSV line $line";
			next LINE;
		}
		my @fields = $csv->fields();
		# guess_identity_type does validation, and
		# the wrapper checks that the record type matches
		# the stream type, so no further validation is required
		# here. XXX It would be faster to fix the type here from
		# $type, and do a single regex to check it.
		return new Mail::Karmasphere::Parser::Record(
			s	=> 0,
			i	=> $fields[0],
			v	=> _value($fields[1]),
			d	=> $fields[2],
				);
	}
}

1;
