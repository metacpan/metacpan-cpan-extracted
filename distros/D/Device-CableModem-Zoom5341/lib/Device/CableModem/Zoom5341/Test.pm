use strict;
use warnings;

package Device::CableModem::Zoom5341;


=head1 NAME

Device::CableModem::Zoom5341::Test

=head1 NOTA BENE

This is part of the guts of Device::CableModem::Zoom5341.  If you're
reading this, you're either developing the module, writing tests, or
coloring outside the lines; consider yourself warned.

=cut


=head2 ->load_test_data

Loads sample data for tests
=cut
sub load_test_data
{
	my $self = shift;

	# We're assuming this is run via 'make test'.  Which is strictly
	# speaking Wrong(tm).  But it works well enough for now...
	# overthink things when it becomes necessary.
	use File::Basename qw(dirname);
	use File::Spec;
	my $sampledata = File::Spec->catfile(dirname($0), 'rf_connection.sample');
	open my $sdf, '<', $sampledata or die "Couldn't load sample data: $@";
	my @html = <$sdf>;
	close $sdf;

	chomp @html;
	$self->{conn_html} = \@html;
}


1;
__END__

=head1 SEE ALSO

You should probably be looking at L<Device::CableModem::Zoom5341>
instead.
