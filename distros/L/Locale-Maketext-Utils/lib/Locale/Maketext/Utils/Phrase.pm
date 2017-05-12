package Locale::Maketext::Utils::Phrase;

use strict;
use warnings;
use Carp ();

use Module::Want ();

$Locale::Maketext::Utils::Phrase::VERSION = '0.1';

my $closing_bn = qr/(?<!\~)\]/;
my $opening_bn = qr/(?<!\~)\[/;
my $bn_delimit = qr/(?<!\~)\,/;
my $bn_var_arg = qr/(?<!\~)\_(?:0|\-?[1-9]+[0-9]*|\*)/;

sub get_bn_var_regexp {
    return qr/(?<!\~)\_(?:0|\-?[1-9]+[0-9]*|\*)/;
}

sub get_non_translatable_type_regexp {
    return qr/(?:var|meth|basic_var)/;
}

sub string_has_opening_or_closing_bracket {
    return $_[0] =~ m/$opening_bn/ || $_[0] =~ m/$closing_bn/;
}

sub phrase2struct {
    my ($phrase) = @_;

    # Makes parsing (via code or mentally) unnecessarily difficult.
    #   ? TODO ? s/~~/_TILDES_/g (yes w/ an S so _TILDE_ still works) then restore them inside the while loop and don’t croak() here (maybe carp()) ?
    Carp::croak("Consecutive tildes are ambiguous (use the special placeholder _TILDE_ instead): “$phrase”") if $phrase =~ m/~~/;

    return [$phrase] unless $phrase =~ m/(?:$opening_bn|$closing_bn)/;

    my @struct;
    while (
        $phrase =~ m{
            ( # Capture chunk of …
                # bracket notation …
                (?:
                    $opening_bn
                        ( # Capture bracket pair contents
                            (?:
                            \~\]
                            |
                            [^\]]
                        )*
                    )
                $closing_bn
            )
            |
            # … or non-bracket notation
            (?:
                \~[\[\]]
                |
                [^\[\]]
            )+
        ) # /Capture chunk of …
    }gx
      ) {
        my ( $match, $bn_inside ) = ( $1, $2 );

        if ( defined $bn_inside ) {
            if ( $bn_inside =~ m/(?:$closing_bn|$opening_bn)/ ) {
                Carp::croak("Unbalanced bracket: “[$bn_inside]”");
            }

            my $list = [ _split_bn_cont($bn_inside) ];
            my $type = _get_bn_type_from_list($list);

            push @struct,
              {
                'orig' => $match,
                'cont' => $bn_inside,
                'list' => $list,
                'type' => $type,
              };
        }
        else {

            # probably won't trip but for good measure
            if ( $match =~ m/(?:$opening_bn|$closing_bn)/ ) {
                Carp::croak("Unbalanced bracket: “$match”");
            }

            push @struct, $match;
        }
    }

    return if !@struct;

    # if the structure rebuilds differently it means unbalanced [ or ] existed in $phrase that were masked out in @struct
    if ( struct2phrase( \@struct ) ne $phrase ) {
        Carp::croak("Unbalanced bracket: “$phrase”");
    }

    return \@struct;
}

sub struct2phrase {
    my ($struct) = @_;

    return join(
        '',
        map { ref($_) ? $_->{'orig'} : $_ } @{$struct}
    );
}

sub phrase_has_bracket_notation {
    return 1 if $_[0] =~ m/$opening_bn/;
    return;
}

sub struct_has_bracket_notation {
    my $len = @{ $_[0] };
    return 1 if ( $len == 1 && ref( $_[0]->[0] ) ) || $len > 1;
    return;
}

sub phrase_is_entirely_bracket_notation {
    return 1 if $_[0] =~ m{\A$opening_bn(?:\~[\[\]]|[^\[\]])+$closing_bn\z}x;
    return;
}

sub struct_is_entirely_bracket_notation {
    return 1 if @{ $_[0] } == 1 && ref( $_[0]->[0] );
    return;
}

sub _split_bn_cont {
    my ( $cont, $limit ) = @_;
    $limit = abs( int( $limit || 0 ) );
    return $limit ? split( $bn_delimit, $cont, $limit ) : split( $bn_delimit, $cont );
}

my %meth = (
    'numf'         => 'Should be passing in an unformatted number.',
    '#'            => 'Should be passing in an unformatted number (numf alias).',
    'format_bytes' => 'Should be passing in the unformatted number of bytes.',
    'output'       => sub {
        return 'Should be passing in character identifier.'                                                  if $_[0]->[1] eq 'chr';
        return 'Displayed without modification.'                                                             if $_[0]->[1] eq 'asis' || $_[0]->[1] eq 'asis_for_tests';
        return 'No args, character.'                                                                         if $_[0]->[1] =~ m/^(?:nbsp|amp|quot|apos|shy|lt|gt)/;
        return 'Domain should be passed in. Hardcoded domain that needs translated should just be a string.' if $_[0]->[1] eq 'encode_puny' || $_[0]->[1] eq 'decode_puny';
        return;
    },
    'datetime' => sub {
        return 'format has no translatable components' if !$_[0]->[2]    # there is no format (FWIW, 0 is not a valid format)
          || $_[0]->[2] =~ m/\A(?:date|time|datetime)_format_(:full|long|medium|short|default)\z/    # it is a format method name
          || $_[0]->[2] =~ m/\A[GgyYQqMmwWdDEeaAhHKkSszZvVuLFcj]+(?:{[0-9],?([0-9])?})?\z/;          # is only CLDR Pattern codes …

        # … i.e. which includes values for format_for() AKA $loc->available_formats(),
        #    http://search.cpan.org/perldoc?DateTime#CLDR_Patterns says:
        #       If you want to include any lower or upper case ASCII characters as-is, you can surround them with single quotes (').
        #        If you want to include a single quote, you must escape it as two single quotes ('').
        #        Spaces and any non-letter text will always be passed through as-is.

        return;
    },
    'current_year'    => 'Takes no args.',
    'asis'            => 'Displayed without modification.',
    'comment'         => 'Not displayed.',
    'join'            => 'Arbitrary args.',
    'sprintf'         => 'Arbitrary args.',
    'convert'         => 'Converts arbitrary units and identifiers.',    # ? technically USD -> GBP, not critical ATM ?
    'list_and'        => 'Arbitrary args.',
    'list_or'         => 'Arbitrary args.',
    'list_and_quoted' => 'Arbitrary args.',
    'list_or_quoted'  => 'Arbitrary args.',
    'list'            => 'Deprecated. Arbitrary args.',
);

my %basic = (
    'output'   => 'has possible translatable parts',
    'datetime' => 'has possible translatable components in format',
);

my %complex = (
    'boolean'    => 'should have translatable parts',
    'is_defined' => 'should have translatable parts',
    'is_future'  => 'should have translatable parts',
    'quant'      => 'should have translatable parts',
    '*'          => 'should have translatable parts (quant alias)',
    'numerate'   => 'should have translatable parts',
);

my $ns_regexp = Module::Want::get_ns_regexp();

sub _get_attr_hash_from_list {
    my ( $list, $start_idx ) = @_;

    my $last_list_idx = @{$list} - 1;

    my %attr;
    my $skip_to = 0;
    for my $i ( $start_idx .. $last_list_idx ) {
        next if $i < $skip_to;
        next if $list->[$i] =~ m/\A$bn_var_arg\z/;

        $attr{ $list->[$i] } = $list->[ $i + 1 ];
        $skip_to = $i + 2;
    }

    return %attr;
}

sub _get_bn_type_from_list {
    my ($list) = @_;
    my $len = @{$list};

    return 'var' if $len == 1 && $list->[0] =~ m/\A$bn_var_arg\z/;

    # recommend to carp/croak
    return '_invalid' if !defined $list->[0] || $list->[0] !~ m/\A(?:$ns_regexp|\*|\#)\z/;
    return '_invalid' if $list->[0] eq 'output' && ( !defined $list->[1] || $list->[1] !~ m/\A$ns_regexp\z/ );

    # should not be anything translatable
    return 'meth' if exists $meth{ $list->[0] } && ( ref( $meth{ $list->[0] } ) ne 'CODE' || $meth{ $list->[0] }->($list) );

    if ( exists $basic{ $list->[0] } && ( ref( $basic{ $list->[0] } ) ne 'CODE' || $basic{ $list->[0] }->($list) ) ) {

        # check for 'basic_var' (might be basic except there are not any translatable parts)

        if ( $list->[0] eq 'output' ) {
            if ( $list->[1] =~ m/\A(?:underline|strong|em|class|attr|inline|block|sup|sub)\z/ ) {
                my %attr = _get_attr_hash_from_list( $list, 3 );

                if (   $list->[2] =~ m/\A$bn_var_arg\z/
                    && ( !exists $attr{'title'} || $attr{'title'} =~ m/\A$bn_var_arg\z/ )
                    && ( !exists $attr{'alt'}   || $attr{'alt'} =~ m/\A$bn_var_arg\z/ ) ) {
                    return 'basic_var';
                }
            }

            # TODO: do url && factor in html/plain attr && add to t/13.phrase_object_precursor_functions.t
            if ( $list->[1] =~ m/\A(?:img|abbr|acronym)\z/ ) {
                my %attr = _get_attr_hash_from_list( $list, 4 );

                # if any of these are true (except maybe $list->[2]) w/ these functions
                # then the caller is probably doing something wrong, the class/methods
                # will help find those sort of things better.
                if (   $list->[2] =~ m/\A$bn_var_arg\z/
                    && $list->[3] =~ m/\A$bn_var_arg\z/
                    && ( !exists $attr{'title'} || $attr{'title'} =~ m/\A$bn_var_arg\z/ )
                    && ( !exists $attr{'alt'}   || $attr{'alt'} =~ m/\A$bn_var_arg\z/ ) ) {
                    return 'basic_var';
                }
            }
        }

        return 'basic';
    }

    return 'complex' if exists $complex{ $list->[0] } && ( ref( $complex{ $list->[0] } ) ne 'CODE' || $complex{ $list->[0] }->($list) );
    return '_unknown';    # recommend to treat like 'basic' unless its one you know about that your class defines or if it's a show stopper
}

1;

__END__

=encoding utf-8

=head1 NAME

Locale::Maketext::Utils::Phrase - Consolidated Phrase Introspection

=head1 VERSION

This document describes Locale::Maketext::Utils::Phrase version 0.1

=head1 SYNOPSIS

    use Locale::Maketext::Utils::Phrase ();

    my $struct = Locale::Maketext::Utils::Phrase::phrase2struct(
        "So long, and thanks for [output,strong,all] the fish."
    );

    for my $piece (@{$struct}) {
        if (!ref($piece)) {
            # this $piece is a non-bracket notation chunk
        }
        else {
            # this $piece is a hashref describing the bracket notation chunk
        }
    }

=head1 DESCRIPTION

This module is meant to allow you to simplify an already complex task by doing all of the parsing and basic categorization of bracket notation (or lack of BN) for you.

That way you do not have to worry about parsing or matching the syntax/escaping/delimiters/etc correctly and then maintaining it in each place it is used.

=head1 INTERFACE

=head2 Object

Eventually the base functions below will be used in an object that can be used for even more complete and fine tuned introspection.

For now these functions allow us to do most of what we need with little trouble.

=head2 Functions

Terms:

=over 4

=item Phrase

A string intended to be passed to maketext() that may or may not contain bracket notation.

=item Struct

An array ref that represents a parsed phrase.

Each item in that array is either a string (a chunk that is not bracket notation) or a hashref (a chunk that is bracket notation).

The hashref has the following keys:

=over 4

=item orig

The value is the original bracket notation string in its entirety. e.g. '[output,strong,NOT]'

=item cont

The value is the content of the inside of original bracket notation string. e.g. 'output,strong,NOT'

=item list

The value is the original bracket notation in list form. e.g. an array reference containing 'output', 'strong', 'NOT'.

=item type

This is a string defining what general type of bracket notation we’re dealing with:

=over 4

=item 'var'

The content is a variable reference (i.e. not translatable).

e.g. [_1]

=item 'meth'

The content is a method that shouldn’t have any translatable part.

e.g. [numf,_1]

=item 'basic'

The content is a method that can have translatable parts and follows a basic pattern like the first part or two after the method can be a string and the rest can be an arbitrary name/value attribute list.

e.g. [output,strong,foo]

=item 'basic_var'

The content is 'basic' except every possible translatable part is a variable reference (i.e. not translatable).

e.g. [output,strong,_1]

=item 'complex'

The content is more complicated than 'basic'.

=item '_unknown'

The content type could not be determined. This is not necessarily an error. It could be a method specific to your object, it could be something this module misses (rt please!).

=item '_invalid'

The content type is invalid.

This could be something L<Locale::Maketext> would see as a syntax error (e.g. ["  ,foo"]) or something it might allow through (on purpose or by happenstance (e.g. [])) but is ambiguous for no gain.

=back

=back

=back

=head3 Phrase related

These all take a phrase as their only argument.

=head4 phrase2struct()

Returns the struct for the given phrase.

If there is a problem it will croak either "Unbalanced bracket: “…”" or "L</"Consecutive tildes are ambiguous">: “…”".

=head4 phrase_has_bracket_notation()

Returns a boolean.

True: the given phrase has bracket notation.

False: the given phrase does not have any bracket notation.

=head4 phrase_is_entirely_bracket_notation()

Returns a boolean.

True: the given phrase is entirely bracket notation.

False: the given phrase is not entirely bracket notation.

=head4 Consecutive tildes are ambiguous

In order to keep the parsing as simple/fast as possible we avoid trying to properly interpret multiple consecutive tildes.

In the rare case you really need a literal ~ to precede a comma, ~, [, or ] (really, anywhere in the string) just use the explicit placeholder string “_TILDE_”.

    $lh->maketext('A tilde is this: _TILDE_, you like?');

    $lh->maketext('A tilde [output,strong,is this: _TILDE_, you like]?');

=head3 Structure Related

These all take a struct as their only argument.

=head4 struct2phrase()

Returns the given struct as a stringified phrase.

=head4 struct_has_bracket_notation()

Returns a boolean.

True: the given struct has bracket notation.

False: the given struct does not have any bracket notation.

=head4 struct_is_entirely_bracket_notation()

Returns a boolean.

True: the given struct is entirely bracket notation.

False: the given struct is not entirely bracket notation.

=head3 Misc

=head4 get_bn_var_regexp()

Takes no arguments, returns a regular expression that matches bracket notation variable syntax.

    my $bn_var_regexp = Locale::Maketext::Utils::Phrase::get_bn_var_regexp();
    if ($string =~ m/\A$bn_var_regexp\z/) {
        # string is a BN variable
    }
    elsif ($string =~ m/$bn_var_regexp/) {
        # string contains a BN variable
    }

    my @bn_variables = $string =~ m/($bn_var_regexp)/g;

=head4 get_non_translatable_type_regexp()

Takes no arguments, returns a regular expression that matches types that should not have any translatable parts.

    my $non_translatable_type_regexp  = Locale::Maketext::Utils::Phrase::get_non_translatable_type_regexp();
    if ($piece->{'type'} =~ m/\A$non_translatable_type_regexp\z/) {
        # nothing to translate here, move along, move along
    }

    if ($xliff->{'ctype'} =~ m/\Ax-bn-$non_translatable_type_regexp\z/) {
        # handle the XLIFF syntax for non-translatable <ph> tags back into bracket notation
    }

=head4 string_has_opening_or_closing_bracket()

Takes one argument, a string. Returns true if it contains an opening or closing bracket.

    if ( !Locale::Maketext::Utils::Phrase::string_has_opening_or_closing_bracket($string) ){
        # $string does not have any bracket notation.
    }

=head3 Private functions

These are essentially meant to be used internally but if you find a use for them be sure to verify the values you pass to them or you will get odd results.

=over 4

=item _split_bn_cont()

Takes the 'cont' of the bracket notation piece hashref and optionally the max number of item to split it into and returns the resulting array.

Used internally to build the hash’s 'list' value.

=item _get_attr_hash_from_list()

Takes the 'list' of the bracket notation piece hashref and the index of where the arbitrary attributes begin and returns a hash. Accounts for non-key/value variable array refs.

=item _get_bn_type_from_list()

Takes the 'list' of the bracket notation piece hashref and returns the type.

Used internally to build the hash’s 'type' value.

=back

=head1 DIAGNOSTICS

Nothing besides what is documented in phrase2struct().

=head1 CONFIGURATION AND ENVIRONMENT

Locale::Maketext::Utils::Phrase requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Locale::Maketext::Utils>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-locale-maketext-utils-mock@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 TODO

Add in the object layer to really make the introspection complete.

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
