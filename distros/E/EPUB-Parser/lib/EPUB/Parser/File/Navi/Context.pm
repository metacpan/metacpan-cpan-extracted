package EPUB::Parser::File::Navi::Context;
use strict;
use warnings;
use Smart::Args;
use EPUB::Parser::Util::Context qw/child_class context_name parser/;

sub new {
    args(
        my $class  => 'ClassName',
        my $context_name => 'Str',
        my $parser,
    );

    my $child_class = $class->child_class({
        context_name => $context_name,
    });

    my $child = bless {
        parser    => $parser,
        context_name => $context_name,
    } => $child_class;


    return $child;
}


1;
