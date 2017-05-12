use strict;
use warnings;
use Test::More tests => 2;

use HTML::Template::Parser;
use HTML::Template::Parser::TreeWriter::TextXslate::Metakolon;

write_test('<tmpl_include foo.tmpl>', q{[% include 'foo.tmpl' %]});

{
    local %ENV;
    $ENV{OLD_TEMPLATE_SUFFIX} = 'tmpl';
    $ENV{NEW_TEMPLATE_SUFFIX} = 'tx';
    write_test('<tmpl_include foo.tmpl>', q{[% include 'foo.tx' %]});
}

sub write_test {
    my($template_string, $expected) = @_;

    my $parser = HTML::Template::Parser->new;
    my $writer = HTML::Template::Parser::TreeWriter::TextXslate::Metakolon->new;
    my $tree = $parser->parse($template_string);
    my $output = $writer->write($tree);

    is($output, $expected, "template_string is [$template_string]");
}

