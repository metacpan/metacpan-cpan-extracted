use Test::More skip_all => 'there are currently no extra filters to test';    # tests => 13;

use Locale::Maketext::Utils::Phrase::Norm;

my $no_arg    = Locale::Maketext::Utils::Phrase::Norm->new_source();
my $true_arg  = Locale::Maketext::Utils::Phrase::Norm->new_source( { 'run_extra_filters' => 1 } );
my $false_arg = Locale::Maketext::Utils::Phrase::Norm->new_source( { 'run_extra_filters' => 0 } );

ok( !$no_arg->run_extra_filters(),    'defaults to off' );
ok( $true_arg->run_extra_filters(),   'true arg is on' );
ok( !$false_arg->run_extra_filters(), 'false arg is off' );

is( $false_arg->enable_extra_filters(), 1, 'enable_extra_filters() returns 1' );
ok( $false_arg->run_extra_filters(), 'enable_extra_filters() enabled it' );

is( $true_arg->disable_extra_filters(), 0, 'disable_extra_filters() returns 0' );
ok( !$true_arg->run_extra_filters(), 'disable_extra_filters() disabled it' );

# If we add a partial extra filter add it here second …
my $spec = Locale::Maketext::Utils::Phrase::Norm->new_source( 'EndPunc', { 'skip_defaults_when_given_filters' => 1 } );

# … update this phrase thourhg the file …
my $res = $spec->normalize('JAPH yo');
ok( $res->get_status(), 'extra filters not applied when disabled (entire module and partial module)' );

my $filt = $res->get_filter_results();
is( $filt->[0]->get_status(), 1, 'entire module extra skipped' );

# … then re-enable this test …
# is( $filt->[1]->get_status(), 1, 'partial module extra skipped' );

ok( exists $spec->{'cache'}{'JAPH yo'}, 'normalize() cached phrase' );
$spec->enable_extra_filters();
ok( !exists $spec->{'cache'}{'JAPH yo'}, 'changing filter state clears cache' );

$res = $spec->normalize('JAPH yo');
is( $res->get_status(), -1, 'extra filters applied when disabled (entire module and partial module)' );

$filt = $res->get_filter_results();
is( $filt->[0]->get_status(), -1, 'entire module extra run' );

# … and this test:
# is( $filt->[1]->get_status(), -1, 'partial module extra run' );
