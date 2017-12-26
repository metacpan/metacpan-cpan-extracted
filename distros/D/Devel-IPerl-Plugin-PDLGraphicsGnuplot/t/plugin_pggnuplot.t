use Test::Most tests => 2;

use strict;
use warnings;

use PDL::Graphics::Gnuplot;
use Devel::IPerl::Plugin::PDLGraphicsGnuplot;
use IPerl;
use PDL;
use PDL::Constants qw(PI);

IPerl->load_plugin($_) for qw(PDLGraphicsGnuplot CoreDisplay);

sub run_plot {
	my $w = gpwin();
	#use DDP; p $w->options();

	my $theta = zeros(200)->xlinvals(0, 6 * PI() );

	$w->plot( $theta, sin($theta) );

	my $data = $w->iperl_data_representations;
}

my $data;
lives_ok { $data = run_plot() } 'plotting does not die';

like $data->{'image/svg+xml'}, qr/<svg[^>]+>/s, 'has <svg> tag';

done_testing;
