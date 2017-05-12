package Logfile::EPrints::Filter::Period;

use vars qw( $AUTOLOAD );

sub new {
	my ($class,%self) = @_;
	bless \%self, ref($class) || $class;
}

sub AUTOLOAD
{
	$AUTOLOAD =~ s/^.*:://;
	return if $AUTOLOAD =~ /[A-Z]$/;
	my ($self,$hit) = @_;
	return if defined($self->{after}) && $hit->datetime <= $self->{after};
	return if defined($self->{before}) && $hit->datetime >= $self->{before};
	$self->{handler}->$AUTOLOAD($hit);
}

1;

=pod

=head1 NAME

Logfile::EPrints::Filter::Period

=head1 DESCRIPTION

Filter hits for a given time period (given as yyyymmddHHMMSS).

=head1 METHODS

=over 5

=item new(%opts)

	after=>20040320145959
		only include records I<after> this datetime
	before=>20040320160000
		only include records I<before> this datetime

=back

=cut
