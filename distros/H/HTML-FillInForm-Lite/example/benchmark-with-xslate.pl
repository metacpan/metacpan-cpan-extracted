#!perl
# based on http://www.geminium.com/chiba_blog/2009/07/12/212/

use strict;
use warnings;
use utf8;
use FindBin qw($Bin);

binmode STDOUT, ':utf8';

use Benchmark qw/cmpthese/;
use Text::Xslate;
use Text::Xslate qw(html_builder);
use HTML::FillInForm;
use HTML::FillInForm::Lite;

print "Benchmark: HTML::FillInForm vs. HTML::FillInForm::Lite\n";

chdir $Bin;

my $t = Text::Xslate->new(
    syntax    => 'TTerse',
    cache_dir => '.xslate_cache',
    function  => {
        fillinform     => html_builder(\&fillinform),
        fillinformlite => html_builder(\&fillinformlite),
    },
);

my $f  = HTML::FillInForm->new;
my $fl = HTML::FillInForm::Lite->new;
my $filldata = {mail => 'foobar at example.com', name => '日本語の名前', tel => '123-456-789'};

cmpthese(-1, {
    fillinall => sub {
        my $output = $t->render("html/test.html", {
            hoge => 'aha'
        });

        $f->fill(\$output, $filldata);
    },
    fillinpart => sub {
        my $output = $t->render("html/test_part.html", {
            hoge => 'aha',
            filldata => $filldata,
        });
    },
    fillinall_lite => sub {
        my $output = $t->render("html/test.html", {
            hoge => 'aha'
        });

        $fl->fill(\$output, $filldata);
    },
    fillinpart_lite => sub {
        my $output = $t->render("html/test_part_lite.html", {
            hoge => 'aha',
            filldata => $filldata,
        });
    },
});
sub fillinform {
    my ($data, @options) = @_;

    return sub {
        my $html = shift;

        $f->fill(\$html, $data, @options);
    };
}
sub fillinformlite {
    my ($data, @options) = @_;

    return sub {
        my $html = shift;

        $fl->fill(\$html, $data, @options);
    };
}
