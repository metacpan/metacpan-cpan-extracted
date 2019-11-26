
use strict;
use warnings;

use Test::More tests => 2;

use Devel::IPerl::Plugin::Chart::Plotly;

Devel::IPerl::Plugin::Chart::Plotly->register();

ok( Chart::Plotly::Plot->can('iperl_data_representations') );
ok( Chart::Plotly::Trace::Scatter->can('iperl_data_representations') );

