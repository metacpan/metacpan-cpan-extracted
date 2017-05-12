#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use utf8;

use_ok('Inky');

sub inky_compare {
    my ($name, $input, $expected) = @_;

    $expected =~ s{\n\s*}{}gxms;
    $expected =~ s{\A\s*}{}xms;
    $expected =~ s{>\s+}{>}xms;
    chomp $expected;

    my $inky   = Inky->new;
    my $output = $inky->release_the_kraken($input);

    $output =~ s{\n\s*}{}gxms;
    $output =~ s{\A\s*}{}xms;
    $output =~ s{>\s+}{>}xms;
    chomp $output;

    ok($expected eq $output, "same output for test $name")
        or diag "BAD TEST $name: expected:\n$expected\nGot:\n$output\n";
}

# See https://github.com/zurb/inky/blob/master/test/inky.js

inky_compare('simple inline element',
    '<container>This is a link to <a href="#">ZURB.com</a>.</container>',
    <<'END');
<table align="center" class="container">
    <tbody>
        <tr>
            <td>This is a link to <a href="#">ZURB.com</a>.</td>
        </tr>
    </tbody>
</table>
END

inky_compare('does not choke on inline elements',
    '<container>This is a link to <a href="#">ZURB.com</a>.</container>',
    <<'END');
<table align="center" class="container">
     <tbody>
         <tr>
            <td>This is a link to <a href="#">ZURB.com</a>.</td>
         </tr>
     </tbody>
</table>
END

inky_compare('special characters',
    '<container>This is a link tø <a href="#">ZURB.com</a>.</container>',
    <<'END');
<table align="center" class="container">
    <tbody>
        <tr>
            <td>This is a link tø <a href="#">ZURB.com</a>.</td>
        </tr>
    </tbody>
</table>
END

# See tests on https://github.com/zurb/inky/blob/master/test/grid.js

inky_compare('simple html doc with container',
    '<!doctype html><html><head></head><body><container></container></body></html>',
    <<'END');
    <!DOCTYPE html>
    <html>
        <head>
        </head>
        <body>
            <table align="center" class="container">
                <tbody>
                    <tr>
                        <td></td>
                    </tr>
                </tbody>
            </table>
        </body>
    </html>
END

inky_compare('create a container table',
    '<container></container>',
    '<table align="center" class="container"><tbody><tr><td></td></tr></tbody></table>');

inky_compare('create a row',
    '<row></row>',
    '<table class="row"><tbody><tr></tr></tbody></table>');

inky_compare('create a single column with first and last classes',
    '<columns large="12" small="12">One</columns>',
    <<'END');
<th class="small-12 large-12 columns first last">
    <table>
        <tr>
            <th>One</th>
            <th class="expander"></th>
        </tr>
    </table>
</th>
END

inky_compare('creates a single column with first and last classes with no-expander',
    '<columns large="12" small="12" no-expander>One</columns>',
    <<'END');
<th class="small-12 large-12 columns first last">
  <table>
    <tr>
      <th>One</th>
    </tr>
  </table>
</th>
END

inky_compare('creates a single column with first and last classes with no-expander="false"',
    '<columns large="12" small="12" no-expander="false">One</columns>',
    <<'END');
<th class="small-12 large-12 columns first last">
  <table>
    <tr>
      <th>One</th>
      <th class="expander"></th>
    </tr>
  </table>
</th>
END

inky_compare('creates a single column with first and last classes with no-expander="true"',
    '<columns large="12" small="12" no-expander="true">One</columns>',
    <<'END');
<th class="small-12 large-12 columns first last">
  <table>
    <tr>
      <th>One</th>
    </tr>
  </table>
</th>
END

inky_compare('create two columns, one first, one last',
    '<columns large="6" small="12">One</columns><columns large="6" small="12">Two</columns>',
    <<'END');
<th class="small-12 large-6 columns first">
<table>
  <tr>
    <th>One</th>
  </tr>
</table>
</th>
<th class="small-12 large-6 columns last">
<table>
  <tr>
    <th>Two</th>
  </tr>
</table>
</th>
END

inky_compare('create 3+ columns, first is first, last is last',
    <<'INPUT', <<'OUTPUT');
    <columns large="4" small="12">One</columns>
    <columns large="4" small="12">Two</columns>
    <columns large="4" small="12">Three</columns>
INPUT
  <th class="small-12 large-4 columns first">
    <table>
      <tr>
        <th>One</th>
      </tr>
    </table>
  </th>
  <th class="small-12 large-4 columns">
    <table>
      <tr>
        <th>Two</th>
      </tr>
    </table>
  </th>
  <th class="small-12 large-4 columns last">
    <table>
      <tr>
        <th>Three</th>
      </tr>
    </table>
  </th>
OUTPUT

inky_compare('transfer classes to the final HTML',
    '<columns class="small-offset-8 hide-for-small">One</columns>',
    <<'END');
    <th class="small-offset-8 hide-for-small small-12 large-12 columns first last">
        <table>
            <tr>
                <th>One</th>
                <th class="expander"></th>
            </tr>
        </table>
    </th>
END

inky_compare('automatically assigns large columns if no large attribute is assigned',
    '<columns small="4">One</columns><columns small="8">Two</columns>',
    <<'END');
<th class="small-4 large-4 columns first">
    <table>
        <tr>
            <th>One</th>
        </tr>
    </table>
</th>
<th class="small-8 large-8 columns last">
    <table>
        <tr>
            <th>Two</th>
        </tr>
    </table>
</th>
END

inky_compare('automatically assigns small columns as full width if only large defined',
    '<columns large="4">One</columns><columns large="8">Two</columns>',
    <<'END');
<th class="small-12 large-4 columns first">
    <table>
        <tr>
            <th>One</th>
        </tr>
    </table>
</th>
<th class="small-12 large-8 columns last">
    <table>
        <tr>
            <th>Two</th>
        </tr>
    </table>
</th>
END

inky_compare('supports nested grids',
    '<row><columns><row></row></columns></row>',
    <<'END');
<table class="row">
    <tbody>
        <tr>
            <th class="small-12 large-12 columns first last">
                <table>
                    <tr>
                        <th>
                            <table class="row">
                                <tbody>
                                    <tr></tr>
                                </tbody>
                            </table>
                        </th>
                    </tr>
                </table>
            </th>
        </tr>
    </tbody>
</table>
END

inky_compare('block grid',
    '<block-grid up="4"></block-grid>',
    <<'END');
<table class="block-grid up-4">
    <tr></tr>
</table>
END

inky_compare('block-grid copies classes to the final HTML output',
    '<block-grid up="4" class="show-for-large"></block-grid>',
    <<'END');
<table class="block-grid up-4 show-for-large">
    <tr></tr>
</table>
END

# https://github.com/zurb/inky/blob/master/test/components.js

inky_compare('applies a text-center class and center alignment attribute to the first child',
    '<center><div></div></center>',
    <<'END');
<center data-parsed="">
    <div align="center" class="float-center"></div>
</center>
END

inky_compare('does not choke if center tags are nested',
    '<center><center></center></center>',
    <<'END');
<center data-parsed="">
    <center align="center" class="float-center" data-parsed="">
    </center>
</center>
END

inky_compare('transfers attributes to the final HTML',
    '<row dir="rtl"><columns dir="rtl" valign="middle" align="center">One</columns></row>',
    <<'END');
<table class="row" dir="rtl">
  <tbody>
     <tr>
      <th align="center" class="small-12 large-12 columns first last" dir="rtl" valign="middle">
        <table>
          <tr>
            <th>One</th>
            <th class="expander"></th>
          </tr>
        </table>
      </th>
     </tr>
  </tbody>
</table>
END

inky_compare('applies the class float-center to <item> elements',
    '<center><menu><item href="#"></item></menu></center>',
    <<'END');
<center data-parsed="">
    <table align="center" class="menu float-center">
        <tr>
            <td>
                <table>
                    <tr>
                        <th class="menu-item float-center">
                            <a href="#"></a>
                        </th>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</center>
END

inky_compare('creates a simple button',
    '<button href="http://zurb.com">Button</button>',
    <<'END');
<table class="button">
    <tr>
        <td>
            <table>
                <tr>
                    <td><a href="http://zurb.com">Button</a></td>
                </tr>
            </table>
        </td>
    </tr>
</table>
END

inky_compare('creates a button with classes',
    '<button class="small alert" href="http://zurb.com">Button</button>',
    <<'END');
<table class="button small alert">
    <tr>
        <td>
            <table>
                <tr>
                    <td><a href="http://zurb.com">Button</a></td>
                </tr>
            </table>
        </td>
    </tr>
</table>
END

inky_compare('create a correct expanded button',
    '<button class="expand" href="http://zurb.com">Button</button>',
    <<'END');
<table class="button expand">
    <tr>
        <td>
            <table>
                <tr>
                    <td>
                        <center data-parsed=""><a align="center" class="float-center" href="http://zurb.com">Button</a></center>
                    </td>
                </tr>
            </table>
        </td>
        <td class="expander"></td>
    </tr>
</table>
END

inky_compare('creates a button with target="_blank"',
    '<button href="http://zurb.com" target="_blank">Button</button>',
    <<'END');
<table class="button">
  <tr>
    <td>
      <table>
        <tr>
          <td><a href="http://zurb.com" target="_blank">Button</a></td>
        </tr>
      </table>
    </td>
  </tr>
</table>
END

inky_compare('creates a menu with item tags inside',
    '<menu><item href="http://zurb.com">Item</item></menu>',
    <<'END');
<table class="menu">
    <tr>
        <td>
            <table>
                <tr>
                    <th class="menu-item"><a href="http://zurb.com">Item</a></th>
                </tr>
            </table>
        </td>
    </tr>
</table>
END

inky_compare('creates a menu with items tags inside, containing target="_blank" attribute',
    '<menu><item href="http://zurb.com" target="_blank">Item</item></menu>',
    <<'END');
<table class="menu">
  <tr>
    <td>
      <table>
        <tr>
          <th class="menu-item"><a href="http://zurb.com" target="_blank">Item</a></th>
        </tr>
      </table>
    </td>
  </tr>
</table>
END

inky_compare('creates a menu with classes',
    '<menu class="vertical"></menu>',
    <<'END');
<table class="menu vertical">
    <tr>
        <td>
            <table>
                <tr>
                </tr>
            </table>
        </td>
    </tr>
</table>
END

inky_compare('creates a menu without item tag',
    '<menu><th class="menu-item"><a href="http://zurb.com">Item 1</a></th></menu>',
    <<'END');
<table class="menu">
    <tr>
        <td>
            <table>
                <tr>
                    <th class="menu-item"><a href="http://zurb.com">Item 1</a></th>
                </tr>
            </table>
        </td>
    </tr>
</table>
END

inky_compare('creates a callout with correct syntax',
    '<callout>Callout</callout>',
    <<'END');
<table class="callout">
    <tr>
        <td class="callout-inner">Callout</td>
        <td class="expander"></td>
    </tr>
</table>
END

inky_compare('callout copies classes to the final HTML',
    '<callout class="primary">Callout</callout>',
    <<'END');
<table class="callout">
    <tr>
        <td class="callout-inner primary">Callout</td>
        <td class="expander"></td>
    </tr>
</table>
END

# Using Mojo::DOM, &#xA0; or &nbsp; gets replaced with the actual character
inky_compare('creates a spacer element with correct size',
    '<spacer size="10"></spacer>',
    <<"END");
<table class="spacer">
    <tbody>
        <tr>
            <td height="10px" style="font-size:10px;line-height:10px;">\xA0</td>
        </tr>
    </tbody>
</table>
END

inky_compare('creates a spacer with a default size or no size defined',
    '<spacer></spacer>',
    <<"END");
<table class="spacer">
  <tbody>
    <tr>
      <td height="16px" style="font-size:16px;line-height:16px;">\xA0</td>
    </tr>
  </tbody>
</table>
END

inky_compare('creates a spacer element for small screens with correct size',
    '<spacer size-sm="10"></spacer>',
    <<"END");
<table class="spacer hide-for-large">
  <tbody>
    <tr>
      <td height="10px" style="font-size:10px;line-height:10px;">\xA0</td>
    </tr>
  </tbody>
</table>
END

inky_compare('creates a spacer element for large screens with correct size',
    '<spacer size-lg="20"></spacer>',
    <<"END");
<table class="spacer show-for-large">
  <tbody>
    <tr>
      <td height="20px" style="font-size:20px;line-height:20px;">\xA0</td>
    </tr>
  </tbody>
</table>
END

inky_compare('creates a spacer element for small and large screens with correct sizes',
    '<spacer size-sm="10" size-lg="20"></spacer>',
    <<"END");
<table class="spacer hide-for-large">
  <tbody>
    <tr>
      <td height="10px" style="font-size:10px;line-height:10px;">\xA0</td>
    </tr>
  </tbody>
</table>
<table class="spacer show-for-large">
  <tbody>
    <tr>
      <td height="20px" style="font-size:20px;line-height:20px;">\xA0</td>
    </tr>
  </tbody>
</table>
END

inky_compare('copies classes to the final spacer HTML',
    '<spacer size="10" class="bgcolor"></spacer>',
    <<"END");
<table class="spacer bgcolor">
    <tbody>
        <tr>
            <td height="10px" style="font-size:10px;line-height:10px;">\xA0</td>
        </tr>
    </tbody>
</table>
END

inky_compare('creates a wrapper that you can attach classes to',
    '<wrapper class="header"></wrapper>',
    <<'END');
<table align="center" class="wrapper header">
    <tr>
        <td class="wrapper-inner"></td>
    </tr>
</table>
END

inky_compare('raw',
    q!<raw><<LCG Program\TG LCG Coupon Code Default='246996'>></raw>!,
    q!<<LCG Program\TG LCG Coupon Code Default='246996'>>!);

inky_compare('does not muck with stuff inside raw',
    '<raw><%= test %></raw>',
    '<%= test %>');

inky_compare('can handle multiple raw tags',
    '<h1><raw><%= test %></raw></h1><h2>< raw >!!!</ raw ></h2>',
    '<h1><%= test %></h1><h2>!!!</h2>');

done_testing;
