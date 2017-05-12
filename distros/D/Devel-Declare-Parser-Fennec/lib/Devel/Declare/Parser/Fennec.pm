package Devel::Declare::Parser::Fennec;
use strict;
use warnings;

use Devel::Declare::Interface;
use base 'Exporter::Declare::Magic::Parser';
BEGIN { Devel::Declare::Interface::register_parser('fennec') }

our $VERSION = '0.005';
our %NAMELESS;
sub nameless    { $NAMELESS{$_[-1]}++ }
sub is_nameless { $NAMELESS{shift->name} }

sub args { (qw/name/) }

sub inject {
    my $self = shift;
    return if $self->is_nameless;
    return if $self->has_fat_comma;
    return ('my $self = shift');
}

sub rewrite {
    my $self = shift;

    return 1 if $self->is_nameless;

    $self->strip_prototype;
    $self->_check_parts;

    my $is_arrow = $self->parts->[1]
        && ( $self->parts->[1] eq '=>' || $self->parts->[1] eq ',' );
    if ( $is_arrow && $self->parts->[2] ) {
        my $is_ref = ref( $self->parts->[2] );
        my $is_sub = $is_ref ? $self->parts->[2]->[0] eq 'sub' : 0;

        if ( !$is_ref ) {
            $self->new_parts( [$self->parts->[0], $self->parts->[2]] );
            return 1;
        }
        elsif ($is_sub) {
            $self->new_parts( [$self->parts->[0]] );
            return 1;
        }
        else {
            $self->bail('oops');
        }
    }

    my ( $names, $specs ) = $self->sort_parts();
    $self->new_parts(
        [
            @$names,
            @$specs
            ? (
                ( map { $_->[0] } @$specs ),
                ['method']
                )
            : ()
        ]
    );

    1;
}

1;

__END__

=head1 NAME

Devel::Declare::Parser::Fennec - The parser for Fennec syntax.

=head1 FENNEC PROJECT

This module is part of the Fennec project. See L<Fennec> for more details.
Fennec is a project to develop an extendable and powerful testing framework.
Together the tools that make up the Fennec framework provide a potent testing
environment.

The tools provided by Fennec are also useful on their own. Sometimes a tool
created for Fennec is useful outside the greator framework. Such tools are
turned into their own projects. This is one such project.

=over 2

=item L<Fennec> - The core framework

The primary Fennec project that ties them all together.

=back

=head1 SYNTAX PROVIDED

This parser provides fennec like syntax. This means a keyword, optional name,
coderef and options.

Examples:

    # These automatically give you $self
    keyword name { ... }
    keyword 'string name' { ... }
    keyword name ( KEY => 'VALUE' ) { ... }

    # These do not automatically give you $self
    # These are not effected by the parser.
    keyword name => sub { ... };
    keyword name => (
        method => sub { ... },
        ...
    );

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Devel-Declare-Parser-Fennec is free software; Standard perl licence.

Devel-Declare-Parser-Fennec is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the license for more details.
