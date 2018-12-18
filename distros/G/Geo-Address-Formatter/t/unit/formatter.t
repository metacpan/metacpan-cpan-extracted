use strict;
use warnings;
use lib 'lib';
use Test::More;
use Test::Warn;
use Clone qw(clone);
use File::Basename qw(dirname);
use Data::Dumper;
use Text::Hogan::Compiler;

my $CLASS = 'Geo::Address::Formatter';
use_ok($CLASS);

my $path = dirname(__FILE__) . '/test_conf-general';
my $GAF = $CLASS->new( conf_path => $path );

{
  is(
    $GAF->_determine_country_code({ country_code => 'DE' }),
    'DE',
    'determine_country 1'
  );
  is(
    $GAF->_determine_country_code({ country_code => 'de' }),
    'DE',
    'determine_country 2'
  );
}


{
  is($GAF->_clean(undef),undef, 'clean - undef');
  is($GAF->_clean(0),"0\n", 'clean - zero');
  my $rh_tests = {
    '  , abc , def ,, ghi , ' => "abc, def, ghi\n",
  };

  while ( my($source, $expected) = each(%$rh_tests) ){
    is($GAF->_clean($source), $expected, 'clean - ' . $source);
  }

}


{
  # keep in mind this is using the test conf, not the real address-formatting conf
  is( $GAF->_add_state_code( {} ), undef );
  is( $GAF->_add_state_code( { country_code => 'BR', state => 'Sao Paulo'} ), undef );
  is( $GAF->_add_state_code( { country_code => 'us', state => 'California'}), 'CA' );

  # correct state and add state_code if code was in state field
  my $rh_comp = {
      country_code => 'IT',
      state => 'PUG',
  };
  $GAF->_add_state_code($rh_comp);
  is($rh_comp->{state}, 'Puglia', 'corrected state to Puglia');
  is($rh_comp->{state_code}, 'PUG', 'state_code is PUG');

  # correct state and add state_code if code was in state field
  my $rh_comp2 = {
      country_code => 'IT',
      state        => 'PUG',
      state_code   => 'PUG',      
  };
  $GAF->_add_state_code($rh_comp2);
  is($rh_comp2->{state}, 'Puglia', 'corrected state to Puglia');
  is($rh_comp2->{state_code}, 'PUG', 'state_code is PUG');  


  # set state if only state_code supplied
#  my $rh_comp3 = {
#      country_code => 'IT',
#      state_code   => 'PUG',
#  };
#  $GAF->_add_state_code($rh_comp3);
#  is($rh_comp3->{state}, 'Puglia', 'corrected state to Puglia');
#  is($rh_comp3->{state_code}, 'PUG', 'state_code is PUG');
}

{ # county code
  my $rh_c = {
      country_code => 'IT',
      county       => 'RM',
  };
  $GAF->_add_county_code($rh_c);
  is($rh_c->{county}, 'Roma', 'corrected county to Roma');
  is($rh_c->{county_code}, 'RM', 'set county_code to RM');  
}

{
  my $components = {
    street => 'Hello World',
  };

  is_deeply(
    $GAF->_apply_replacements(clone($components),[]),
    $components
  );

  is_deeply(
    $GAF->_apply_replacements(clone($components),[['^Hello','Bye'], ['d','t']]),
    {street => 'Bye Worlt'}
  );

  warning_like {
    is_deeply(
      $GAF->_apply_replacements(clone($components),[['((ll','']]),
      $components
    );
  } qr/invalid replacement/, 'got warning';


}

{
  is_deeply(
    $GAF->_find_unknown_components({ one => 1, four => 4}),
    ['four'],
    '_find_unknown_components'
  );
}


{
  my $THT = Text::Hogan::Compiler->new->compile('abc {{#first}} {{one}} || {{two}} {{/first}} def');
  is(
    $GAF->_render_template(
        $THT,
        { two => 2 }
      ),
    "abc 2 def\n",
    '_render_template - first'
  );
}


done_testing();

1;
