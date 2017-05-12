use Test::Simple 'no_plan';
use strict;
use lib './lib';
use Cwd;
use HTML::Template::Default;
$HTML::Template::Default::DEBUG = 1;

#$ENV{TMPL_PATH} = cwd().'/t/templates';
$ENV{HTML_TEMPLATE_ROOT} = cwd().'/t/templates';

my $default = '
   <html>
   <head>
   <title><TMPL_VAR TITLE></title>
   
   </head>
   <body>
   I AM DEFAULT
   <h1><TMPL_VAR TITLE></h1>
   <p><TMPL_VAR CONTENT></p>   
   </body>
   </html>
';

my ( $tmpl, $output);



step('regular..');
$tmpl = HTML::Template::Default->new(
   filename => 'super.html',
   scalarref => \$default,
);
ok( $tmpl, 'instanced');

$output = $tmpl->output;
ok( $output=~/I AM DEFAULT/, 'output was of default template' );






step('2');
$tmpl = HTML::Template::Default->new(
   scalarref => \$default,
);
ok( $tmpl, 'instanced');






step('3 expecting death');
ok( ! eval {
   $tmpl = HTML::Template::Default->new(
      filename => 'super.html',
   );
}, 'not instanced' );







step('try from disk');
-f "$ENV{HTML_TEMPLATE_ROOT}/duper.html" or die("missing file, can't test, $!");


$tmpl = HTML::Template::Default->new(
   filename => 'duper.html',
   scalarref => \$default,
);

ok($tmpl,'instanced');

$output = $tmpl->output;
ok( $output=~/FROM DISK XYZ/,'correct, is from disk' );





exit;
sub step {
   printf STDERR "\n\n%s\n%s\n\n", '='x80,"@_";
}
   
