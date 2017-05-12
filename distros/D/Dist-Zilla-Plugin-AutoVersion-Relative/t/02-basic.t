
use strict;
use warnings;

use Test::More tests => 6;    # last test to print
use Dist::Zilla::Plugin::AutoVersion::Relative;
use Test::DZil qw( simple_ini Builder );
use Dist::Zilla;
use Dist::Zilla::Plugin::GatherDir;
use DateTime;

my $pn = 'AutoVersion::Relative';

my $files = {
  'source/dist.ini' => simple_ini('GatherDir'),
  'source/fake.pm'  => q[],
};

my $zilla = Builder->from_config( { dist_root => 'invalid' }, { add_files => $files } );

sub create_plugin {
  my ( $name, $args ) = @_;
  ( 'Dist::Zilla::Plugin::' . $name )->new(
    zilla       => $zilla,
    plugin_name => $name,
    %{$args},
  );
}
pass('Configure OK');
{
  my $plug = create_plugin($pn);
  like $plug->provide_version, qr/^1.01\d{6}$/, "Defaults";
}
{
  my $plug = create_plugin( $pn, { major => 0, } );
  like $plug->provide_version, qr/^0.01\d{6}$/, "Major V";
}
{
  my $plug = create_plugin( $pn, { major => 0, minor => 0, } );
  like $plug->provide_version, qr/^0.00\d{6}$/, "Minor V";
}
{
  my $plug = create_plugin( $pn => { major => 0, minor => 0, year => DateTime->now->year } );

  $plug->provide_version =~ m/^0.00(\d{4})/;
  my $y = $1;
  if ( $y <= 12 * 31 ) {
    ok( 1, "Recent " );
  }
  else {
    ok( 0, "Recent" );
    diag( 'Version: ' . $plug->provide_version );
    diag( 'Days Passed: ' . $y );
    diag( 'Expected: <= ' . ( 12 * 31 ) );
  }
}
{

  # calculation of variables sent to Text::Template.

  # fake the current time, so this test is consistent
  # this time corresponds to 2012-03-01 00:00:00 UTC, which using the
  # "all months have 31 days" rule would give days=31+31+1 - 5 = 58,
  # but the actual days since the milestone is 31+29+1 - 5 = 56.
  my $now = DateTime->from_epoch( epoch => 1330560000 );

  my $plug = create_plugin(
    $pn => {
      format        => '{{ sprintf("%03u", days) }}',
      year          => 2012,
      month         => 01,
      day           => 05,
      _current_time => $now,
    }
  );

  is( $plug->provide_version, '056', 'day of year is calculated correctly' );

  # TODO: test other variables, using other $dt and milestone inputs.
}

