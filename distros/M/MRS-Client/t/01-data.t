#!perl -T

#use Test::More qw(no_plan);
use Test::More tests => 76;

BEGIN {
    use_ok ('MRS::Client');
}
diag( "Data manipulation" );

#
# these tests do not need access to the network
#

my $client = MRS::Client->new (host => 'NOT_USED');
ok ($client,                           'Main worker created');

$client->search_url      ('a'); is ($client->search_url,      'a', 'Set search_url');
$client->blast_url       ('b'); is ($client->blast_url,       'b', 'Set blast_url');
$client->clustal_url     ('c'); is ($client->clustal_url,     'c', 'Set clustal_url');
$client->admin_url       ('d'); is ($client->admin_url,       'd', 'Set admin_url');
$client->search_service  ('e'); is ($client->search_service,  'e', 'Set search_service');
$client->blast_service   ('f'); is ($client->blast_service,   'f', 'Set blast_service');
$client->clustal_service ('g'); is ($client->clustal_service, 'g', 'Set clustal_service');
$client->admin_service   ('h'); is ($client->admin_service,   'h', 'Set admin_service');
$client->search_wsdl     ('i'); is ($client->search_wsdl,     'i', 'Set search_wsdl');
$client->blast_wsdl      ('j'); is ($client->blast_wsdl,      'j', 'Set blast_wsdl');
$client->clustal_wsdl    ('k'); is ($client->clustal_wsdl,    'k', 'Set clustal_wsdl');
$client->admin_wsdl      ('l'); is ($client->admin_wsdl,      'l', 'Set admin_wsdl');

# Databank objects
my $db = $client->db ('enzyme');
isa_ok ($db, 'MRS::Client::Databank',   'Databank object created');
ok ($db->{client} == $client,           'Databank back reference');
ok ($db->id eq 'enzyme',                'Databank ID');

eval { MRS::Client::Databank->new() };
ok ($@,                                 'Databank without ID');

# Find objects
my $find;
eval { $find = MRS::Client::Find->new() };
like ($@, qr/empty/i,                   'Empty query request');

$find = MRS::Client::Find->new (undef, 'human');
is (@{ $find->terms }, 1,               'Find: scalar argument');
is ($find->terms->[0], 'human',         'Find: scalar argument 2');

$find = MRS::Client::Find->new (undef, 'human AND mouse');
ok (! $find->terms,                     'Find: scalar boolean argument');
is ($find->query, 'human AND mouse',    'Find: scalar boolean argument 2');

$find = MRS::Client::Find->new (undef, ['human', 'mouse']);
is (@{ $find->terms }, 2,               'Find: refarray argument');
is ($find->terms->[0], 'human',         'Find: refarray argument 2');
is ($find->terms->[1], 'mouse',         'Find: refarray argument 3');

$find = MRS::Client::Find->new (undef, 'and'   => ['human', 'mouse'],
                                query => 'cool');
is (@{ $find->terms }, 2,               'Find: refhash argument');
is ($find->terms->[0], 'human',         'Find: refhash argument 2');
is ($find->terms->[1], 'mouse',         'Find: refhash argument 3');
is ($find->query, 'cool',               'Find: refhash argument 4');

$find = MRS::Client::Find->new (undef, 'and' => ['some', 'any']);
is ($find->terms->[0], 'some',          'Find: argument AND');
is ($find->terms->[1], 'any',           'Find: argument AND 2');
ok ($find->all_terms_required,          'Find: argument AND 3');

$find = MRS::Client::Find->new (undef, 'or' => ['one', 'two']);
is ($find->terms->[0], 'one',           'Find: argument OR');
is ($find->terms->[1], 'two',           'Find: argument OR 2');
ok (!$find->all_terms_required,         'Find: argument OR 3');

foreach my $format (MRS::EntryFormat->PLAIN,
                    MRS::EntryFormat->TITLE,
                    MRS::EntryFormat->HTML,
                    MRS::EntryFormat->FASTA,
                    MRS::EntryFormat->SEQUENCE,
                    MRS::EntryFormat->HEADER) {
    eval { $find = MRS::Client::Find->new (undef, query => 'some', format => $format) };
    ok (!$@, "Find: correct format $format");
}
{
    local $SIG{__WARN__} = sub { };
    $find = MRS::Client::Find->new (undef, query => 'some', format => 'wrong');
    is ($find->{format}, MRS::EntryFormat->PLAIN,  'Find: default format');
}

foreach my $algorithm (MRS::Algorithm->VECTOR,
                       MRS::Algorithm->DICE,
                       MRS::Algorithm->JACCARD) {
    eval { $find = MRS::Client::Find->new (undef, query => 'some', algorithm => $algorithm) };
    ok (!$@, "Find: correct algorithm $algorithm");
}
{
    local $SIG{__WARN__} = sub { like ($_[0], qr/algorithm/, 'Find: wrong algorithm') };
    $find = MRS::Client::Find->new (undef, query => 'some', algorithm => 'wrong');
    is ($find->{algorithm}, MRS::Algorithm->VECTOR,  'Find: default algorithm');
}

{
    local $SIG{__WARN__} = sub { like ($_[0], qr/offset/, 'Find: wrong offset') };
    $find = MRS::Client::Find->new (undef, query => 'some', offset => 'wrong');
    is ($find->{offset}, 0,  'Find: default offset');
    $find = MRS::Client::Find->new (undef, query => 'some', offset => -1);
    is ($find->{offset}, 0,  'Find: default offset');
}

{
    local $SIG{__WARN__} = sub { like ($_[0], qr/start/, 'Find: wrong start') };
    $find = MRS::Client::Find->new (undef, query => 'some', start => 'wrong');
    is ($find->{start}, 1,  'Find: default start');
    $find = MRS::Client::Find->new (undef, query => 'some', start => -1);
    is ($find->{start}, -1,  'Find: ignored start');
}

{
    local $SIG{__WARN__} = sub { like ($_[0], qr/max_entries/, 'Find: wrong max_entries') };
    $find = MRS::Client::Find->new (undef, query => 'some', max_entries => 'wrong');
    is ($find->max_entries, 0,  'Find: default max_entries');
    $find = MRS::Client::Find->new (undef, query => 'some', max_entries => -1);
    is ($find->max_entries, 0,  'Find: default max_entries');
}

{
    local $SIG{__WARN__} = sub { like ($_[0], qr/both/i, 'Find: both And and OR') };
    $find = MRS::Client::Find->new (undef, 'and' => 'some', 'or' => 'any');
}

$find = MRS::Client::Find->new (undef, 'and' => ['rds', 'os:human']);
is (@{ $find->terms }, 1,               'Find: bools in terms');
is ($find->terms->[0], 'rds',           'Find: bools in terms 2');
is ($find->query, 'os:human',           'Find: bools in terms 3');
ok ($find->all_terms_required,          'Find: bools in terms 4');
$find = MRS::Client::Find->new (undef, 'and' => ['os:human']);
is (@{ $find->terms }, 0,               'Find: bools in terms 5');
is ($find->query, 'os:human',           'Find: bools in terms 6');
ok ($find->all_terms_required,          'Find: bools in terms 7');
$find = MRS::Client::Find->new (undef, 'and' => 'os:human');
is (@{ $find->terms }, 0,               'Find: bools in terms 8');
is ($find->query, 'os:human',           'Find: bools in terms 9');
ok ($find->all_terms_required,          'Find: bools in terms 10');
$find = MRS::Client::Find->new (undef, 'and' => ['rds', 'os:human', 'os:rat', 'des']);
is (@{ $find->terms }, 2,               'Find: bools in terms 11');
is ($find->terms->[0], 'rds',           'Find: bools in terms 12');
is ($find->terms->[1], 'des',           'Find: bools in terms 12');
is ($find->query, 'os:human AND os:rat','Find: bools in terms 13');
ok ($find->all_terms_required,          'Find: bools in terms 14');
