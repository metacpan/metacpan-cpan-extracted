package Exporter::Declare::Magic;
use strict;
use warnings;

our $VERSION = '0.107';

use Devel::Declare::Parser;
use aliased 'Exporter::Declare::Magic::Sub';
use aliased 'Exporter::Declare::Export::Generator';
use Carp qw/croak/;
our @CARP_NOT = qw/
    Exporter::Declare
    Exporter::Declare::Specs
    Exporter::Declare::Meta
    Exporter::Declare::Magic
    /;

BEGIN {
    die "Devel::Declare::Parser version >= 0.017 is required for -magic\n"
        unless $Devel::Declare::Parser::VERSION gt '0.016';
}

use Devel::Declare::Parser::Sublike;

use base 'Exporter::Declare';
use Exporter::Declare
    'default_exports',
    'reexport',
    export             => {-as => 'ed_export'},
    gen_export         => {-as => 'ed_gen_export'},
    default_export     => {-as => 'ed_default_export'},
    gen_default_export => {-as => 'ed_gen_default_export'};

default_exports qw/
    parsed_exports
    parsed_default_exports
    /;

parsed_default_exports( sublike => qw/parser/ );

parsed_default_exports(
    export => qw/
        export
        gen_export
        default_export
        gen_default_export
        /
);

Exporter::Declare::Meta->add_hash_metric('parsers');

reexport('Exporter::Declare');

sub export {
    my $class = Exporter::Declare::_find_export_class( \@_ );
    _export( $class, undef, @_ );
}

sub gen_export {
    my $class = Exporter::Declare::_find_export_class( \@_ );
    _export( $class, Generator(), @_ );
}

sub default_export {
    my $class = Exporter::Declare::_find_export_class( \@_ );
    my $meta  = $class->export_meta;
    $meta->export_tags_push( 'default', _export( $class, undef, @_ ) );
}

sub gen_default_export {
    my $class = Exporter::Declare::_find_export_class( \@_ );
    my $meta  = $class->export_meta;
    $meta->export_tags_push( 'default', _export( $class, Generator(), @_ ) );
}

sub _export {
    my %params = Exporter::Declare::_parse_export_params(@_);
    my ($parser) = @{$params{args}};
    if ($parser) {
        my $ec = $params{export_class};
        if ( $ec && $ec eq Generator ) {
            $params{extra_exporter_props} = {parser => $parser, type => Sub};
        }
        else {
            $params{export_class} = Sub;
            $params{extra_exporter_props} = {parser => $parser};
        }
    }
    Exporter::Declare::_add_export(%params);
}

sub parser {
    my $class = Exporter::Declare::_find_export_class( \@_ );
    my $name  = shift;
    my $code  = pop;
    croak "You must provide a name to parser()"
        if !$name || ref $name;
    croak "Too many parameters passed to parser()"
        if @_ && defined $_[0];
    $code ||= $class->can($name);
    croak "Could not find code for parser '$name'"
        unless $code;

    $class->export_meta->parsers_add( $name, $code );
}

sub parsed_exports {
    my $class = Exporter::Declare::_find_export_class( \@_ );
    my ( $parser, @items ) = @_;
    croak "no parser specified" unless $parser;
    _export( $class, Sub(), $_, $parser ) for @items;
}

sub parsed_default_exports {
    my $class = Exporter::Declare::_find_export_class( \@_ );
    my ( $parser, @names ) = @_;
    croak "no parser specified" unless $parser;

    for my $name (@names) {
        _export( $class, Sub(), $name, $parser );
        $class->export_meta->export_tags_push( 'default', $name );
    }
}

1;

__END__

=head1 NAME

Exporter::Declare::Magic - Enhance Exporter::Declare with some fancy magic.

=head1 DESCRIPTION

=head1 SYNOPSIS

    package Some::Exporter;
    use Exporter::Declare::Magic;

    ... #Same as the basic Exporter::Declare synopsis

    #Quoting is not necessary unless you have space or special characters
    export another_sub;
    export parsed_sub parser;

    # no 'sub' keyword, not a typo
    export anonymous_export {
        ...
    }
    #No semicolon, not a typo

    export parsed_anon parser {
        ...
    }

    # Same as export
    default_export name { ... }

    # No quoting required
    export $VAR;
    export %VAR;

    my $iterator = 'a';
    gen_export unique_class_id {
        my $current = $iterator++;
        return sub { $current };
    }

    gen_default_export '$my_letter' {
        my $letter = $iterator++;
        return \$letter;
    }

    parser myparser {
        ... See Devel::Declare
    }

    parsed_exports parser => qw/ parsed_sub_a parsed_sub_b /;
    parsed_default_exports parser_b => qw/ parsed_sub_c /;

=head1 API

These all work fine in function or method form, however the syntax sugar will
only work in function form.

=over 4

=item parsed_exports( $parser, @exports )

Add exports that should use a 'Devel::Declare' based parser. The parser should
be the name of a registered L<Devel::Declare::Interface> parser, or the name of
a parser sub created using the parser() function.

=item parsed_default_exports( $parser, @exports )

Same as parsed_exports(), except exports are added to the -default tag.

=item parser name { ... }

=item parser name => \&code

Define a parser. You need to be familiar with Devel::Declare to make use of
this.

=item export( $name )

=item export( $name, $ref )

=item export( $name, $parser )

=item export( $name, $parser, $ref )

=item export name { ... }

=item export name parser { ... }

export is a keyword that lets you export any 1 item at a time. The item can be
exported by name, name+ref, or name+parser+ref. You can also use it without
parentheses or quotes followed by a codeblock.

=item default_export( $name )

=item default_export( $name, $ref )

=item default_export( $name, $parser )

=item default_export( $name, $parser, $ref )

=item default_export name { ... }

=item default_export name parser { ... }

=item gen_export( $name )

=item gen_export( $name, $ref )

=item gen_export( $name, $parser )

=item gen_export( $name, $parser, $ref )

=item gen_export name { ... }

=item gen_export name parser { ... }

=item gen_default_export( $name )

=item gen_default_export( $name, $ref )

=item gen_default_export( $name, $parser )

=item gen_default_export( $name, $parser, $ref )

=item gen_default_export name { ... }

=item gen_default_export name parser { ... }

These all act just like export(), except that they add subrefs as generators,
and/or add exports to the -default tag.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Exporter-Declare is free software; Standard perl licence.

Exporter-Declare is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the license for more details.
