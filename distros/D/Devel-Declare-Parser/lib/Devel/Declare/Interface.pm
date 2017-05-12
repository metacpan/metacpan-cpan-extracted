package Devel::Declare::Interface;
use strict;
use warnings;

use base 'Exporter';
use Carp;

our @EXPORT = qw/register_parser get_parser enhance/;

our %REGISTER = (
    codeblock => [ 'Devel::Declare::Parser::Codeblock', 0 ],
    method    => [ 'Devel::Declare::Parser::Method',    0 ],
    sublike   => [ 'Devel::Declare::Parser::Sublike',   0 ],
    codelast  => [ 'Devel::Declare::Parser',            0 ],
);

sub register_parser {
    my ( $name, $rclass ) = @_;
    croak( "No name for registration" ) unless $name;
    $rclass ||= caller;
    croak( "Parser $name already registered" )
        if $REGISTER{ $name } && $REGISTER{ $name }->[0] ne $rclass;
    $REGISTER{ $name } = [ $rclass, 0 ];
}

sub get_parser {
    my ( $name ) = @_;
    croak( "No name for parser" ) unless $name;
    unless ( $REGISTER{$name} ) {
        if ( $name =~ m/::/g ) {
            return $name if eval "require $name; 1";
            warn @_;
        }
        croak( "No parser found for $name" );
    }
    unless( $REGISTER{$name}->[1] ) {
        eval "require " . $REGISTER{$name}->[0] . "; 1" || die($@);
        $REGISTER{$name}->[1]++;
    }
    return $REGISTER{ $name }->[0];
}

sub enhance {
    my ( $for, $name, $parser, $type ) = @_;
    croak "You must specify a class, a function name, and a parser"
        unless $for && $name && $parser;
    $type ||= 'const';

    require Devel::Declare;
    Devel::Declare->setup_for(
        $for,
        {
            $name => {
                $type => sub {
                    my $pclass = get_parser( $parser );
                    my $parser = $pclass->new( $name, @_ );
                    $parser->process();
                }
            }
        }
    );
}

1;

__END__

=pod

=head1 NAME

Devel::Declare::Interface - Interface to Devel-Declare parsers.

=head1 DESCRIPTION

A higher level interface to Devel-Declare. This is the package you will
interact with the most when using L<Devel::Declare::Parser>.

=head1 SYNOPSIS

    package My::Keyword::Method;
    use strict;
    use warnings;

    use Devel::Declare::Parser;

    # Look at Exporter-Declare to have most of this done for you.
    sub import {
        my $class = shift;
        my $destination = caller;

        enhance( $destination, "make_method", "method" );
        no strict 'refs';
        *{ $destination . '::make_method' } = \&my_keyword;
    }

    sub make_method {
        my ( $name, $code ) = @_;
        my $dest = caller;
        no strict 'refs';
        *{ $destination . '::' . $name } = $code;
    }

    1;

=head1 API

The following functions are all exported by default.

=item register_parser( $name )

=item register_parser( $name, $class )

Register a parser under a short name. If $class is not provided caller will be
used.

=item get_parser( $name );

Get the parser class by short name.

=item enhance( $dest_class, $name, $parser );

=item enhance( $dest_class, $name, $parser, $type );

Make $name a keyword in $dest_class that uses $parser. $parser can be a short
name or class name. $type defaults to 'const'.

=back

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

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Devel-Declare-Interface is free software; Standard perl licence.

Devel-Declare-Parser is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the license for more details.
