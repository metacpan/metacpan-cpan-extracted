#!/usr/bin/perl
use lib qw (../lib lib);
use Test::More 'no_plan';
use strict;
use warnings;
use MKDoc::XML::Tokenizer;

my $data   = '<!-- this is -- invalid -->';
eval { MKDoc::XML::Tokenizer->process_data ($data) };
ok ($@);

1;


__END__
