package EPUB::Parser::File::OPF::Context::Metadata;
use strict;
use warnings;
use Carp;
use parent 'EPUB::Parser::File::OPF::Context';


sub title      { shift->parser->single( 'dc:title'      )->string_value }
sub creator    { shift->parser->single( 'dc:creator'    )->string_value }
sub language   { shift->parser->single( 'dc:language'   )->string_value }
sub identifier { shift->parser->single( 'dc:identifier' )->string_value }


1;

__END__

=encoding utf-8

=head1 NAME

 EPUB::Parser::File::OPF::Context::Metadata - parses metadata node in opf file

=head1 METHODS

=head2 title

return value of dc:title.

=head2 creator

return value of dc:creator.

=head2 language

return value of dc:language.

=head2 identifier

return value of dc:identifier

=head1 LICENSE

Copyright (C) tokubass.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

tokubass E<lt>tokubass {at} cpan.orgE<gt>

=cut


