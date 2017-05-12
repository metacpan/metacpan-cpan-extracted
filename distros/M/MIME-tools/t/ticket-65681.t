#!/usr/bin/perl
use Test::More tests => 2;
use MIME::Parser;

open(IN, '<testmsgs/simple.msg');
my $data = do {	local $/; <IN> };
close(IN);

my $data_with_crlf = $data;

# This one MUST have CRLF
$data_with_crlf =~ s/\r\n|\n\r|\n|\r/\r\n/g;

# This one MUST NOT have CRLF
$data =~ s/\r\n|\n\r|\n|\r/\n/g;

my $parser = MIME::Parser->new();
$parser->output_to_core(1);

my $entity = $parser->parse_data($data);
my $entity_crlf = $parser->parse_data($data_with_crlf);

is ($entity->head->get('Subject', 0),
    $entity_crlf->head->get('Subject', 0),
    'Headers unchanged by line-ending conventions');
is ($entity->head->get('Subject', 0), 'Request for Leave' . "\n",
    'Got expected subject');

#print STDERR "\n\nMIME::tools version is " . $MIME::Tools::VERSION . "\n\n";
