use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use Test::File::ShareDir -share => {
  -dist => { 'Langertha-Skeid' => 'share' },
};
use Langertha::Skeid;

# Without pricing every row costs 0: the order must still be the same on
# every run and ascending by key id / model name.
my @ids    = qw( k_m k_c k_x k_a k_q k_f k_z k_b k_t k_h k_p k_d );
my @models = qw( m-9 m-3 m-7 m-1 m-5 m-2 m-8 m-4 m-6 m-0 m-b m-a );

for my $case (
  [ jsonlog => sub { +{ backend => 'jsonlog', path => tempdir( CLEANUP => 1 ) } } ],
  [ sqlite  => sub { +{ backend => 'sqlite', sqlite_path => tempdir( CLEANUP => 1 ).'/u.sqlite' } } ]
) {
  my ( $name, $cfg ) = @{ $case };
  my $skeid = Langertha::Skeid->new( usage_store => $cfg->() );
  for my $i ( 0 .. $#ids ) {
    $skeid->call_function( 'usage.record', {
      api_format  => 'openai',
      api_key_id  => $ids[$i],
      model       => $models[$i],
      status_code => 200,
      ok          => 1,
      duration_ms => 1,
      metrics     => { usage => { input => 1, output => 1, total => 2 } }
    } );
  }
  my $r1   = $skeid->call_function( 'usage.report', {} );
  my $r2   = $skeid->call_function( 'usage.report', {} );
  my @keys = map { $_->{api_key_id} } @{ $r1->{by_key} };
  my @mods = map { $_->{model} } @{ $r1->{by_model} };
  is_deeply( \@keys, [ sort @ids ],    $name.': by_key ascending by key id at equal cost' );
  is_deeply( \@mods, [ sort @models ], $name.': by_model ascending by model at equal cost' );
  is_deeply( [ map { $_->{api_key_id} } @{ $r2->{by_key} } ], \@keys, $name.': by_key stable across runs' );
}

done_testing;
