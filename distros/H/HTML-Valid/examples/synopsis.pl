#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use FindBin '$Bin';
use HTML::Valid;
my $html = <<EOF;
<ul>
<li>Shape it up
<li>Get straight
<li>Go forward
<li>Move ahead
<li>Try to detect it
<li>It's not too late
EOF
my $htv = HTML::Valid->new ();
my ($output, $errors) = $htv->run ($html);
print "$output\n";
print "$errors\n";
