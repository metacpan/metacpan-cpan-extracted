package Devel::SawAmpersand;

use strict;
use vars qw($VERSION @ISA @EXPORT_OK);

use Exporter;
*import = \&Exporter::import;
require DynaLoader;
@ISA = qw(DynaLoader);
@EXPORT_OK = qw(sawampersand);
$VERSION = '0.33';

bootstrap Devel::SawAmpersand $VERSION;

1;

__END__

=head1 NAME

Devel::SawAmpersand - Perl extension querying PL_sawampersand variable

=head1 SYNOPSIS

  use Devel::SawAmpersand qw(sawampersand);

  sawampersand();

=head1 DESCRIPTION

This module provides one single function:

=over

=item $bool = Devel::SawAmpersand::sawampersand()

Returns a true value if the compiled code has the C-level global
variable PL_sawampersand set.

=back

There's a global variable in the perl source, called PL_sawampersand.
It gets set to true in that moment in which the parser sees one of $`,
$', and $&. It never can be set to false again. Trying to set it to
false breaks the handling of the $`, $&, and $' completely.

If the global variable C<PL_sawampersand> is set to true, all
subsequent RE operations will be accompanied by massive in-memory
copying, because there is nobody in the perl source who could predict,
B<when> the (necessary) copy for the ampersand family will be needed.
So B<all> subsequent REs are considerable slower than necessary.

There are at least three impacts for developers:

=over 4

=item *

never use $& and friends in a library. Use /p if you have perl 5.10 or later.

=item *

Don't "use English" in a library, because it contains the three bad
fellows. Corollary: if you really want to use English, do it like so:

    use English qw( -no_match_vars ) ;

=item *

before you release a module or program, check
if PL_sawampersand is set by any of the modules you use or require.

=back

=head2 Workarounds

Fortunately, perl offers easy to use alternatives. If you have perl 5.10
or later, you can use the /p match operator flag to turn on per-match
variables that do the same thing:

       instead of this              you can use this

     $`   of   /pattern/          ${^PREMATCH}  of  /pattern/p
     $&   of   /pattern/          ${^MATCH}     of  /pattern/p
     $'   of   /pattern/          ${^POSTMATCH} of  /pattern/p

If you are using an older perl, you can use these workarounds:

       instead of this              you can use this

     $`   of   /pattern/          $1   of  /(.*?)pattern/s
     $&   of   /pattern/          $1   of  /(pattern)/
     $'   of   /pattern/          $+   of  /pattern(.*)/s

In general, apply C</^(.*)(pattern)(.*)$/s> and use $1 for $`, $2 for
$& and $+ for $' ($+ is not dependent on the number of parens in the
original pattern). Note that the C</s> switch can alter the meaning of
C<.> in your pattern.


=head1 AUTHOR

Andreas Koenig, special thanks to Johan Vromans, John Macdonald, and
brian d foy for parts of the manpage and to Doug MacEachern for the
FindAmpersand.

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=head1 SEE ALSO

Devel::FindAmpersand, B::FindAmpersand

=cut
