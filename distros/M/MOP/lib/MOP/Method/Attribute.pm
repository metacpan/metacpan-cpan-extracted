package MOP::Method::Attribute;
# ABSTRACT: The Method Attribute object

use strict;
use warnings;

use Carp ();

our $VERSION   = '0.14';
our $AUTHORITY = 'cpan:STEVAN';

use parent 'UNIVERSAL::Object::Immutable';

our %HAS; BEGIN {
    %HAS = (
        original => sub { die '`original` is required' },
    )
}

# NOTE:
# we are not terribly sophisticated, but
# we accept `foo` calls (no-parens) and
# we accept `foo(1, 2, 3)` calls (parens
# with comma seperated args).

sub BUILDARGS {
    my $class = shift;
    Carp::confess('You must pass only a simple string')
        unless scalar(@_) == 1 && not ref $_[0];
    return +{ original => $_[0] };
}

sub REPR { \(my $x) }

sub CREATE {
    my ($class, $proto) = @_;
    my $self = $class->REPR;
    $$self = $proto->{original};
    $self;
}

sub original { ${ $_[0] } }

sub name {
    my ($self) = @_;
    my ($name) = ($$self =~ m/^([a-zA-Z_]*)/);
    return $name;
}

sub args {
    my ($self, $arg_splitter, $arg_processor) = @_;
    my ($args) = ($$self =~ m/^[a-zA-Z_]*\(\s*(.*)\)/ms);
    return unless $args;

    # NOTE:
    # These parses arguments badly,
    # but they are just the defaults.
    # it makes no attempt to enforce
    # anything, just splits on the
    # comma, both skinny and fat,
    # then strips away any quotes
    # and treats everything as a
    # simple string.
    $arg_splitter  ||= sub { split /\s*(?:\,|\=\>)\s*/ => $_[0] };
    $arg_processor ||= sub {
        # NOTE:
        # None of the args are eval-ed and they are
        # basically just a list of strings, with the
        # one exception of the string "undef", which
        # will be turned into undef
        my $arg = $_[0];
        $arg =~ s/\s*$//;
        $arg =~ s/^['"]//;
        $arg =~ s/['"]$//;
        $arg eq 'undef' ? undef : $arg;
    };

    return [ map $arg_processor->( $_ ), $arg_splitter->( $args ) ];
}

1;

__END__

=pod

=head1 NAME

MOP::Method::Attribute - The Method Attribute object

=head1 VERSION

version 0.14

=head1 DESCRIPTION

This is just a simple object to parse and store the
attribute invocation information.

=head1 METHODS

=head2 C<new( $attribute_string )>

=head2 C<original>

=head2 C<name>

=head2 C<args>

=head1 AUTHOR

Stevan Little <stevan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2018 by Stevan Little.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
