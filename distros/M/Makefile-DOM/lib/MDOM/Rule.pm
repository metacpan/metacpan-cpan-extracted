package MDOM::Rule;

use strict;
use warnings;

use base 'MDOM::Node';

use MDOM::Rule::Simple;
use MDOM::Rule::StaticPattern;

1;

__END__

=encoding utf-8

=head1 NAME

MDOM::Rule - DOM Rule Abstract Node for Makefiles

=head1 DESCRIPTION

A rule node.

=head1 AUTHOR

Yichun "agentzh" Zhang (章亦春) E<lt>agentzh@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2006-2014 by Yichun "agentzh" Zhang (章亦春).

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<MDOM::Document>, L<MDOM::Document::Gmake>, L<PPI>, L<Makefile::Parser::GmakeDB>, L<makesimple>.

