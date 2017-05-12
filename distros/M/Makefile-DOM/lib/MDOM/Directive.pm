package MDOM::Directive;

use strict;
use base 'MDOM::Node';

sub name {
    my ($self) = @_;
    # XXX need a better way to do this:
    return $self->schild(0);
}

sub value {
    my ($self) = @_;
    # XXX This is a hack
    return $self->schild(1);
}

1;

__END__

=encoding utf-8

=head1 NAME

MDOM::Directive - DOM Directive Node for Makefiles

=head1 DESCRIPTION

A directive node.

=head2 Accessors

=over 4

=item name

directive name

=item value

directive value

=back

=head1 AUTHOR

Yichun "agentzh" Zhang (章亦春) E<lt>agentzh@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2006-2014 by Yichun "agentzh" Zhang (章亦春).

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<MDOM::Document>, L<MDOM::Document::Gmake>, L<PPI>, L<Makefile::Parser::GmakeDB>, L<makesimple>.

