package MarpaX::Simple;

our $DATE = '2017-07-10'; # DATE
our $VERSION = '0.07'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Marpa::R2;
use UUID::Random;

use Exporter qw(import);
our @EXPORT_OK = qw(gen_parser);

our %SPEC;

$SPEC{gen_parser} = {
    v => 1.1,
    summary => 'Generate Marpa-based parser',
    description => <<'_',

One of `slif_grammar`, `grammar_class_file`, `grammar_module_file`,
`grammar_file`, `grammar` must be specified for the input grammar. The arguments
will be checked in that order. The simplest would be to use grammar text inlined
in your source code (`grammar`), but for larger grammar it might be more
convenient to put it in a separate file (the `grammar_*file` arguments) so you
can check line numbers from error messages more easily. The `slif_grammar` has
the lowest overhead since you specify SLIF grammar that are already
instantiated. See also the related Dist::Zilla plugin
`Dist::Zilla::Plugin::InsertMarpaSLIFGrammar`.


_
    args => {
        slif_grammar => {
            summary => 'SLIF input grammar',
            schema  => ['obj*', isa=>'Marpa::R2::Scanless::G'],
            description => <<'_',

This input-grammar argument is checked first because it is the most ready-to-use
form and has the least overhead. The other input-grammar arguments require
creating the `Marpa::R2::Scanless::G` object first from the Marpa BNF DSL
grammar.

_
            tags    => ['category:input-grammar'],
        },
        grammar_class_file => {
            summary => 'Marpa BNF input grammar file, '.
                'resolved using File::ShareDir\'s class_file()',
            schema  => 'str*',
            tags    => ['category:input-grammar'],
        },
        grammar_module_file => {
            summary => 'Marpa BNF input grammar file, '.
                'resolved using File::ShareDir\'s module_file()',
            schema  => 'str*',
            tags    => ['category:input-grammar'],
        },
        grammar_file => {
            summary => 'Marpa BNF input grammar file',
            schema  => 'str*',
            tags    => ['category:input-grammar'],
        },
        grammar => {
            summary => 'Marpa BNF input grammar text',
            schema  => 'str*',
            tags    => ['category:input-grammar'],
        },

        actions => {
            summary => 'Supply code for actions specified in the grammar',
            schema  => ['hash*', each_value => 'code*'],
        },
        too_many_earley_items => {
            summary => "Will be passed to recognizer's constructor",
            schema  => ['int*'],
        },
        trace_terminals => {
            summary => "Will be passed to recognizer's constructor",
            schema  => ['bool'],
        },
        trace_values => {
            summary => "Will be passed to recognizer's constructor",
            schema  => ['bool'],
        },
    },
    result_naked => 1,
    result => {
        schema => 'code*',
    },
};
sub gen_parser {
    no strict 'refs';

    my %args = @_;

    my $slif;
    {
        my $bnf;
        if ($args{slif_grammar}) {
            $slif = $args{slif_grammar};
            last;
        } elsif ($args{grammar_class_file}) {
            require File::ShareDir;
            require File::Slurper;
            $bnf = File::Slurper::read_text(
                File::ShareDir::class_file(__PACKAGE__,
                                           $args{grammar_class_file}));
        } elsif ($args{grammar_module_file}) {
            require File::ShareDir;
            require File::Slurper;
            $bnf = File::Slurper::read_text(
                File::ShareDir::module_file(__PACKAGE__,
                                            $args{grammar_module_file}));
        } elsif ($args{grammar_file}) {
            require File::Slurper;
            $bnf = File::Slurper::read_text($args{grammar_file});
        } elsif ($args{grammar}) {
            $bnf = $args{grammar};
        }
        $slif = Marpa::R2::Scanless::G->new({source => \$bnf});
    }

    my $pkg = __PACKAGE__ . '::gen' . substr(UUID::Random::generate(), 0, 8);
    my $acts = $args{actions};
    for (keys %$acts) {
        *{"$pkg\::$_"} = $acts->{$_};
    }

    my $parser = sub {
        my $input = shift;

        my $rec_args = {
            grammar => $slif,
            semantics_package => $pkg,
            trace_terminals => $args{trace_terminals} ? 1:0,
            trace_values    => $args{trace_values}    ? 1:0,
        };
        $rec_args->{too_many_earley_items} = $args{too_many_earley_items}
            if $args{too_many_earley_items};
        my $recce = Marpa::R2::Scanless::R->new($rec_args);
        $recce->read(\$input);
        my $valref = $recce->value;
        if (!defined($valref)) {
            die "No parse was found after reading the entire input\n";
            # XXX show last expression
        }
        $$valref;
    };

    $parser;
}

1;
# ABSTRACT: Generate Marpa-based parser

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Simple - Generate Marpa-based parser

=head1 VERSION

This document describes version 0.07 of MarpaX::Simple (from Perl distribution MarpaX-Simple), released on 2017-07-10.

=head1 SYNOPSIS

 use MarpaX::Simple qw(gen_parser);

 my $parser = gen_parser(
     grammar => <<'EOG',
 :start     ::= expr
 expr       ::= num
              | num '+' num    action => do_add
 num        ~ [\d]+
 :discard   ~ whitespace
 whitespace ~ [\s]+
 EOG
     actions => {
         do_add => sub { shift; $_[0] + $_[2] }
     },
 );

 print $parser->('3 + 4'); # -> 7
 print $parser->('3 + ');  # dies with parse error

which is a shortcut for roughly this:

 no strict 'refs';
 use Marpa::R2;
 my $slif = Marpa::R2::Scanless::G->new({source => \$args{grammar}});
 my $pkg = "MarpaX::Simple::gen" . some_random_value();
 my $actions = $args{actions};
 for (keys %$actions) {
     ${"$pkg\::$_"} = $actions->{$_};
 }
 my $parser = sub {
     my $input = shift;
     my $recce = Marpa::R2::Scanless::R->new({
         grammar => $slif,
         semantics_package => $pkg,
     });
 };

=head1 DESCRIPTION

This module tries to simplify the incantation of producing a parser using
L<Marpa::R2> (the scanless interface) by reducing the process to a single
function call: C<gen_parser>.

=head1 FUNCTIONS


=head2 gen_parser

Usage:

 gen_parser(%args) -> code

Generate Marpa-based parser.

One of C<slif_grammar>, C<grammar_class_file>, C<grammar_module_file>,
C<grammar_file>, C<grammar> must be specified for the input grammar. The arguments
will be checked in that order. The simplest would be to use grammar text inlined
in your source code (C<grammar>), but for larger grammar it might be more
convenient to put it in a separate file (the C<grammar_*file> arguments) so you
can check line numbers from error messages more easily. The C<slif_grammar> has
the lowest overhead since you specify SLIF grammar that are already
instantiated. See also the related Dist::Zilla plugin
C<Dist::Zilla::Plugin::InsertMarpaSLIFGrammar>.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<actions> => I<hash>

Supply code for actions specified in the grammar.

=item * B<grammar> => I<str>

Marpa BNF input grammar text.

=item * B<grammar_class_file> => I<str>

Marpa BNF input grammar file, resolved using File::ShareDir's class_file().

=item * B<grammar_file> => I<str>

Marpa BNF input grammar file.

=item * B<grammar_module_file> => I<str>

Marpa BNF input grammar file, resolved using File::ShareDir's module_file().

=item * B<slif_grammar> => I<obj>

SLIF input grammar.

This input-grammar argument is checked first because it is the most ready-to-use
form and has the least overhead. The other input-grammar arguments require
creating the C<Marpa::R2::Scanless::G> object first from the Marpa BNF DSL
grammar.

=item * B<too_many_earley_items> => I<int>

Will be passed to recognizer's constructor.

=item * B<trace_terminals> => I<bool>

Will be passed to recognizer's constructor.

=item * B<trace_values> => I<bool>

Will be passed to recognizer's constructor.

=back

Return value:  (code)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/MarpaX-Simple>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-MarpaX-Simple>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=MarpaX-Simple>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Marpa::R2>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2015, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
