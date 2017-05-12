package Test::Lingua::EO::Orthography::Base;


# ****************************************************************
# pragma(s)
# ****************************************************************

use strict;
use warnings;
use utf8;


# ****************************************************************
# basic dependency(-ies)
# ****************************************************************

use Encode qw(find_encoding);
use Test::Exception;
use Test::More;


# ****************************************************************
# internal dependency(-ies)
# ****************************************************************

use Lingua::EO::Orthography;


# ****************************************************************
# test method(s)
# ****************************************************************

sub test_basic {
    my $self = shift;

    my $converter = $self->class->new;

    isa_ok(
        $converter,
        $self->class,
    );

    can_ok(
        $converter,
        qw(
            convert
            sources
            target
            all_sources
            add_sources
            remove_sources
        ),
    );

    return;
}

sub test_orthographize {
    my $self = shift;

    my $orthography = $self->orthography;
    my $converter = $self->class->new( target => $orthography );
    is(
        $converter->target,
        $orthography,
        sprintf(
            'Get $converter->target: %s',
                $orthography,
        ),
    );

    # Note: Memoized _source_pattern() should be passed @source_notations,
    #       instead of $source_notations_ref
    foreach my $substitution ( $self->substitutions ) {
        is_deeply(
            $converter->sources([ $substitution ]),
            [ $substitution ],
            sprintf(
                'Get $converter->sources: [ %s ]',
                    $substitution,
            ),
        );
        my $converted = $converter->convert(
            $self->string_of( $substitution )
        );
        is(
            $converted,
            $self->string_of(
                  $substitution =~ m{zamenhof} ? $orthography . '_u'
                :                                   $orthography
            ),
            sprintf(
                "Convert (orthographize): from %s => to %s",
                    $substitution,
                    $orthography,
            ),
        );
        ok(
            utf8::is_utf8($converted),
            'Converted string turned utf8 flag on',
        );
    }

    return;
}

sub test_substitutize {
    my $self = shift;

    my $orthography = $self->orthography;
    my $converter = $self->class->new( sources => [ $orthography ] );
    is_deeply(
        $converter->sources,
        [ $orthography ],
        sprintf(
            'Get $converter->sources: [ %s ]',
                $orthography,
        ),
    );

    foreach my $substitution ( $self->substitutions ) {
        is(
            $converter->target( $substitution ),
            $substitution,
            sprintf(
                'Get $converter->target: %s',
                    $substitution,
            ),
        );
        my $converted = $converter->convert(
            $self->string_of( $orthography )
        );
        is(
            $converted,
            $self->string_of( $substitution ),
            sprintf(
                "Convert (substitutize): from %s => to %s",
                    $orthography,
                    $substitution,
            ),
        );
        ok(
            utf8::is_utf8($converted),
            'Converted string turned utf8 flag on',
        );
    }

    return;
}

sub test_plurally_orthographize {
    my $self = shift;

    my $orthography = $self->orthography;

    my $converter = $self->class->new(
        sources => [ qw(postfix_h) ],
        target  => $orthography,
    );

    is_deeply(
        $converter->add_sources( qw(postfix_x) ),
        [qw( postfix_h postfix_x )],
        'Add postfix_x',
    );
    is(
        $converter->convert( $self->string_of( $converter->all_sources ) ),
        $self->string_of( ($orthography) x scalar $converter->all_sources ),
        'Convert (plurally): postfix_h, postfix_x',
    );

    is_deeply(
        $converter->add_sources( qw(postfix_caret prefix_caret postfix_h) ),
        [qw( postfix_h postfix_x postfix_caret prefix_caret )],
        'Add postfix_caret, prefix_caret, (postfix_h)',
    );
    is(
        $converter->convert( $self->string_of( $converter->all_sources ) ),
        $self->string_of( ($orthography) x scalar $converter->all_sources ),
        'Convert (plurally): postfix_h, postfix_x, postfix_caret, prefix_caret',
    );

    is_deeply(
        [ $converter->all_sources ],
        $converter->sources,
        'All sources',
    );

    is_deeply(
        $converter->remove_sources( qw(postfix_h) ),
        [qw( postfix_x postfix_caret prefix_caret )],
        'Remove postfix_h',
    );
    is(
        $converter->convert( $self->string_of( $converter->all_sources ) ),
        $self->string_of( ($orthography) x scalar $converter->all_sources ),
        'Convert (plurally): postfix_x, postfix_caret, prefix_caret',
    );

    is_deeply(
        $converter->remove_sources( qw( postfix_x postfix_caret postfix_caret) ),
        [qw( prefix_caret )],
        'Remove postfix_x, postfix_caret, (postfix_caret)',
    );
    is(
        $converter->convert( $self->string_of( $converter->all_sources ) ),
        $self->string_of( ($orthography) x scalar $converter->all_sources ),
        'Convert (plurally): prefix_caret',
    );

    return;
}

sub test_exception_on_sources {
    my $self = shift;

    my $converter = $self->class->new;

    # new
    throws_ok {
        $self->class->new( sources => $self->orthography );
    } $self->exception_of('sources', 'not_aref'),
    'Throws an exception: $class->new( sources => $scalar )';

    throws_ok {
        $self->class->new( sources => undef );
    } $self->exception_of('sourcs', 'not_aref'),
    'Throws an exception: $class->new( sources => undef )';

    throws_ok {
        $self->class->new( sources => [] );
    } $self->exception_of('sources', 'null_aref'),
    'Throws an exception: $class->new( sources => [] )';

    throws_ok {
        $self->class->new( sources => [ [$self->orthography] ] );
    } $self->exception_of('sources', 'not_primitive'),
    'Throws an exception: $class->new( sources => [ $not_primitive ] )';

    throws_ok {
        $self->class->new( sources => [$self->orthography, 'foobar'] );
    } $self->exception_of('sources', 'not_enumerated'),
    'Throws an exception: $class->new( sources => [($exists, $not_exists)] )';

    # sources
    throws_ok {
        $converter->sources( $self->orthography );
    } $self->exception_of('sources', 'not_aref'),
    'Throws an exception: $class->sources( $scalar )';

    throws_ok {
        $converter->sources( undef );
    } $self->exception_of('sources', 'not_aref'),
    'Throws an exception: $class->sources( undef )';

    throws_ok {
        $converter->sources( [] );
    } $self->exception_of('sources', 'null_aref'),
    'Throws an exception: $class->sources( [] )';

    throws_ok {
        $converter->sources( [ [$self->orthography] ] );
    } $self->exception_of('sources', 'not_primitive'),
    'Throws an exception: $class->sources( [ $not_primitive ] )';

    throws_ok {
        $converter->sources( [$self->orthography, 'foobar'] );
    } $self->exception_of('sources', 'not_enumerated'),
    'Throws an exception: $class->sources( [($exists, $not_exists)] )';

    # add_sources
    throws_ok {
        $converter->add_sources( undef );
    } $self->exception_of('add_sources', 'not_primitive'),
    'Throws an exception: $class->add_sources( undef )';

    throws_ok {
        $converter->add_sources( [] );
    } $self->exception_of('add_sources', 'not_primitive'),
    'Throws an exception: $class->add_sources( $not_primitive )';

    throws_ok {
        $converter->add_sources( $self->orthography, 'foobar' );
    } $self->exception_of('add_sources', 'not_enumerated'),
    'Throws an exception: $class->add_sources( $exists, $not_exists )';

    # remove_sources
    throws_ok {
        $converter->remove_sources( undef );
    } $self->exception_of('remove_sources', 'not_primitive'),
    'Throws an exception: $class->remove_sources( undef )';

    throws_ok {
        $converter->remove_sources( [] );
    } $self->exception_of('remove_sources', 'not_primitive'),
    'Throws an exception: $class->remove_sources( $not_primitive )';

    throws_ok {
        $converter->remove_sources( $self->orthography, 'foobar' );
    } $self->exception_of('remove_sources', 'not_enumerated'),
    'Throws an exception: $class->remove_sources( $exists, $not_exists )';

    throws_ok {
        $converter->remove_sources( $converter->all_sources );
    } $self->exception_of('remove_sources', 'at_least_one'),
    'Throws an exception: $class->remove_sources( @all_sources )';

    return;
}

sub test_exception_on_target {
    my $self = shift;

    my $converter = $self->class->new;

    # new
    throws_ok {
        $self->class->new( target => undef );
    } $self->exception_of('sourcs', 'not_primitive'),
    'Throws an exception: $class->new( target => undef )';

    throws_ok {
        $self->class->new( target => [] );
    } $self->exception_of('target', 'not_primitive'),
    'Throws an exception: $class->new( target => [] )';

    throws_ok {
        $self->class->new( target => 'foobar' );
    } $self->exception_of('target', 'not_enumerated'),
    'Throws an exception: $class->new( target => $not_exists )';

    # target
    throws_ok {
        $converter->target( undef );
    } $self->exception_of('target', 'not_primitive'),
    'Throws an exception: $class->target( undef )';

    throws_ok {
        $converter->target( [] );
    } $self->exception_of('target', 'not_primitive'),
    'Throws an exception: $class->target( [] )';

    throws_ok {
        $converter->target( 'foobar' );
    } $self->exception_of('target', 'not_enumerated'),
    'Throws an exception: $class->target( $not_exists )';

    return;
}

sub test_exception_on_convert {
    my $self = shift;

    my $converter = $self->class->new;

    throws_ok {
        $converter->convert( undef );
    } $self->exception_of('convert'),
    'Throws an exception: $class->convert( undef )';

    throws_ok {
        $converter->convert( [] );
    } $self->exception_of('convert'),
    'Throws an exception: $class->convert( [] )';

    return;
}

# Note: This is an edge case.
sub test_flughaveno {
    my $self = shift;

    my $converter = $self->class->new;
    my $encoding  = $self->encoding;

    TODO: {
        local $TODO = 'Some words have border between roots '
                    . 'as if it was substitutized';

        is(
            $encoding->encode( $converter->convert('flughaveno') ),
            'flughaveno',
            'Convert (orthographize) flughaveno',
        );
    };

    return;
}


# ****************************************************************
# utility(-ies)
# ****************************************************************

sub class {
    my $self = shift;

    return q(Lingua::EO::Orthography);
}

sub substitutions {
    return qw(
        postfix_x
        postfix_capital_x
        zamenhof
        capital_zamenhof
        postfix_h
        postfix_capital_h
        postfix_caret
        prefix_caret
        postfix_apostrophe
    );
}

sub orthography {
    return q(orthography);
}

sub string_of {
    my ($self, @notations) = @_;

    my %string = (
        orthography         => qq(\x{108}\x{109}\x{11C}\x{11D}\x{124}\x{125})
                             . qq(\x{134}\x{135}\x{15C}\x{15D}\x{16C}\x{16D}),
        orthography_u       => qq(\x{108}\x{109}\x{11C}\x{11D}\x{124}\x{125})
                             . qq(\x{134}\x{135}\x{15C}\x{15D}Uu),
        zamenhof            => q(ChchGhghHhhhJhjhShshUu),
        capital_zamenhof    => q(CHchGHghHHhhJHjhSHshUu),
        postfix_h           => q(ChchGhghHhhhJhjhShshUwuw),
        postfix_capital_h   => q(CHchGHghHHhhJHjhSHshUWuw),
        postfix_x           => q(CxcxGxgxHxhxJxjxSxsxUxux),
        postfix_capital_x   => q(CXcxGXgxHXhxJXjxSXsxUXux),
        postfix_caret       => q(C^c^G^g^H^h^J^j^S^s^U^u^),
        postfix_apostrophe  => q(C'c'G'g'H'h'J'j'S's'U'u'),
        prefix_caret        => q(^C^c^G^g^H^h^J^j^S^s^U^u),
    );

    my $string = '';
    foreach my $notation (@notations) {
        $string .= $string{$notation};
    }

    return $string;
}

sub exception_of {
    my ($self, $type, $cause) = @_;

    my %type = (
        sources        => 'Could not set source notations because: ',
        add_sources    => 'Could not add source notations because: ',
        remove_sources => 'Could not remove source notations because: ',
        target         => 'Could not set a target notation because: ',
        convert        => 'Could not convert string because '
                        . 'string (.+?) must be a primitive value',
    );

    my %cause = (
        not_aref       => 'Source notations must be an array reference',
        null_aref      => 'Source notations must be a nonnull array reference',
        not_primitive  => 'Notation (.+?) must be a primitive value',
        not_enumerated => 'Notation (".+?") does not enumerated',
        at_least_one   => 'Converter must maintain '
                        . 'at least one source notation',
    );

    my $pattern = $type{$type};
    $pattern .= $cause{$cause}
        if defined $cause;
    $pattern =~ s{
        (
            [\(\)]
        )
    }{\\$1}xmsg;

    return qr{$pattern};
}

sub encoding {
    return find_encoding('utf8');
}


# ****************************************************************
# return true
# ****************************************************************

1;
__END__


# ****************************************************************
# POD
# ****************************************************************

=head1 NAME

Test::Lingua::EO::Orthography::Base -

=head1 SYNOPSIS

    package Test::Lingua::EO::Orthography::Foobar;

    use base qw(
        Test::Class
        Test::Lingua::EO::Orthography::Base
    );

=head1 DESCRIPTION

This class provides us with basic test cases for
L<Lingua::EO::Orthography|Lingua::EO::Orthography>.

=head1 AUTHOR

=over 4

=item MORIYA Masaki, alias Gardejo

C<< <moriya at cpan dot org> >>,
L<http://gardejo.org/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010 MORIYA Masaki, alias Gardejo

This module is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.
See L<perlgpl|perlgpl> and L<perlartistic|perlartistic>.

The full text of the license can be found in the F<LICENSE> file
included with this distribution.

=cut
