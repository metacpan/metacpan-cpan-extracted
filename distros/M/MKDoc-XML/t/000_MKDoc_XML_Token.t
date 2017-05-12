#!/usr/bin/perl
use lib qw (../lib lib);
use Test::More 'no_plan';
use strict;
use warnings;
use MKDoc::XML::Token;


my $file = (-e 't/data/sample.xml') ? 't/data/sample.xml' : 'data/sample.xml';


my $comment        = new MKDoc::XML::Token ('<!-- this is a comment -->');
my $declaration    = new MKDoc::XML::Token ('<!DECLARATION SOME BIG STOOPID DECLARATION>');
my $pi             = new MKDoc::XML::Token ('<?php 2 + 2?>');
my $open_tag_1     = new MKDoc::XML::Token ('<strong>');
my $open_tag_2     = new MKDoc::XML::Token ('<a href="foo">');
my $close_tag      = new MKDoc::XML::Token ('</strong>');
my $self_close_tag = new MKDoc::XML::Token ('<br />');
my $text           = new MKDoc::XML::Token ('this is some text');


{
    ok !$comment->tag_open();
    ok !$comment->tag_self_close();
    ok !$comment->tag_close();
    ok !$comment->pi();
    ok !$comment->declaration();
    ok  $comment->comment();
    ok !$comment->tag();
    ok  $comment->pseudotag();
    ok  $comment->leaf();
    ok !$comment->text();
}


{
    ok !$declaration->tag_open();
    ok !$declaration->tag_self_close();
    ok !$declaration->tag_close();
    ok !$declaration->pi();
    ok  $declaration->declaration();
    ok !$declaration->comment();
    ok !$declaration->tag();
    ok  $declaration->pseudotag();
    ok  $declaration->leaf();
    ok !$declaration->text();
}


{
    ok !$pi->tag_open();
    ok !$pi->tag_self_close();
    ok !$pi->tag_close();
    ok  $pi->pi();
    ok !$pi->declaration();
    ok !$pi->comment();
    ok !$pi->tag();
    ok  $pi->pseudotag();
    ok  $pi->leaf();
    ok !$pi->text();
}


{
    ok  $open_tag_1->tag_open();
    ok !$open_tag_1->tag_self_close();
    ok !$open_tag_1->tag_close();
    ok !$open_tag_1->pi();
    ok !$open_tag_1->declaration();
    ok !$open_tag_1->comment();
    ok  $open_tag_1->tag();
    ok !$open_tag_1->pseudotag();
    ok !$open_tag_1->leaf();
    ok !$open_tag_1->text();
    
    my $n = $open_tag_1->tag_open();
    ok ($n->{_open});
    ok (!$n->{_close});
}


{
    ok  $open_tag_2->tag_open();
    ok !$open_tag_2->tag_self_close();
    ok !$open_tag_2->tag_close();
    ok !$open_tag_2->pi();
    ok !$open_tag_2->declaration();
    ok !$open_tag_2->comment();
    ok  $open_tag_2->tag();
    ok !$open_tag_2->pseudotag();
    ok !$open_tag_2->leaf();
    ok !$open_tag_2->text();
    my $n = $open_tag_2->tag_open();
    ok ($n->{_open});
    ok (!$n->{_close});
}


{
    ok !$close_tag->tag_open();
    ok !$close_tag->tag_self_close();
    ok  $close_tag->tag_close();
    ok !$close_tag->pi();
    ok !$close_tag->declaration();
    ok !$close_tag->comment();
    ok  $close_tag->tag();
    ok !$close_tag->pseudotag();
    ok !$close_tag->leaf();
    ok !$close_tag->text();
    my $n = $close_tag->tag_close();
    ok (!$n->{_open});
    ok ($n->{_close});
}


{
    ok !$self_close_tag->tag_open();
    ok  $self_close_tag->tag_self_close();
    ok !$self_close_tag->tag_close();
    ok !$self_close_tag->pi();
    ok !$self_close_tag->declaration();
    ok !$self_close_tag->comment();
    ok  $self_close_tag->tag();
    ok !$self_close_tag->pseudotag();
    ok  $self_close_tag->leaf();
    ok !$self_close_tag->text();
    my $n = $self_close_tag->tag_self_close();
    ok ($n->{_open});
    ok ($n->{_close});
}


{
    ok !$text->tag_open();
    ok !$text->tag_self_close();
    ok !$text->tag_close();
    ok !$text->pi();
    ok !$text->declaration();
    ok !$text->comment();
    ok !$text->tag();
    ok !$text->pseudotag();
    ok  $text->leaf();
    ok  $text->text();
}

{
    my $tag = new MKDoc::XML::Token ('<p>');
    my $node = $tag->tag();
    is ($node->{_tag}, 'p');
}


{
    my $data = <<EOF;
    <input
      value="test"
      onfocus="if(t.value='';"
    />
EOF

    $data =~ s/^\s+//;
    $data =~ s/\s+$//;

    my $tag = new MKDoc::XML::Token ($data);
    $tag = $tag->leaf();
    is ($tag->{onfocus}, "if(t.value='';");
    is ($tag->{value}, "test");
}

1;


__END__
