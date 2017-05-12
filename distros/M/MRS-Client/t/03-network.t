#!perl -T

BEGIN {
    use Test::More;
    unless ($ENV{AUTHOR_TESTING}) {
        plan(skip_all => 'these tests are for testing by the author (when AUTHOR_TESTING=1)');
    }
}

BEGIN {
    use_ok ('MRS::Client');
}
diag( "Calling MRS services" );

#my $client = MRS::Client->new (host => 'localhost');
my $client = MRS::Client->new();
my $db = $client->db ('enzyme');

$db->name;
ok ($db->name,                              'Databank name');
ok ($db->version,                           'Databank version');
ok ($db->count > -1,                        'Databank non-negative count');
ok ($db->parser,                            'Databank parser');
ok ($db->url,                               'Databank URL');
can_ok ($db, 'blastable');

ok (@{ $db->files } > 0,                      'Databank files');
my $file = $db->files->[0];
isa_ok ($file, 'MRS::Client::Databank::File', 'File instance');
ok ($file->id,                                'File ID');
ok ($file->last_modified,                     'File date');
ok ($file->version,                           'File version');
ok ($file->entries_count > -1,                'File non-negative count');
ok ($file->raw_data_size > -1,                'File raw data size');
ok ($file->file_size > -1,                    'File size');

ok (@{ $db->indices } > 0,                     'Databank indices');
my $index = $db->indices->[0];
isa_ok ($index, 'MRS::Client::Databank::Index', 'Index instance');
ok ($index->id,                                 'Index ID');
ok (defined $index->description,                'Index description');
ok ($index->count > -1,                         'Index non-negative count');
ok (defined $index->type,                       'Index type');

my $find = $db->find ('human');
isa_ok ($find, 'MRS::Client::Find',     'Find instance');
# ok ($find->{client} == $client,         'Find back reference');
ok ($find->db eq $db->id,               'Find database ID');
ok ($find->count > -1,                  'Find non-negative count');
ok ($find->max_entries > -1,            'Find non-negative max');
ok (@{ $find->terms } > 0,              'Find result count');
is ($find->terms->[0], 'human',         'Find term');
can_ok ($find, 'all_terms_required');
can_ok ($find, 'query');

# examples from the MRS::Client manual page
$client = MRS::Client->new();
ok ($client->db ('uniprot')->find ('sapiens')->count > 1,  'Uniprot count');
my $data = $client->db ('uniprot')->find ('sapiens')->next;
ok ($data =~ m{^ID},  'Uniprot next');
{
    $data = '';
    my $query = $client->db ('enzyme')->find ('and' => ['snake', 'human'],
                                              'format' => MRS::EntryFormat->HEADER);
    while (my $record = $query->next) {
        $data .= $record . "\n";
    }
    ok ($data =~ m{^enzyme\t\d},  'Enzyme AND HEADER');
}
{
    my $query = $client->db ('sprot')->find ('and' => ['snake', 'canine'],
                                             query => 'NOT (kinase OR reductase)',
                                             'format' => MRS::EntryFormat->HEADER);
    my $count = $query->count;
    ok ($count > 0,   'SwissProt count');
    my $line_count = 0;
    while (my $record = $query->next) {
        $line_count++;
    }
    is ($line_count, $count, 'SwissProt count: AND BOOLEAN');
}

{
    # running blast
    my $job = $client->blast->run (fasta => ">b1gv78_schgr Insulin-related peptide transcript variant T1;\nMWKLCLRLLAVLAVCLCTATQAQSDLFLLSPKRSGAPQPVARYCGEKLSNALKIVCRGNYNTMFKKASQDVS\nDAESEDNYWSQSADEEVEAPALPPYPVLARPSAGGLLTAAVFRRRTRGVFDECCRKSCSISELQTYCGRR\n",
                                   expect => '1.1E02',
                                   db => 'sprot');
    ok ($job->id, "Blast: Missing job ID");
    ok ($job->status, "Blast: Missing status");
    while (not $job->completed) {
        diag ('Waiting for 10 seconds... [status: ' . $job->status . ']');
        sleep 10;
    }
    ok ($job->results, "Blast: Missing results");
}

#done_testing();
done_testing(37);
