package Logfile::EPrints::Institution;

use vars qw( $AUTOLOAD );

=pod

=head1 NAME

Logfile::EPrints::Institution - Deprecated.

=cut

sub new
{
	my ($class,%args) = @_;
	bless \%args, ref($class) || $class;
}

sub AUTOLOAD
{
	$AUTOLOAD =~ s/.*:://;
	return if $AUTOLOAD =~ /^[A-Z]/;
	my ($self,$hit) = @_;
	$self->{handler}->$AUTOLOAD($hit);
}

1;

=back

=cut
