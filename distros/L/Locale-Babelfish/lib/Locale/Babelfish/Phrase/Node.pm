package Locale::Babelfish::Phrase::Node;

# ABSTRACT: Babelfish AST abstract node.

use utf8;
use strict;
use warnings;

use parent qw( Class::Accessor::Fast );

our $VERSION = '1.000000'; # VERSION


sub new {
    my ( $class, %args ) = @_;
    return bless { %args }, $class;
}


sub to_perl_escaped_str {
    my ( $self, $str ) = @_;

    $str =~ s/\\/\\\\/g;
    $str =~ s/'/\\'/g;
    return "'$str'";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Locale::Babelfish::Phrase::Node - Babelfish AST abstract node.

=head1 VERSION

version 1.000000

=head1 METHODS

=head2 new

    $class->new( %args )

Instantiates AST node.

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
