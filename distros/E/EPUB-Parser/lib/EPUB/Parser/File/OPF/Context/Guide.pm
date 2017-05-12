package EPUB::Parser::File::OPF::Context::Guide;
use strict;
use warnings;
use Carp;
use parent 'EPUB::Parser::File::OPF::Context';

sub list {
    my $self = shift;
    my @guide = $self->parser->in_guide->find('pkg:reference');
    return @guide;
}


1;

__END__

=encoding utf-8

=head1 NAME

 EPUB::Parser::File::OPF::Context::Guide - parses guide node in opf file

=head1 METHODS

=head2 list

Return reference elements in guide.
Element is XML::LibXML::Element.

=head1 LICENSE

Copyright (C) tokubass.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

tokubass E<lt>tokubass {at} cpan.orgE<gt>

=cut


