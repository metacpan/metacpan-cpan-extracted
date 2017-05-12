BEGIN
{
	$| = 1; print "1..1\n";
}

use strict;

use warnings;

use IO::Extended ':all';

our $loaded = 0;

	eval
	{
		$IO::Extended::tabsize = 3;

		$IO::Extended::space = ':';

		println 'Now printing a string';

		printfln 'Hello %s, printing with printfln...', 'User';

			ind 2;

			printfln 'And now indented...%s', 'User';

			printl 'Hello John';

			printf 'and hello James ...';

			print ' how are you doing ?!', "\n";
	};

	if($@)
	{
	        	print 'not ';
	}

print 'ok ', ++$loaded, "\n";
