use lib 't', 'lib';
use strict;
use warnings;
use Test::More tests => 2;
use Kwiki;

BEGIN {
    use_ok 'Kwiki::SOAP';
}

SKIP: {
skip "templates make tests hard", 1;
my $content =<<"EOF";
=== Hello

{soap http://www.xmethods.net/sd/2001/TemperatureService.wsdl getTemp 98112}

EOF

    my $kwiki = Kwiki->new;
    my $hub = $kwiki->load_hub({plugin_classes => ['Kwiki::SOAP']});
    my $registry = $hub->load_class('registry');
    $registry->update();
    $hub->load_registry();
    my $formatter = $hub->load_class('formatter');

    my $output = $formatter->text_to_html($content);
    diag($output);
    like($output, qr/VAR/, 'content looks okay');
}



