
package Log::Parallel::TSV;

use strict;
use warnings;

use Log::Parallel::Parsers;
use Log::Parallel::Writers;
use Carp qw(confess);
use YAML::Syck;

our @ISA = qw(Log::Parallel::Parsers::BaseClass Log::Parallel::Writers::BaseClass);

__PACKAGE__->register_parser();
__PACKAGE__->register_writer();

Log::Parallel::Writers::register_writer(TSV_as_sessions => sub { __PACKAGE__->new(@_) });

sub done {
	my ($self) = @_;

	$self->SUPER::done();
	$self->{name} = $self->{format} . '-' . $self->md5_hex(Dump($self->{columns}, $self->{sort_types}));
}

sub return_parser {
	my ($class, $fh, %info) = @_;
	my $header = $info{header};
	my @ordered_fieldnames = @{$header->{'columns'}};

	return sub {
		my $line = <$fh>;
		if (not defined $line) {
			return undef;
		}

		chomp($line);
		my @ordered_values = split("\t", $line, -1);
		if (scalar(@ordered_fieldnames) != scalar(@ordered_values)) {
			if (scalar(@ordered_fieldnames) < scalar(@ordered_values)) {
				confess sprintf("Mismatch in field count between header (%d) and data (%d) at line %d of %s:%s", scalar(@ordered_fieldnames), scalar(@ordered_values), $., $info{host}, $info{filename})
			} else {
				push(@ordered_values, ('') x (scalar(@ordered_fieldnames) - scalar(@ordered_values)));
			}
		}

		my %log_entry;
		@log_entry{@ordered_fieldnames} = @ordered_values;

		return \%log_entry;
	};
}

sub new
{
	my ($pkg, $format, %info) = @_;
	my $self = $pkg->SUPER::new($format, %info);
	$self->{items} = 0;
	$self->{numeric} = {};
	return $self;
}

sub write {
	my ($self, $log) = @_;

	$self->{items}++;

#	if (! defined $self->{columns}) {
#		if ($self->{sort_by}) {
#			if ($self->{new_fields_cb}) {
#				$self->{columns} = $self->{new_fields_cb}(
#					current => [],
#					sort_by	=> $self->{sort_by},
#					new	=> keys %$log,
#				);
#			} else {
#				my $c = 1;
#				my %sort_by = map { $_ => $c++ } @{$self->{sort_by}};
#				$self->{columns} = [ @{$self->{sort_by}} ];
#				$self->{columns} = [ @{$self->{sort_by}}, sort grep { ! exists $sort_by{$_} } keys %$log ];
#			}
#		} else {
#			$self->{columns} = [];
#		}
#	}

	my $cols = $self->{columns};

	defined($_) && s/[\n\t]+/ /g for values %$log;

	my $buf = join("\t", map { defined($log->{$_}) ? $log->{$_} : '' } @$cols);

	delete @$log{@$cols};

	if (keys %$log) {
		my @oldval = split(/\t/, $buf, -1);
		my @oldcol = @$cols;
#		if ($self->{new_fields_cb}) {
#			$self->{columns} = $self->{new_fields_cb}(
#				current => $cols,
#				sort_by	=> $self->{sort_by},
#				new	=> keys %$log,
#			);
#			$cols = $self->{columns};
#		} 
		push(@$cols, sort keys %$log);
		@$log{@oldcol} = @oldval;
		$buf = join("\t", map { defined($log->{$_}) ? $log->{$_} : '' } @$cols);
	}
	my $fh = $self->{fh};

	print $fh $buf."\n";

	if ($self->{discover_types}) {
		$self->{numeric}{$_}++ for grep { defined($log->{$_}) && $log->{$_} =~ /^-?(?:\d+(?:\.\d+)?|\.\d+)/ } @{$self->{sort_by}};
	}
}

sub sort_arguments
{
	my ($self) = @_;

	return '' unless $self->{sort_by};

	my $arg = qq{-t'\t'};

	my $col = 1;

	for my $c (@{$self->{sort_by}}) {
		$arg .= " -k $col,$col";
		if ($self->{discover_types}) {
			if (($self->{numeric}{$c} || 0) >= $self->{items} * .5) {
				$arg .= "n";
				$self->{sort_types}{$c} = 'n';
			}
		} else {
			$arg .= $self->{sort_types}{$c} || '';
		}
		$col++;
	}
	return $arg;
}

1;

__END__

=head1 NAME

Log::Parallel::TSV - Log TSV format reader/writer.

=head1 DESCRIPTION

This module implements a data format for use by the batch
log processing system, L<Log::Parallel>.  This format 
stores files in headerless Tab Sepearated Values files.  The
columns are discovered at runtime.

If the output is sorted, the columns by which it is sorted will
be first.

There is special handling for this format in
L<Log::Parallel::Task> to combine buckets together.

=head1 LICENSE

This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.

