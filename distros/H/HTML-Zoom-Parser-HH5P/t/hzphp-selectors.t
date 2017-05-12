use strictures 1;
use Test::More;

use HTML::Zoom;

my $tmpl = <<END;
<body>
  <div class="main">
    <span prop='moo' class="hilight name">Bob</span>
    <span class="career">Builder</span>
    <hr />
  </div>
</body>
END

my $stub = '<div class="waargh"></div>';

my $output = HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } );
# el#id
is( HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )
   ->from_html('<div id="yo"></div>'.$stub)
   ->select('div#yo')
      ->replace_content('grg')
   ->to_html,
   '<div id="yo">grg</div>'.$stub,
   'E#id works' );

# el.class1
is( HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )
   ->from_html('<div class="yo"></div>'.$stub)
   ->select('div.yo')
      ->replace_content('grg')
   ->to_html,
   '<div class="yo">grg</div>'.$stub,
   'E.class works' );


# el.class\.1
is( HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )
   ->from_html('<div class="yo.yo"></div>'.$stub)
   ->select('div.yo\.yo')
      ->replace_content('grg')
   ->to_html,
   '<div class="yo.yo">grg</div>'.$stub,
   'E.class\.0 works' );

# el[attr]
is( HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )
   ->from_html('<div frew="yo"></div>'.$stub)
   ->select('div[frew]')
      ->replace_content('grg')
   ->to_html,
   '<div frew="yo">grg</div>'.$stub,
   'E[attr] works' );

# *[attr]
is( HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )
   ->from_html('<div frew="yo"></div><span frew="ay"></span>'.$stub)
   ->select('*[frew]')
      ->replace_content('grg')
   ->to_html,
   '<div frew="yo">grg</div><span frew="ay">grg</span>'.$stub,
   '*[attr] works' );

# el[attr="foo"]
is( HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )
   ->from_html('<div frew="yo"></div>'.$stub)
   ->select('div[frew="yo"]')
      ->replace_content('grg')
   ->to_html,
   '<div frew="yo">grg</div>'.$stub,
   'E[attr="val"] works' );

# el[attr=foo]
is( HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )
   ->from_html('<div frew="yo"></div>'.$stub)
    ->select('div[frew=yo]')
    ->replace_content('grg')
    ->to_html,
    '<div frew="yo">grg</div>'.$stub,
    'E[attr=val] works' );

# el[attr=foo\.bar]
is( HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )
   ->from_html('<div frew="yo.yo"></div>'.$stub)
    ->select('div[frew=yo\.yo]')
    ->replace_content('grg')
    ->to_html,
    '<div frew="yo.yo">grg</div>'.$stub,
    'E[attr=foo\.bar] works' );

# el[attr!="foo"]
is( HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )
   ->from_html('<div f="f"></div><div class="quux"></div>'.$stub)
    ->select('div[class!="waargh"]')
       ->replace_content('grg')
    ->to_html,
    '<div f="f">grg</div><div class="quux">grg</div>'.$stub,
    'E[attr!="val"] works' );

# el[attr*="foo"]
is( HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )
   ->from_html('<div f="frew goog"></div>'.$stub)
   ->select('div[f*="oo"]')
      ->replace_content('grg')
   ->to_html,
   '<div f="frew goog">grg</div>'.$stub,
   'E[attr*="val"] works' );

# el[attr^="foo"]
is( HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )
   ->from_html('<div f="foobar"></div>'.$stub)
   ->select('div[f^="foo"]')
      ->replace_content('grg')
   ->to_html,
   '<div f="foobar">grg</div>'.$stub,
   'E[attr^="val"] works' );

# el[attr$="foo"]
is( HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )
   ->from_html('<div f="foobar"></div>'.$stub)
   ->select('div[f$="bar"]')
      ->replace_content('grg')
   ->to_html,
   '<div f="foobar">grg</div>'.$stub,
   'E[attr$="val"] works' );

# el[attr*="foo"]
is( HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )
   ->from_html('<div f="foo bar"></div>'.$stub)
   ->select('div[f*="bar"]')
      ->replace_content('grg')
   ->to_html,
   '<div f="foo bar">grg</div>'.$stub,
   'E[attr*="val"] works' );

# el[attr~="foo"]
is( HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )
   ->from_html('<div frew="foo bar baz"></div>'.$stub)
   ->select('div[frew~="bar"]')
      ->replace_content('grg')
   ->to_html,
   '<div frew="foo bar baz">grg</div>'.$stub,
   'E[attr~="val"] works' );

# el[attr|="foo"]
is( HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )
   ->from_html('<div lang="pl"></div><div lang="english"></div>'.
                          '<div lang="en"></div><div lang="en-US"></div>'.$stub)
   ->select('div[lang|="en"]')
      ->replace_content('grg')
   ->to_html,
   '<div lang="pl"></div><div lang="english"></div>'.
   '<div lang="en">grg</div><div lang="en-US">grg</div>'.$stub,
   'E[attr|="val"] works' );

# [attr=bar]
ok( check_select( '[prop=moo]'), '[attr=bar]' );

# el[attr=bar],[prop=foo]
is( check_select('span[class=career],[prop=moo]'), 2,
    'Multiple selectors: el[attr=bar],[attr=foo]');


# selector parse error test:
eval{
    HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )
     ->from_html('<span att="bar"></span>')
      ->select('[att=bar')
      ->replace_content('cats')
          ->to_html;
};
like( $@, qr/Error parsing dispatch specification/,
      'Malformed attribute selector ([att=bar) results in a helpful error' );


TODO: {
local $TODO = "descendant selectors doesn't work yet";
# sel1 sel2
is( eval { HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )
   ->from_html('<table><tr></tr><tr></tr></table>')
   ->select('table tr')
      ->replace_content('<td></td>')
   ->to_html },
   '<table><tr><td></td></tr><tr><td></td></tr></table>',
   'sel1 sel2 works' );
diag($@) if $@;

# sel1 sel2 sel3
is( eval { HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )
   ->from_html('<table><tr><td></td></tr><tr><td></td></tr></table>')
   ->select('table tr td')
      ->replace_content('frew')
   ->to_html },
   '<table><tr><td>frew</td></tr><tr><td>frew</td></tr></table>',
   'sel1 sel2 sel3 works' );
diag($@) if $@;
}

done_testing;


sub check_select {
    # less crude?:
    my $output = HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )
   ->from_html($tmpl)
    ->select(shift)->replace("the monkey")->to_html;
    my $count = 0;
    while ( $output =~ /the monkey/g ){
        $count++;
    }
    return $count;
}
