use strict;
use warnings;

use Test::More tests => 7;

BEGIN {
	use_ok( 'HTML::LinkAdd' );
}

BASIC: {
	my $o = HTML::LinkAdd->new( 
		\'This is some text to hyperlink ...', 
		{
			hyperlink => 'http://www.google.co.uk',
		}
	);
	
	isa_ok( $o, 'HTML::LinkAdd');
	is( $o->hyperlinked, $o->{output}, 'getter' );
	is( $o->hyperlinked,
		'This is some text to <a href="http://www.google.co.uk">hyperlink</a> ...',
		'hyperlinked word, old'
	);
}


ARRAYS: {
	my $o = HTML::LinkAdd->new( 
		\'This is some text to hyperlink ...', 
		{
			hyperlink => ['http://www.google.co.uk','The Title'],
		}
	);
	
	is( $o->hyperlinked,
		'This is some text to <a href="http://www.google.co.uk" title="The Title">hyperlink</a> ...',
		'hyperlinked word new'
	);
}

SKIPTO:{
	my $o = HTML::LinkAdd->new( 
		\'<head>no hyperlink</head>This is some text to hyperlink ... <pre>no hyperlink</pre> <xmp>no hyperlink</xmp> and <input type="no hyperlink"> hyperlink and <textarea>no hyperlink</textarea>',
		{
			hyperlink => ['http://www.google.co.uk','The Title'],
		}
	);
	
	is( $o->hyperlinked,
		'<head>no hyperlink</head>This is some text to <a href="http://www.google.co.uk" title="The Title">hyperlink</a> ... <pre>no hyperlink</pre> <xmp>no hyperlink</xmp> and <input type="no hyperlink"> <a href="http://www.google.co.uk" title="The Title">hyperlink</a> and <textarea>no hyperlink</textarea>',
		'skip head/pre'
	);
}

SKIPTO2:{
	my $txt = '<head><pre><xmp>no hyperlink</xmp></pre></head>';
	my $o = HTML::LinkAdd->new( 
		\$txt,
		{
			hyperlink => ['http://www.google.co.uk','The Title'],
		}
	);
	
	is( $o->hyperlinked, $txt, 'skip head/pre' );
}


