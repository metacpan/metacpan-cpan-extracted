package Locale::Babelfish::Phrase::Variable;

# ABSTRACT: Babelfish AST Variable substitution node.

use utf8;
use strict;
use warnings;

our $VERSION = '1.000000'; # VERSION

use parent qw( Locale::Babelfish::Phrase::Node );

__PACKAGE__->mk_accessors( qw( name ) );

sub to_perl_escaped_str {
    my ( $self ) = @_;

    return $self->SUPER::to_perl_escaped_str( $self->name );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Locale::Babelfish::Phrase::Variable - Babelfish AST Variable substitution node.

=head1 VERSION

version 1.000000

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
