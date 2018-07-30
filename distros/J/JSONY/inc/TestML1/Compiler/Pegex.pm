package TestML1::Compiler::Pegex;

use TestML1::Base;
extends 'TestML1::Compiler';

use TestML1::Compiler::Pegex::Grammar;
use TestML1::Compiler::Pegex::AST;
use Pegex::Parser;

has parser => ();

sub compile_code {
    my ($self) = @_;

    $self->{parser} = Pegex::Parser->new(
        grammar => TestML1::Compiler::Pegex::Grammar->new,
        receiver => TestML1::Compiler::Pegex::AST->new,
    );
    $self->fixup_grammar;

    $self->parser->parse($self->code, 'code_section')
        or die "Parse TestML1 code section failed";
}

sub compile_data {
    my ($self) = @_;

    if (length $self->data) {
        $self->parser->parse($self->data, 'data_section')
            or die "Parse TestML1 data section failed";
    }

    $self->{function} = $self->parser->receiver->function;
}

# TODO This can be moved to the AST some day.
sub fixup_grammar {
    my ($self) = @_;

    my $tree = $self->{parser}->grammar->tree;

    my $point_lines = $tree->{point_lines}{'.rgx'};

    my $block_marker = $self->directives->{BlockMarker};
    if ($block_marker) {
        $block_marker =~ s/([\$\%\^\*\+\?\|])/\\$1/g;
        $tree->{block_marker}{'.rgx'} = qr/\G$block_marker/;
        $point_lines =~ s/===/$block_marker/;
    }

    my $point_marker = $self->directives->{PointMarker};
    if ($point_marker) {
        $point_marker =~ s/([\$\%\^\*\+\?\|])/\\$1/g;
        $tree->{point_marker}{'.rgx'} = qr/\G$point_marker/;
        $point_lines =~ s/\\-\\-\\-/$point_marker/;
    }

    $tree->{point_lines}{'.rgx'} = qr/$point_lines/;
}

1;
