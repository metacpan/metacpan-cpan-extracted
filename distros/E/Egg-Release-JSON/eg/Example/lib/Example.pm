package Example;
use strict;
use warnings;
use Egg qw/ -Debug
  Dispatch::Fast
  Debugging
  JSON
  LWP
  /;

our $VERSION= '0.01';

__PACKAGE__->egg_startup(

  title      => 'Example',
  root       => '/path/to/Example',
  static_uri => '/',
  dir => {
    lib      => '< $e.root >/lib',
    static   => '< $e.root >/htdocs',
    etc      => '< $e.root >/etc',
    cache    => '< $e.root >/cache',
    tmp      => '< $e.root >/tmp',
    template => '< $e.root >/root',
    comp     => '< $e.root >/comp',
    },
  template_path=> ['< $e.dir.template >', '< $e.dir.comp >'],

  VIEW=> [

    [ Template=> {
      .....
      ...
      } ],

    [ JSON => {
      content_type=> 'application/rss+xml',
      charset     => 'UTF-8',
      option      => { pretty => 1, indent => 2 },
      } ],

    ],

  );

# Dispatch. ------------------------------------------------
__PACKAGE__->run_modes(
  ajax_page    => sub { $_[0]->template('/ajax_page.tt') },
  json_data    => \&json_data,
  json_request => \&json_request,
  );
# ----------------------------------------------------------

sub json_data {
	my($e)= @_;
	$e->default_view('JSON')->obj({
	 is_success=> 1,
	 message=> 'OK',
	 });
}
sub json_request {
	my($e)= @_;
	my $res= $e->get_json( GET=> 'http://domainname/json/hoge.js' );
	my $obj;
	if ($res->is_success and $obj= $res->obj) {
		@{$e->stash}{keys %$obj}= values %$obj;
		$e->template('/json_request.tt');
	} else {
		$e->debug_out($res->is_error);
		$e->finished(500);
	}
}

1;
