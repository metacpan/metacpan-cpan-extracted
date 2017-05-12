# $Id: ScottAdams.pm,v 1.5 2006/11/02 18:04:37 mike Exp $

# ScottAdams.pm - a compiler for Scott Adams adventures

package Games::ScottAdams;
use strict;

use vars qw($VERSION);
$VERSION = '0.04';

=head1 NAME

Games::ScottAdams - Perl extension for representing Scott Adams games

=head1 SYNOPSIS

	use Games::ScottAdams;
	$game = new Games::ScottAdams::Game();
	$game->parse('/usr/local/lib/sac/foo.sac');
	$game->compile();

=head1 DESCRIPTION

This module allows adventure games in the textual SAC format to be
compiled into a form that can be understood by Scott Adams adventure
interpreters such as ScottFree and GnomeScott.

I don't propose to discuss the API because frankly, no-one will ever
call it.  They'll just use the trivial front-end program C<sac> which
is essentially identical to the code in the SYNOPSIS, but with a few
more C<use strict>s and suchlike.

You'd do much better to read the Tutorial and Reference Manual.


=head1 SEE ALSO

I<The Scott Adams Adventure Compiler Tutorial>
(B<Games::ScottAdams::Tutorial>)

I<The Scott Adams Adventure Compiler Reference Manual>
(B<Games::ScottAdams::Manual>)

C<sac>, the Scott Adams Compiler that uses this module.

=head1 AUTHOR

Mike Taylor E<lt>mike@miketaylor.org.ukE<gt>

First version Tuesday 17th April 2001.

=cut


use Games::ScottAdams::Game;

1;
__END__
