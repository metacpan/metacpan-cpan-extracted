package Locale::Babelfish::Phrase::Compiler;

# ABSTRACT: Babelfish AST Compiler


use utf8;
use strict;
use warnings;

use List::Util 1.33 qw( none );

use Locale::Babelfish::Phrase::Literal ();
use Locale::Babelfish::Phrase::Variable ();
use Locale::Babelfish::Phrase::PluralForms ();

use parent qw( Class::Accessor::Fast );

our $VERSION = '2.10'; # VERSION

__PACKAGE__->mk_accessors( qw( ast ) );

my $sub_index = 0;


sub new {
    my ( $class, $ast ) = @_;
    my $parser = bless {}, $class;
    $parser->init( $ast )  if $ast;
    return $parser;
}


sub init {
    my ( $self, $ast ) = @_;
    $self->ast( $ast );
    return $self;
}


sub throw {
    my ( $self, $message ) = @_;
    die "Cannot compile: $message";
}



sub compile {
    my ( $self, $ast ) = @_;

    $self->init( $ast )  if $ast;

    $self->throw("No AST given")  unless $self->ast;
    $self->throw("Empty AST given")  if scalar( @{ $self->ast } ) == 0;

    if ( scalar( @{ $self->ast } ) == 1 && ref($self->ast->[0]) eq 'Locale::Babelfish::Phrase::Literal' ) {
        #  просто строка
        return $self->ast->[0]->text;
    }

    my $text = 'sub { my ( $params ) = @_; return join \'\',';
    for my $node ( @{ $self->ast } ) {
        if ( ref($node) eq 'Locale::Babelfish::Phrase::Literal' ) {
            $text .= $node->to_perl_escaped_str. ',';
        }
        elsif ( ref($node) eq 'Locale::Babelfish::Phrase::Variable' ) {
            $text .= "(\$params->{". $node->to_perl_escaped_str. "} // ''),";
        }
        elsif ( ref($node) eq 'Locale::Babelfish::Phrase::PluralForms' ) {
            my $sub = $node->to_perl_sub();
            my $index = ++$sub_index;
            my $name = "Locale::Babelfish::Phrase::Compiler::COMPILED_SUB_$index";
            no strict 'refs';
            *{$name} = $sub;
            use strict 'refs';
            $text .= "$name(\$params),"
        }
    }
    $text .= '\'\'; }';
    return eval $text;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Locale::Babelfish::Phrase::Compiler - Babelfish AST Compiler

=head1 VERSION

version 2.10

=head1 DESCRIPTION

Compiles AST to string or to coderef.

=head1 METHODS

=head2 new

    $class->new()
    $class->new( $ast )

Instantiates AST compiler.

=head2 init

Initializes compiler. Should not be called directly.

=head2 throw

    $self->throw( $message )

Throws given message in compiler context.

=head2 compile

    $self->compile()
    $self->compile( $ast )

Compiles AST.

Result is string when possible; coderef otherwise.

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

=item *

Kirill Sysoev <k.sysoev@me.com>

=item *

Alexandr Tkach <tkach@reg.ru>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by REG.RU LLC.

This is free software, licensed under:

  The MIT (X11) License

=cut
