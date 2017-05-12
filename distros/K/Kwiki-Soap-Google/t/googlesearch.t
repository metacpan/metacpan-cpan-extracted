use lib 't', 'lib';
use strict;
use warnings;
use Test::More tests => 2;
use Kwiki;

my $key = '';

BEGIN {
    use_ok 'Kwiki::SOAP::Google';
}

SKIP: {
    eval {require Kwiki::Test};
    skip "Kwiki::Test needed for tests", 1 if $@;
    skip "google key needed for test", 1 unless $key;

    my $kwiki = Kwiki::Test->new->init(['Kwiki::SOAP::Google']);
    $kwiki->hub->googlesoap->key($key);

    my $content =<<"EOF";
=== Hello

{googlesoap chris dent}

EOF

    my $output = $kwiki->hub->formatter->text_to_html($content);
    like($output, qr/Glacial Erratics/, 'content looks okay');
    $kwiki->cleanup
}

