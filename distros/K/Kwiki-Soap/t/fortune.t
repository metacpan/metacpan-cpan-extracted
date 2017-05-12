use lib 't', 'lib';
use strict;
use warnings;
use Test::More tests => 2;

my $down = 1;

BEGIN {
    use_ok 'Kwiki::SOAP::Fortune';
}

SKIP: {
    eval {require Kwiki::Test};
    skip "Kwiki::Test needed for tests", 1 if $@;
    skip "fortune service unreliable", 1 if $down;

my $content =<<"EOF";
=== Hello

{fortunesoap zippy}

EOF

    my $kwiki = Kwiki::Test->new->init(['Kwiki::SOAP::Fortune']);
    my $formatter = $kwiki->hub->formatter;

    my $output = $formatter->text_to_html($content);
    like($output, qr/fortune/, 'content looks okay');
    $kwiki->cleanup;
}



