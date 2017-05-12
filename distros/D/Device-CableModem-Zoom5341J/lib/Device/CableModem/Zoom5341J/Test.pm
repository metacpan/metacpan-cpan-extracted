use strict;
use warnings;

package Device::CableModem::Zoom5341J;


=head1 NAME

Device::CableModem::Zoom5341J::Test

=head1 NOTA BENE

This is part of the guts of Device::CableModem::Zoom5341J.  If you're
reading this, you're either developing the module, writing tests, or
coloring outside the lines; consider yourself warned.

=cut


=head2 ->load_test_data

Loads sample data for tests
=cut
sub load_test_data
{
	my $self = shift;
	my $samfile = shift;

	open my $sdf, '<', $samfile or die "Couldn't load sample data: $@";
	my $html = join '', <$sdf>;
	close $sdf;

	$self->{conn_html} = $html;
}


1;
__END__

=head1 SEE ALSO

You should probably be looking at L<Device::CableModem::Zoom5341J>
instead.
