#!/usr/bin/perl
use lib qw (../lib lib);
use Test::More 'no_plan';
use strict;
use warnings;
use MKDoc::XML::Tokenizer;
use Data::Dumper;

my $data = qq|<foo bar"baz">Hello</foo>|;
eval { Dumper (MKDoc::XML::Tokenizer->process_data ($data)) };
ok ($@);

$data = qq |<p foo=bar>|;
eval { Dumper (MKDoc::XML::Tokenizer->process_data ($data)) };
ok ($@);

$data = qq |<p foo="bar">hello world</p>|;
eval { Dumper (MKDoc::XML::Tokenizer->process_data ($data)) };
ok (!$@);


$data = qq |<p foo='bar'>hello world</p>|;
eval { Dumper (MKDoc::XML::Tokenizer->process_data ($data)) };
ok (!$@);

$data = qq |<p foobar>hello world</p>|;
eval { print Dumper (MKDoc::XML::Tokenizer->process_data ($data)) };
ok ($@);

$data = qq |<p foo bar>hello world</p>|;
eval { print Dumper (MKDoc::XML::Tokenizer->process_data ($data)) };
ok ($@);

$data = qq |<p "foobar">hello world</p>|;
eval { print Dumper (MKDoc::XML::Tokenizer->process_data ($data)) };
ok ($@);


1;


__END__
