use strict;
use warnings;
use Test::More tests => 3;
use Kwiki::Test;

use lib '../lib';

my $kwiki = Kwiki::Test->new->init(['Kwiki::DatedAnnounce']);

my $time = time;
my $duration = 2;
$time = $time + $duration;
my $content =<<"EOF";
=== Hello

.dated
datespec: $time $duration

=== Secret

.dated
EOF

my $expected_output1 =<<"EOF";
<h3>Hello</h3>
<div class='dated'>
<h3>Secret</h3>
</div>
EOF

my $expected_output2 =<<"EOF";
<h3>Hello</h3>

EOF

my $formatter = $kwiki->hub->formatter;
my $output = $formatter->text_to_html($content);
is($output, $expected_output2, 'prior to date no show');

sleep 3;
$output = $formatter->text_to_html($content);
is($output, $expected_output1, 'in date window, show');

sleep 3;
$output = $formatter->text_to_html($content);
is($output, $expected_output2, 'after date window, no show');


$kwiki->cleanup;
