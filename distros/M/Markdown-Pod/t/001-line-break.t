use lib 't/lib';
use strict;
use warnings;
use Test::More tests => 1;
use Markdown::Pod::Test qw( get_pod markdown_to_pod );

my $file = 't/mkd/001-line-break.mkd';
is markdown_to_pod($file), get_pod( \*DATA ), "converting $file";

__DATA__
=encoding utf8


=head2 NAME

Markdown::Pod - Convert Markdown to POD


=head2 VERSION

version 0.003


=head2 SYNOPSIS

    use Markdown::Pod;
    
    my $m2p = Markdown::Pod->new;
    my $pod = $m2p->markdown_to_pod(
        markdown => $markdown,
    );


=head2 DESCRIPTION

This module parses Markdown text and return POD text.
It uses Markdent module to parse Markdown.

Due to POD doesn't support blockquoted HTML tag,
so quoted text of Markdown will not be handled properly.

Quoted text will be converted to POD verbatim section.
