package Locale::Babelfish::Phrase::Literal;

# ABSTRACT: Babelfish AST Literal node.

use utf8;
use strict;
use warnings;

use Locale::Babelfish::Phrase::Pluralizer ();

use parent qw( Locale::Babelfish::Phrase::Node );

our $VERSION = '2.004'; # VERSION

__PACKAGE__->mk_accessors( qw( text ) );


sub to_perl_escaped_str {
    my ( $self ) = @_;

    return $self->SUPER::to_perl_escaped_str( $self->text );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Locale::Babelfish::Phrase::Literal - Babelfish AST Literal node.

=head1 VERSION

version 2.004

=head1 METHODS

=head2 to_perl_escaped_str

    $str = $node->to_perl_escaped_str

Returns node string to be used in Perl source code.

=head1 AUTHORS

=over 4

=item *

Akzhan Abdulin <akzhan@cpan.org>

=item *

Igor Mironov <grif@cpan.org>

=item *

Victor Efimov <efimov@reg.ru>

=item *

REG.RU LLC

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by REG.RU LLC.

This is free software, licensed under:

  The MIT (X11) License

=cut
