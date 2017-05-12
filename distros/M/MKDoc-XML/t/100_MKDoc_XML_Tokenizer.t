#!/usr/bin/perl
use lib qw (../lib lib);
use Test::More 'no_plan';
use strict;
use warnings;
use MKDoc::XML::Tokenizer;

{
    my $data = <<EOF;
    <input
      value="test"
      onfocus="if(t.value='';"
    />
EOF

    my $tokens = MKDoc::XML::Tokenizer->process_data ($data);
    like ($tokens->[0]->as_string(), qr/value\=\"test\"/);
}


my $file = (-e 't/data/sample.xml') ? 't/data/sample.xml' : 'data/sample.xml';
my $tokens = MKDoc::XML::Tokenizer->process_file ($file);


like ($tokens->[0]->as_string(), qr/<!-- warning, this XML is entirely/);
like ($tokens->[1]->as_string(), qr/^\s+$/s);
like ($tokens->[2]->as_string(), qr/^<!DOCTYPE html PUBLIC/);
like ($tokens->[3]->as_string(), qr/^\s+$/s);
is   ($tokens->[4]->as_string(), '<?xml version="1.0" encoding="UTF-8"?>');
like ($tokens->[5]->as_string(), qr/^\s+$/s);
like ($tokens->[6]->as_string(), qr/^<rdf:RDF/s);
like ($tokens->[7]->as_string(), qr/^\s+$/s);
is   ($tokens->[8]->as_string(), qq |<!-- let's have a comment -->|);
like ($tokens->[9]->as_string(), qr/^\s+$/s);


1;


__END__
