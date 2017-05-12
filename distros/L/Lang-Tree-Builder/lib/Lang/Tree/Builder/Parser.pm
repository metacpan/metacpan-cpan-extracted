package Lang::Tree::Builder::Parser;

use strict;
use warnings;

use FileHandle;
use Lang::Tree::Builder::Data;
use Lang::Tree::Builder::Tokenizer;

our $VERSION = '0.01';

our $debug = 0;

use constant START    => 0;
use constant MAIN     => 1;
use constant ARGS     => 2;
use constant ARG      => 3;
use constant NAME     => 4;
use constant SUPER    => 6;
use constant ABSTRACT => 7;

=head1 NAME

Lang::Tree::Builder::Parser - Parse Tree Definitions

=head1 SYNOPSIS

  use Lang::Tree::Builder::Parser;
  my $parser = new Lang::Tree::Builder::Parser();
  my $data = $parser->parseFile($datafile);

=head1 DESCRIPTION

A parser for class definitions. The data file input to the C<parse>
method has the following simple format:

  # a comment
  [abstract] [<parent>] <class>(<class> [<name>], ... )
  ...

for example

  # this class has no base class and is initialized with a scalar
  IntNode(scalar)
  # the list class is abstract
  abstract List()
  # this class is a type of List and takes initializers Foo::Node and Foo::List
  List Foo::List(Foo::Node first,
                 Foo::List rest)
  # this class is an abstract type of List and takes no initializers
  List EmptyList()

apart from arbitrary class names as initializers, the keyword C<scalar> is
recognized.

=head2 new

  my $parser = new Lang::Tree::Builder::Parser;

Creates and returns a new instance of a parser.

=cut

sub new {
    my ( $class, %params ) = @_;
    $params{prefix} ||= '';
    bless {
        filename => '',
        lineno   => 0,
        error    => '',
        prefix   => $params{prefix},
        state    => START,
        class    => '',
        parent   => '',
        args     => [],
        abstract => 0,
    }, $class;
}

sub init {
    my ($self) = @_;
    $self->{state}       = START;
    $self->{class}       = '';
    $self->{parent}      = '';
    $self->{args}        = [];
    $self->{is_abstract} = 0;
}

=head2 parseFile

  my $data = $parser->parseFile($datafile);

Parses C<$datafile> and returns an instance of L<Lang::Tree::Builder::Data>

=cut

sub parseFile {
    my ( $self, $datafile ) = @_;

    $self->{error}     = '';
    $self->{data}      = new Lang::Tree::Builder::Data();
    $self->{tokenizer} = new Lang::Tree::Builder::Tokenizer($datafile);

    unless ( $self->{tokenizer} ) {
        $self->{error} = "$datafile: $@";
        return undef;
    }

    $self->init;

    while ( defined( my $token = $self->{tokenizer}->next() ) ) {
        warn "### state $self->{state}, token $token\n" if $debug;
        if ( $token eq '(' ) {
            $self->handleLBrace;
        } elsif ( $token eq ')' ) {
            $self->handleRBrace;
        } elsif ( $token eq ',' ) {
            $self->handleComma;
        } elsif ( $token eq 'abstract' ) {
            $self->handleAbstract;
        } elsif ( $token eq 'scalar' ) {
            $self->handleScalar;
        } else {
            $self->handleName($token);
        }
    }

    if ( $self->{tokenizer}->{error} ) {
        $self->{error} = $self->{tokenizer}->{error};
        return undef;
    }

    if ( $self->{state} != START ) {
        $self->{error} = "unexpected EOF";
        return undef;
    }

    $self->{data}->finalize();
    return $self->{data};
}

sub handleLBrace {
    my ($self) = @_;

    if ( $self->{state} == MAIN || $self->{state} == SUPER ) {
        $self->{state} = ARGS;
    } else {
        die "syntax error ", $self->{tokenizer}->info(), "\n";
    }
}

sub handleRBrace {
    my ($self) = @_;

    if ( $self->{state} == ARG ) {
        push @{ $self->{args}[-1] }, '';
    }

    if (   $self->{state} == ARGS
        || $self->{state} == ARG
        || $self->{state} == NAME )
    {
        $self->processOneClass;
        $self->init;
    } else {
        die "syntax error ", $self->{tokenizer}->info(), "\n";
    }
}

sub handleComma {
    my ($self) = @_;

    if ( $self->{state} == ARG ) {
        push @{ $self->{args}[-1] }, '';
    }

    if ( $self->{state} == ARG || $self->{state} == NAME ) {
        $self->{state} = ARGS;
    } else {
        die "syntax error ", $self->{tokenizer}->info(), "\n";
    }
}

sub handleAbstract {
    my ($self) = @_;

    if ( $self->{state} == START ) {
        $self->{is_abstract} = 1;
        $self->{state}       = ABSTRACT;
    } else {
        die "syntax error ", $self->{tokenizer}->info(), "\n";
    }
}

sub handleScalar {
    my ($self) = @_;

    $self->handleName('scalar');
}

sub handleName {
    my ( $self, $token ) = @_;

    if ( $self->{state} == START || $self->{state} == ABSTRACT ) {
        $self->{class} = $token;
        $self->{state} = SUPER;
    } elsif ( $self->{state} == ARGS ) {
        if ( $self->{is_abstract} ) {
            die "pointless args to abstract constructor ",
              $self->{tokenizer}->info(), "\n";
        }

        push @{ $self->{args} }, [$token];
        $self->{state} = ARG;
    } elsif ( $self->{state} == ARG ) {
        if ( $token =~ /:/ ) {
            die "named argument cannot contain colons ",
              $self->{tokenizer}->info(), "\n";
        }

        push @{ $self->{args}[-1] }, $token;
        $self->{state} = NAME;
    } elsif ( $self->{state} == SUPER ) {
        $self->{parent} = $self->{class};
        $self->{class}  = $token;
        $self->{state}  = MAIN;
    } else {
        die "syntax error ", $self->{tokenizer}->info(), "\n";
    }
}

sub processOneClass {
    my ($self) = @_;

    $self->{parent} = $self->{prefix} . $self->{parent}
      if $self->{parent};

    $self->{class} = $self->{prefix} . $self->{class};
    my @args = map {
        [
            (
                $_->[0] eq 'scalar'
                ? 'scalar'
                : $self->{prefix} . $_->[0]
            ),
            $_->[1]
        ];
    } @{ $self->{args} };

    $self->{data}->add(
        Lang::Tree::Builder::Class->new(
            parent   => $self->{parent},
            class    => $self->{class},
            args     => [@args],
            abstract => $self->{is_abstract},
        )
    );
}

=head1 SEE ALSO

L<Lang::Tree::Builder>

=head1 AUTHOR

Bill Hails, E<lt>me@billhails.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Bill Hails

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
