use strict;
use warnings;
use lib 'lib';
use Test::More;
use Test::Warn;
use Clone qw(clone);
use File::Basename qw(dirname);
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
use Text::Hogan::Compiler;
use utf8;

my $CLASS = 'Geo::Address::Formatter';
use_ok($CLASS);

my $path = dirname(__FILE__) . '/test_conf-general';
my $GAF  = $CLASS->new(conf_path => $path);

{
    is($GAF->_determine_country_code({country_code => 'DE'}), 'DE', 'determine_country 1');
    is($GAF->_determine_country_code({country_code => 'de'}), 'DE', 'determine_country 2');
}

{
    is($GAF->_clean(undef), undef, 'clean - undef');
    is($GAF->_clean(0),     "0\n", 'clean - zero');
    my $rh_tests = {'  , abc , def ,, ghi , ' => "abc, def, ghi\n",};

    while (my ($source, $expected) = each(%$rh_tests)) {
        is($GAF->_clean($source), $expected, 'clean - ' . $source);
    }
}

{
    # keep in mind this is using the test conf, not the real address-formatting conf
    is($GAF->_add_state_code({}), undef);
    is($GAF->_add_state_code({country_code => 'BR', state => 'Sao Paulo'}),  undef);
    is($GAF->_add_state_code({country_code => 'us', state => 'California'}), 'CA');

    # correct state and add state_code if code was in state field
    my $rh_comp = {
        country_code => 'IT',
        state        => 'PUG',
    };
    $GAF->_add_state_code($rh_comp);
    is($rh_comp->{state},      'Puglia', 'corrected state to Puglia');
    is($rh_comp->{state_code}, 'PUG',    'state_code is PUG');

    # correct state and add state_code if code was in state field
    my $rh_comp2 = {
        country_code => 'IT',
        state        => 'PUG',
        state_code   => 'PUG',
    };
    $GAF->_add_state_code($rh_comp2);
    is($rh_comp2->{state},      'Puglia', 'corrected state to Puglia');
    is($rh_comp2->{state_code}, 'PUG',    'state_code is PUG');


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
    is($rh_c->{county},      'Roma', 'corrected county to Roma');
    is($rh_c->{county_code}, 'RM',   'set county_code to RM');
}

{
    my $components = {street => 'Hello World',};

    is_deeply($GAF->_apply_replacements(clone($components), []), $components);
    is_deeply($GAF->_apply_replacements(clone($components), [['^Hello', 'Bye'], ['d', 't']]), {street => 'Bye Worlt'});

    warning_like {
        is_deeply($GAF->_apply_replacements(clone($components), [['((ll', '']]), $components);
    }
    qr/invalid replacement/, 'got warning';
}

{
    my $components = {
        'continent'    => 'Antarctica',
        'country_code' => ''
    };
    $GAF->_sanity_cleaning($components), is_deeply($components, {'continent' => 'Antarctica'}, '_sanity_cleaning');
}

{
    is_deeply($GAF->_find_unknown_components({one => 1, four => 4}), ['four'], '_find_unknown_components');
}


{
    my $THT = Text::Hogan::Compiler->new->compile('abc {{#first}} {{one}} || {{two}} {{/first}} def');
    is($GAF->_render_template($THT, {two => 2}), "abc 2 def\n", '_render_template - first');
}


{
    # uses test conf
    my $GAF  = $CLASS->new(conf_path => $path);
    my $rh_components = {
        'country_code'  => 'DE',
        'city'          => 'Heilbad Heiligenstadt',
        'county'        => 'Landkreis Eichsfeld',
        'state'         => 'Thüringen',
        'country'       => 'Deutschland',
    };
    my $formatted = $GAF->format_address($rh_components);
    $formatted =~ s/\n$//g;  # remove from end
    $formatted =~ s/\n/, /g; # turn into commas

    is( $formatted,
        'Heilbad Heiligenstadt, Eichsfeld, Thüringen, Deutschland',
        'correctly formatted DE with fallback and replace'
    );
}

{
    # uses test conf
    my $GAF  = $CLASS->new(conf_path => $path);
    my $rh_components = {
        'country_code' => 'DE',
        'one'          => 'Heilbad Heiligenstadt',        
        'two'          => 'Landkreis Eichsfeld',
        'three'        => 'Deutschland',
        'road'         => 'Rosenstraße',  # needed to avoid fallback
        'postcode'     => '37308',        # needed to avoid fallback        
    };
    my $formatted = $GAF->format_address($rh_components);
    $formatted =~ s/\n$//g;  # remove from end
    $formatted =~ s/\n/, /g; # turn into commas

    is( $formatted,
        'Heilbad Heiligenstadt, Eichsfeld, Deutschland',
        'correctly formatted DE with default and replace'
    );
}

# actually do some formatting
{
    my $af_path   = dirname(__FILE__) . '/../../address-formatting';
    my $conf_path = $af_path . '/conf/';
    my $GAF       = $CLASS->new(conf_path => $conf_path);

    my $rh_components = {
        'country_code'  => 'US',
        'house_number'  => '301',
        'road'          => 'Northwestern University Road',
        'neighbourhood' => 'Crescent Park',
        'city'          => 'Palo Alto',
        'postcode'      => '94303',
        'county'        => 'Santa Clara County',
        'state'         => 'California',
        'country'       => 'United States',
    };

    # final_components not yet set, so this should cause a warning
    warning_like {
        $GAF->final_components();
    }
    qr/not yet set/, 'got final_components warning';

    my $formatted = $GAF->format_address($rh_components);
    $formatted =~ s/\n$//g;  # remove from end
    $formatted =~ s/\n/, /g; # turn into commas

    is( $formatted,
        '301 Northwestern University Road, Palo Alto, CA 94303, United States of America',
        'correctly formatted components'
    );

    # now we can get the final_components
    my $rh_fincomp = $GAF->final_components();
    is($rh_fincomp->{state_code}, 'CA', 'set state_code correctly');

    $rh_components = {
        'city'          => 'Barcelona',
        'city_district' => "Sarrià - Sant Gervasi",
        'country'       => 'Spain',
        'country_code'  => 'es',
        'county'        => 'Barcelonès',
        'house_number'  => '68',
        'postcode'      => '08017',
        'road'          => 'Carrer de Calatrava',
        'state'         => 'Cataluña',
        'suburb'        => 'les Tres Torres'
    };

    $formatted = $GAF->format_address($rh_components);
    $formatted =~ s/\n$//g;  # remove from end
    $formatted =~ s/\n/, /g; # turn into commas

    is($formatted, 'Carrer de Calatrava, 68, 08017 Barcelona, Spain', 'correctly formatted components');

    # now we can get the final_components
    $rh_fincomp = $GAF->final_components();
    is($rh_fincomp->{state_code},  'CT', 'set state_code correctly');
    is($rh_fincomp->{county_code}, 'B',  'set county_code correctly');
}



# test post_formatting
# actually do some formatting
{
    my $af_path   = dirname(__FILE__) . '/../../address-formatting';
    my $conf_path = $af_path . '/conf/';
    my $GAF       = $CLASS->new(conf_path => $conf_path);

    my %pftests = (
        'Berlin, Berlin' => {
            'input'    => 'Berlin, Berlin, Germany',
            'expected' => 'Berlin, Germany',
        },
        'New York, New York' => {
            'input'    => 'New York, New York, USA',
            'expected' => 'New York, New York, USA',
        },
    );

    foreach my $tname (sort keys %pftests) {
        my $input    = $pftests{$tname}->{input};
        my $expected = $pftests{$tname}->{expected};
        is($GAF->_postformat($input), $expected, 'testing _postformat ' . $tname,);
    }

}
done_testing();

1;
