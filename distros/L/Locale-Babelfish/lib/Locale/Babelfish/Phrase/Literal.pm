package Locale::Babelfish::Phrase::Literal;

# ABSTRACT: Babelfish AST Literal node.

use utf8;
use strict;
use warnings;

use Locale::Babelfish::Phrase::Pluralizer ();

use parent qw( Locale::Babelfish::Phrase::Node );

our $VERSION = '1.000000'; # VERSION

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

version 1.000000

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

REG.RU LLC

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Akzhan Abdulin.

This is free software, licensed under:

  The MIT (X11) License

=cut
