use strict;
use constant TEST_COUNT => 32;
use Test::More tests => TEST_COUNT;

BEGIN {
	use_ok('HTML::Menu::DateTime');
}

SKIP: {
  eval { require HTML::Menu::Select };
  
  skip("HTML::Menu::Select not installed", TEST_COUNT-1) if $@;
  
  my $dt = HTML::Menu::DateTime->new(
    date => '200106070809',
    html => 'menu',
  );
  
  
  { # METHOD SELECTION
    # BASIC
    my $html = $dt->second_menu('05');
    
    ok( $html =~ /<select name="">/ );
    ok( $html =~ /<option value="01">01<\/option>/ );
    ok( $html =~ /<option selected="selected" value="05">05<\/option>/ );
    ok( $html =~ /<option value="59">59<\/option>/ );
    ok( $html =~ /<\/select>/ );
  }
  
  { # CONSTRUCTOR SELECTION
    # BASIC
    my $html = $dt->minute_menu();
    
    ok( $html =~ /<select name="">/ );
    ok( $html =~ /<option value="01">01<\/option>/ );
    ok( $html =~ /<option selected="selected" value="09">09<\/option>/ );
    ok( $html =~ /<option value="59">59<\/option>/ );
    ok( $html =~ /<\/select>/ );
  }
  
  { # NAME
    my $html = $dt->day_menu( {name => 'myMenu'} );
    
    ok( $html =~ /<select name="myMenu">/ );
    ok( $html =~ /<option value="01">01<\/option>/ );
    ok( $html =~ /<option selected="selected" value="07">07<\/option>/ );
    ok( $html =~ /<option value="31">31<\/option>/ );
    ok( $html =~ /<\/select>/ );
  }
  
  { # 2 ARGS
    my $html = $dt->minute_menu( '03', {name => 'mySelect'} );
    
    ok( $html =~ /<select name="mySelect">/ );
    ok( $html =~ /<option value="01">01<\/option>/ );
    ok( $html =~ /<option selected="selected" value="03">03<\/option>/ );
    ok( $html =~ /<option value="59">59<\/option>/ );
    ok( $html =~ /<\/select>/ );
  }
  
  { # HTML SETTER
    # OVERRIDE CONSTRUCTOR SECOND VALUE
    
    $dt->html( 'options' );
    
    my $html = $dt->second_menu('10');
    
    ok( $html !~ /\bselect\b/ );
    
    ok( $html =~ /<option value="01">01<\/option>/ );
    ok( $html =~ /<option selected="selected" value="10">10<\/option>/ );
    ok( $html =~ /<option value="59">59<\/option>/ );
  }
  
  { # HTML SETTER
    # ATTRIBUTES
    
    $dt->html( 'menu' );
    
    my $html = $dt->hour_menu(
      {
        name       => 'myHour',
        attributes => {
          '00' => {style => 'bgcolor: #f00;'},
        },
      });
    
    ok( $html =~ /<select name="myHour">/ );
    ok( $html =~ /<option style="bgcolor: #f00;" value="00">00<\/option>/ );
    ok( $html =~ /<option selected="selected" value="08">08<\/option>/ );
    ok( $html =~ /<option value="23">23<\/option>/ );
    ok( $html =~ /<\/select>/ );
  }
  
  { # INVALID HTML OPTION
    
    eval {
      $dt->html( 'unknown' );
      
      my $html = $dt->hour_menu; 
    };
    
    ok( $@, 'correctly dies on invalid html() option' );
  }
  
  { # RESET BACK TO NON-HTML
    
    $dt->html( undef );
    
    my $array_ref = $dt->second_menu;
    
    ok( ref $array_ref eq 'ARRAY', 'html( undef )' );
  }
}

