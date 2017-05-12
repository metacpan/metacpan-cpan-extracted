#!/usr/bin/perl -w

use lib '.'; use lib 't';
use WMTest; webmake_t_init("defwmktags");
use Test; BEGIN { plan tests => 5 };

# ---------------------------------------------------------------------------

$file = q{
  <webmake>
  <{perl
      define_wmk_tag ("bar", \&mk_bar, qw(name inside));
      define_empty_wmk_tag ("baz", \&mk_baz, qw(name inside));

      sub mk_bar {
	my ($tagname, $attrs, $text, $perlcode) = @_;
	"<content name=".$attrs->{name}.">".$attrs->{inside}."</content>";
      }

      sub mk_baz {
	my ($tagname, $attrs, $text, $perlcode) = @_;
	"<content name=".$attrs->{name}.">".$attrs->{inside}."</content>";
      }
  }>

  <bar name="foo" inside="Foo! Foo!"></bar>
  <baz name="baz" inside="Baz! Baz!" />

  <out file=log/defwmktags.html>${foo}${baz}</out>
  </webmake>
};

# ---------------------------------------------------------------------------

%patterns = (
  q{Foo! Foo!}, 'bar_tag',
  q{Baz! Baz!}, 'baz_tag',
);

# ---------------------------------------------------------------------------

wmfile ($file);
ok (wmrun ("-F -f log/test.wmk", \&patterns_run_cb));
ok_all_patterns();

