package Fey::Role::HasAliasName;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.44';

use Fey::Types qw( Bool Str );

use MooseX::Role::Parameterized 1.00;

parameter 'generated_alias_prefix' => (
    isa      => Str,
    required => 1,
);

parameter 'sql_needs_parens' => (
    isa     => Bool,
    default => 0,
);

has 'alias_name' => (
    is     => 'rw',
    isa    => Str,
    writer => 'set_alias_name',
);

requires 'sql';

sub alias {
    $_[0]->set_alias_name( $_[1] );
    return $_[0];
}

sub sql_with_alias {
    $_[0]->_make_alias()
        unless $_[0]->alias_name();

    my $sql = $_[0]->_sql_for_alias( $_[1] );

    $sql .= ' AS ';
    $sql .= $_[1]->quote_identifier( $_[0]->alias_name() );

    return $sql;
}

sub sql_or_alias {
    return $_[1]->quote_identifier( $_[0]->alias_name() )
        if $_[0]->alias_name();

    return $_[0]->sql( $_[1] );
}

role {
    my $p = shift;

    my $parens = $p->sql_needs_parens();

    method _sql_for_alias => sub {
        my $sql = $_[0]->sql( $_[1] );
        $sql = "( $sql )" if $parens;
        return $sql;
    };

    my $prefix = $p->generated_alias_prefix();
    my $num    = 0;

    method '_make_alias' => sub {
        my $self = shift;
        $self->set_alias_name( $prefix . $num++ );
    };

};

1;

# ABSTRACT: A role for objects that bring an alias with them

__END__

=pod

=encoding UTF-8

=head1 NAME

Fey::Role::HasAliasName - A role for objects that bring an alias with them

=head1 VERSION

version 0.44

=head1 SYNOPSIS

  package My::Thing;

  use Moose 2.1200;
  with 'Fey::Role::HasAliasName'
      => { generated_alias_prefix => 'THING' };

=head1 DESCRIPTION

This role adds an C<alias_name> attribute to objects, as well as some
methods for making use of that alias.

=head1 PARAMETERS

=head2 generated_alias_prefix

The prefix that generated aliases will have, e.g. C<LITERAL>,
C<FUNCTION>, etc. Required.

=head2 sql_needs_parens

If true, C<sql_with_alias()> will wrap the output of C<sql()> when
generating its own output. Default is false.

=head1 METHODS

=head2 $obj->alias_name()

Returns the current alias name, if any.

=head2 $obj->set_alias_name()

  $obj->set_alias_name('my object');

Sets the current alias name.

=head2 $obj->alias()

  $obj->alias('my object')->do_something_else(...);

Sets the current alias name, then returns the object.

=head2 $obj->sql_with_alias()

=head2 $obj->sql_or_alias()

Returns the appropriate SQL snippet.  C<sql_with_alias> will generate
an alias if one has not been set (using C<generated_alias_prefix>,
above).

=head1 BUGS

See L<Fey> for details on how to report bugs.

Bugs may be submitted at L<https://github.com/ap/Fey/issues>.

=head1 SOURCE

The source code repository for Fey can be found at L<https://github.com/ap/Fey>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 - 2025 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
