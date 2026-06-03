#!/usr/bin/env perl
# Regenerate README.md from lib/EV/Gearman.pm POD.
#
# Run from the dist root:
#   perl tools/gen-readme.pl
#
# Pulled in automatically by `make dist` via the postamble in
# Makefile.PL, but can also be run by hand after editing POD.
use strict;
use warnings;
use Pod::Markdown;

my $src = 'lib/EV/Gearman.pm';
my $dst = 'README.md';

my $parser = Pod::Markdown->new(
    perldoc_url_prefix       => 'https://metacpan.org/pod/',
    perldoc_fragment_format  => 'metacpan',
    markdown_fragment_format => 'metacpan',
    local_module_url_prefix  => 'https://metacpan.org/pod/',
);

# parse_file leaves $out as a character string; Pod::Simple reads the
# =encoding utf8 directive and decodes the source itself.
$parser->output_string(\my $out);
$parser->parse_file($src);

my $banner = "<!-- DO NOT EDIT \x{2014} regenerated from $src POD by tools/gen-readme.pl -->\n\n";

open my $fh, '>:encoding(UTF-8)', $dst or die "$dst: $!";
print $fh $banner, $out;
close $fh;

print "wrote $dst (", -s $dst, " bytes)\n";
