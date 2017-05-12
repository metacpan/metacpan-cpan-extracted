package EPUB::Parser::File::OPF::Context;
use strict;
use warnings;
use Smart::Args;
use Scalar::Util qw/weaken/;
use EPUB::Parser::Util::Context qw/child_class context_name parser/;

sub new {
    args(
        my $class  => 'ClassName',
        my $opf    => { isa => 'EPUB::Parser::File::OPF' },
        my $context_name => 'Str',
        my $parser,
    );

    my $child_class = $class->child_class({
        context_name => $context_name,
    });

    my $child = bless {
        opf       => $opf,
        parser    => $parser,
        context_name => $context_name,
    } => $child_class;

    weaken $child->{opf};

    return $child;
}


sub opf { shift->{opf} }

1;
