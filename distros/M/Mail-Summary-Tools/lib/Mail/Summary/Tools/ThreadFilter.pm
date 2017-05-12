#!/usr/bin/perl

package Mail::Summary::Tools::ThreadFilter;
use Moose;

has filters => (
	isa => "ArrayRef",
	is  => "rw",
	required   => 1,
	auto_deref => 1,
);

sub filter {
	my ( $self, %params ) = @_;

	my $threads = $params{threads}  || die "no threads";;
	my $cb      = $params{callback} || die "no callback";
	
	thread: foreach my $thread ( $threads->sortedAll ) {
		foreach my $filter ( $self->filters ) {
			next thread unless $filter->( $thread );
		}

		$cb->($thread);
	}
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Mail::Summary::Tools::ThreadFilter - Filter Mail::Box::Thread::Node objects

=head1 SYNOPSIS

	# don't use it directly

=head1 DESCRIPTION

This is just a utility class used by the summary creation code, to limit the
scope of the summary.

=cut


