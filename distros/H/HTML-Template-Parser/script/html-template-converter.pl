#!/usr/bin/perl

use strict;
use warnings;

use FindBin::libs;
use UNIVERSAL::require;

use HTML::Template::Parser;

my $type = 'metakolon';

my %target_format = (
    'metakolon' => {
        plugin => 'TextXslate::Metakolon',
    },
);
my $writer_plugin = 'HTML::Template::Parser::TreeWriter::' . $target_format{$type}->{plugin};

eval {
    $writer_plugin->require;
};
die "load $writer_plugin faild. [$@]\n" if $@;

my $parser = HTML::Template::Parser->new;
my $writer = $writer_plugin->new;

my $template_text;
{ local $/; $template_text = <>; }
my $tree = $parser->parse($template_text);
my $new_template_text = $writer->write($tree);
print $new_template_text;
