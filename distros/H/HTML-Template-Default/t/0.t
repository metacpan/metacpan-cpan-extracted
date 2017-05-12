use Test::Simple 'no_plan';
use strict;
use lib './lib';
use HTML::Template::Default 'get_tmpl';
use Cwd;

$HTML::Template::Default::DEBUG = 1;

#$ENV{TMPL_PATH} = cwd().'/t/templates';
$ENV{HTML_TEMPLATE_ROOT} = cwd().'/t/templates';

my $default = '
   <html>
   <head>
   <title><TMPL_VAR TITLE></title>
   </head>
   <body>
   <h1><TMPL_VAR TITLE></h1>
   <p><TMPL_VAR CONTENT></p>   
   </body>
   </html>
';

my $tmpl;



ok( $tmpl= get_tmpl('super.tmpl', \q{   <html>
   <head>
   <title><TMPL_VAR TITLE></title>
   </head>
   <body>
   <h1><TMPL_VAR TITLE></h1>
   <p><TMPL_VAR CONTENT></p>   
   </body>
   </html>
}), 'got default because none on disk');



#\$default), 'got default because none on disk'); 

#$tmpl->param( TITLE => 'Great Title' );
#$tmpl->param( CONTENT => 'Super cool content is here.' );
#my $out =  $tmpl->output;
#print $out;
ok($tmpl->output,'output');





# try from disk



ok($tmpl = get_tmpl('duper.html', \$default),'get tmpl from disk instead'  );

my $out = $tmpl->output;

ok( $out=~/FROM DISK XYZ/,'correct, is from disk' );



my $dc = 'test';

ok( get_tmpl(undef,\$dc),'get_tmlpl with undef filename');



# ------------------------------------------
print STDERR "\n\n ----- \n\n";
# NEW ADDED 02/27/08

ok( get_tmpl( filename => 'duper.html', die_on_bad_params => 0 ),'get with filename');
ok( get_tmpl( scalarref => \$default, die_on_bad_params => 0   ), 'get with ref');
ok( get_tmpl( filename => 'duper.html', scalarref => \$default ),'get with both');




