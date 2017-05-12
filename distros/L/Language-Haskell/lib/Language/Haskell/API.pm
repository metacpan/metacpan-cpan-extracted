package Language::Haskell::API;
push @_p__HugsServerAPI::ISA, __PACKAGE__;

use strict;

=head1 NAME

Language::Haskell::API - Haskell interpreter API

=head1 DESCRIPTION

This module represents a haskell interpreter.

See L<http://www.cs.sfu.ca/CC/SW/Haskell/hugs/server.html> for a description
of the Hugs API.  That document is also available as
F<hugs98-Nov2003/docs/server.html> in this module's source distribution.

=head1 CONVENIENT METHODS

=head2 $hugs->eval($string)

=head1 BUILT-IN METHODS

=head2 $hugs->clearError

=head2 $hugs->setHugsArgs($argc, $argv)

=head2 $hugs->getNumScripts

=head2 $hugs->reset

=head2 $hugs->setOutputEnable($bool)

=head2 $hugs->changeDir($path)

=head2 $hugs->loadProject($pathname)

=head2 $hugs->loadFile($pathname)

=head2 $hugs->loadFromBuffer($string)

=head2 $hugs->setOptions($string)

=head2 $hugs->getOptions

=head2 $hugs->compileExpr($module, $string)

=head2 $hugs->garbageCollect

=head2 $hugs->lookupName($module, $name)

=head2 $hugs->mkInt($int)

=head2 $hugs->mkAddr($pointer)

=head2 $hugs->mkString($string)

=head2 $hugs->apply

=head2 $hugs->evalInt

=head2 $hugs->evalAddr

=head2 $hugs->evalString

=head2 $hugs->doIO

=head2 $hugs->doIO_Int(\$int)

=head2 $hugs->doIO_Addr(\$pointer)

=head2 $hugs->popHVal

=head2 $hugs->pushHVal($hval)

=head2 $hugs->freeHVal($hval)

=cut

# XXX - This is totally a makeshift operation.  Should use the
# overloaded "show" primitive for this.
sub eval {
    my $self = shift;
    my $hval = $self->compileExpr( Prelude => "(show) ($_[0])" );
    $self->pushHVal($hval);
    return $self->evalString;
}

1;

__END__

=head1 SEE ALSO

L<Language::Haskell>

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

=head1 COPYRIGHT

Copyright 2004 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
