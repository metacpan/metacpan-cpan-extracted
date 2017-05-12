
package Log::Parallel::Raw;

use strict;
use warnings;

our @ISA = qw(Log::Parallel::Parsers::BaseClass Log::Parallel::Writers::BaseClass);

__PACKAGE__->register_parser();
__PACKAGE__->register_writer();

sub done {
	my ($self) = @_;

	$self->{'columns'} = ['raw'];
	$self->SUPER::done();
	$self->{'name'} = $self->{'format'} = 'Raw';
}

sub return_parser {
	my ($class, $fh, %info) = @_;

	return sub {
		my $line = <$fh>;
		return $line;
	};
}

sub new
{
	my ($pkg, $format, %info) = @_;
	my $self = $pkg->SUPER::new($format, %info);
	$self->{items} = 0;
	return $self;
}

sub write {
	my ($self, $log) = @_;
	$self->{items}++;
	my $fh = $self->{fh};
	print $fh $log;
}

sub sort_arguments
{
	my ($self) = @_;
	return $self->{sort_args} || '';
}

sub post_sort_transform
{
	my ($self) = @_;
	return $self->{post_sort_transform} || '';
}

1;

__END__


=head1 NAME

Log::Parallel::Raw - raw format reader/writer.

=head1 DESCRIPTION

This module implements a data format for use by the batch
log processing system, L<Log::Parallel>.  This format 
stores data as lines of text as provided by the transformation
step.

=head1 LICENSE

This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.

