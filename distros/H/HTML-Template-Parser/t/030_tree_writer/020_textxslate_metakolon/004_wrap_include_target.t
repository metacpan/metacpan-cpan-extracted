use strict;
use warnings;
use Test::More tests => 2;

use HTML::Template::Parser;
use HTML::Template::Parser::TreeWriter::TextXslate::Metakolon;

write_test('<tmpl_include foo.tmpl>', q{[% include 'foo.tmpl' %]});

{
    local %ENV;
    $ENV{WRAP_TEMPLATE_TARGET} = '_convert_to_metakoron';
    write_test('<tmpl_include foo.tmpl>', q{[% include _convert_to_metakoron('foo.tmpl') %]}, '_convert_to_metakoron');
}

sub write_test {
    my($template_string, $expected, $wrap_template_target) = @_;

    my $parser = HTML::Template::Parser->new;
    my $writer = HTML::Template::Parser::TreeWriter::TextXslate::Metakolon->new;
    my $tree = $parser->parse($template_string);
    $writer->wrap_template_target($wrap_template_target) if($wrap_template_target);
    my $output = $writer->write($tree);

    is($output, $expected, "template_string is [$template_string]");
}

