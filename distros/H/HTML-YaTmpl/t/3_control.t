# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use warnings;
use Test::More tests => 4;
use HTML::YaTmpl;
use Compress::Zlib ();

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $t=HTML::YaTmpl->new( file=>'main.tmpl', path=>['templates'] );

ok( $t->evaluate_to_file( 'out.html',
			  title=>'Opi\'s Super Test Document',
			  links=>[[link1=>'link1.html'],
				  [link2=>'link2.html'],
				  [link3=>'link3.html'],
				  [link4=>'link4.html'],
				  [link5=>'link5.html'],
				  [link6=>'link6.html'],
				 ],
			  thema=>'some fruits',
			  fruits=>[[apple=>'round'],
				   [pear=>'pear-shaped'],
				   [egg=>'ovaliform'],
				   [plum=>'ovaliform'],
				  ],
			), 'writing out.html' );

my $html=<<'EOF';
<html>
<head>
<title>Opi's Super Test Document</title>
</head>
<body>
<table width="100%" border="1">
<tr>
<td width="200"><h3>Navigation</h3>
<a href="link1.html">link1</a><br>
<a href="link2.html">link2</a><br>
<a href="link3.html">link3</a><br>
<a href="link4.html">link4</a><br>
<a href="link5.html">link5</a><br>
<a href="link6.html">link6</a><br>
</td>
<td><table>
<tr><th colspan="2">Some Fruits</th></tr>
<tr><tr><td>Apple</td><td>round</td></tr>
<tr><td>Pear</td><td>pear-shaped</td></tr>
<tr><td>Egg</td><td>ovaliform</td></tr>
<tr><td>Plum</td><td>ovaliform</td></tr>
</tr></td>
</tr>
</table>
</body>
</html>
EOF
#'}#

ok( do{ local $/; local *F;
	((open F, '<out.html' and $html eq <F>),
	 close F,
	 unlink 'out.html')[0]},
    'checking out.html' );

$t->compress='.gz';

ok( $t->evaluate_to_file( 'out.html',
			  title=>'Opi\'s Super Test Document',
			  links=>[[link1=>'link1.html'],
				  [link2=>'link2.html'],
				  [link3=>'link3.html'],
				  [link4=>'link4.html'],
				  [link5=>'link5.html'],
				  [link6=>'link6.html'],
				 ],
			  thema=>'some fruits',
			  fruits=>[[apple=>'round'],
				   [pear=>'pear-shaped'],
				   [egg=>'ovaliform'],
				   [plum=>'ovaliform'],
				  ],
			), 'writing out.html.gz' );

ok( do{ local $/; local *F;
	((open F, '<out.html.gz' and Compress::Zlib::memGzip $html eq <F>),
	 close F,
	 unlink 'out.html.gz')[0]},
    'checking out.html.gz' );

# Local Variables:
# mode: cperl
# End:
