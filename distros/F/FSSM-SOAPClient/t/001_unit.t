#-*-perl-*-
#$Id$

# FSSM::SOAPClient unit tests (no networking)
use lib 'lib';
use Test::More tests => 28;
use Test::Exception;
use SOAP::Lite;

use_ok('FSSM::SOAPClient');
ok my $client = FSSM::SOAPClient->new, 'factory';
is_deeply [ sort $client->available_parameters], [ sort qw( search expansion seqtype predictor )], 'available parameters';
is_deeply [sort $client->available_parameters('search')], [ sort qw(none fast align)], 'search parameters';
ok $client->search('none'), 'set search';
ok $client->expansion('avg'), 'set expansion';
ok $client->seqtype('aa'), 'set seqtype';
ok $client->predictor('subtype B SI/NSI'), 'set predictor';
throws_ok { $client->search('avg') } qr/^Invalid/;
my %parms = $client->get_parameters;
is_deeply \%parms, { search => 'none', expansion => 'avg', 
		     seqtype => 'aa', predictor => 'subtype B SI/NSI'}, 
    'get_parameters';
ok !$client->parameters_changed, 'parameters_changed';
ok $client->reset_parameters, 'reset_parameters';
ok !$client->search, 'parms reset';
ok !$client->parameters_changed, 'parameters not changed after read';

SKIP : {
    skip 'BioPerl not present', 2 unless eval { require Bio::Seq; 1 };
    open $f, "<t/test.dmp";
    local $/ = undef;
    my $seqs = eval <$f>;
    ok $client->attach_seqs($seqs), 'attach BioPerl seqs';
    is_deeply $client->{_seqs}, [ { seqid => 'seq1', type => 'nt', sequence => 'attccgcggcggtg'},
				  { seqid => 'seq2', type => 'nt', sequence => 'tttctgaggccttt'} ], '_seqs content';
}

open my $tf, 't/result.xml';
my $som;
{ 
    local $/ = undef;
  
  $som = SOAP::Deserializer->deserialize(<$tf>);
}
ok $result = FSSM::SOAPClient::Result->new($som), 'fake result';

is $result->metadata->{'your-ip'}, '127.0.0.1', 'metadata (1)';
like $result->metadata->{'date'}, qr/.*T.*/, 'metadata (2)';
ok my $hash = $result->next_call, 'iterate';
is $hash->{seqid}, 'seq1', 'data (1)';
ok $hash = $result->next_call, 'iterate';
is $hash->{seqid}, 'seq2', 'data (2)';
is $hash->{score}, 5.265, 'data (3)';
ok !$result->next_call, 'all through';
ok $result->rewind, 'rewind';
ok $result->next_call, 'rewound';
is scalar $result->each_call, 2, 'each_call';




