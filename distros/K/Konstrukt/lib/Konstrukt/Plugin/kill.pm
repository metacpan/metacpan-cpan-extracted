=head1 NAME

Konstrukt::Plugin::kill - Remove content from a website

=head1 SYNOPSIS
	
B<Usage:>

	We will never <& kill &>agree that we always <& / &>do censoring!

B<Result:>

	We will never do censoring!

=head1 DESCRIPTION

Every content below this tag will be removed.

=cut

package Konstrukt::Plugin::kill;

use strict;
use warnings;

use base 'Konstrukt::Plugin'; #inheritance
use Konstrukt::Parser::Node;

=head1 METHODS

=head2 prepare

We can remove the content already at the prepare run.

=cut
sub prepare {
	#return an empty list, which will replace (delete) the tag and all content below
	return Konstrukt::Parser::Node->new();
}
#= /prepare

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin>, L<Konstrukt>

=cut

