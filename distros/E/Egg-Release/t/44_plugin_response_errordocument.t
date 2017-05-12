use Test::More;
use lib qw( ./lib ../lib );
use Egg::Helper;

my %c;
eval{ require HTML::Mason };
if ($@) {
	eval{ require HTML::Template };
	unless ($@) {
		$c{VIEW}= [
		  [ HT => {
		    path=> [qw/ \<e.dir.template> \<e.dir.comp> /],
		    } ],
		  ];
	}
} else {
	$c{VIEW}= [
	  [ Mason => {
	    comp_root=> [
	      [ main   => '\<e.dir.template>' ],
	      [ private=> '\<e.dir.comp>' ],
	      ],
	    data_dir=> '\<e.dir.tmp>',
	    } ],
	  ];
}
unless ($c{VIEW})
{ plan skip_all=> "'HTML::Mason' or 'HTML::Template' is not installed." } else {

plan tests=> 31;

ok $e= Egg::Helper->run( Vtest => { %c,
  vtest_plugins=> [qw/ Response::ErrorDocument /],
  plugin_response_errordocument=> {
    template=> 'error_document.tt',
    },
  }), q{load plugin.};

my $tt= $e->helper_yaml_load(join '', <DATA>);

$e->helper_create_file({
  filename=> '<e.dir.comp>/error_document.tt',
  value=> $tt->{$e->config->{VIEW}[0][0]},
  }, $e->config );
$e->helper_create_dir( $e->config->{root}. "/tmp" );

ok $e->finished('404 Not Found'),
     q{$e->finished('404 Not Found')};
  ok my $res= $e->helper_stdout(sub { $e->_output }),
     q{my $res= $e->helper_stdout( ... };
  ok ! $res->error, q{! $res->error };
  ok response_check($e), q{response_check($e)};

ok ! $e->finished(0), q{! $e->finished(0)};
ok ! $e->res->clear_body, q{! $e->res->clear_body};
ok $e->view_manager->reset_context($e->view_manager->default),
   q{$e->view_manager->reset_context($e->view_manager->default)};

ok $e->finished('403 Forbidden'),
     q{$e->finished('403 Forbidden')};
  ok $res= $e->helper_stdout(sub { $e->_output }),
     q{$res= $e->helper_stdout( ... };
  ok ! $res->error, q{! $res->error };
  ok response_check($e), q{response_check($e)};

ok ! $e->finished(0), q{! $e->finished(0)};
ok ! $e->res->clear_body, q{! $e->res->clear_body};
ok $e->view_manager->reset_context($e->view_manager->default),
   q{$e->view_manager->reset_context($e->view_manager->default)};

ok $e->finished('500 Internal Server Error'),
     q{$e->finished('500 Internal Server Error')};
  ok $res= $e->helper_stdout(sub { $e->_output }),
     q{$res= $e->helper_stdout( ... };
  ok ! $res->error, q{! $res->error };
  ok response_check($e), q{response_check($e)};

}
sub response_check {
	my($e)= @_;
	my $status= $e->res->status;
	my $string= $e->res->status_string;
	   $string=~s{^\s+} [];
	my $string_uc= uc($string);
	my $body= $e->res->body;
	like $$body, qr{<html.*>.+?</html>}s,
	     "\$\$body, qr{<html.*>.+?</html>}s";
	like $$body, qr{<title>$status +\- +$string</title>}s,
	     "\$\$body, qr{<title>$status +\\- +$string</title>}s";
	like $$body, qr{<h1>$status +\- +$string</h1>}s,
	     "\$\$body, qr{<h1>$status +\\- +$string</h1>}s";
	like $$body, qr{<div> *$string_uc</div>}s,
	     "\$\$body, qr{<div> *$string_uc</div>}s";
}

__DATA__
Mason: |
  <html>
  <head><title><% $e->page_title %></title></head>
  <body>
  <h1><% $e->page_title %></h1>
  <div><% uc($e->res->status_string) %></div>
  </body>
  </html>
  
HT: |
  <html>
  <head><title><TMPL_VAR NAME="page_title"></title></head>
  <body>
  <h1><TMPL_VAR NAME="page_title"></h1>
  <TMPL_IF NAME="status_404">
    <div>NOT FOUND</div>
  <TMPL_ELSE><TMPL_IF NAME="status_403">
    <div>FORBIDDEN</div>
  <TMPL_ELSE>
    <div>INTERNAL SERVER ERROR</div>
  </TMPL_IF></TMPL_IF>
  </body>
  </html>
  
