#!perl
# based on http://www.geminium.com/chiba_blog/2009/07/12/212/

use strict;
use warnings;
use utf8;
use FindBin qw($Bin);

binmode STDOUT, ':utf8';

use Benchmark qw/cmpthese/;
use Template;
use HTML::FillInForm;
use HTML::FillInForm::Lite;

print "Benchmark: HTML::FillInForm vs. HTML::FillInForm::Lite\n";

chdir $Bin;

my $t = Template->new({
    ENCODING => 'UTF-8',
    FILTERS => {
        fillinform     => [\&fillinform, 1],
        fillinformlite => [\&fillinformlite, 1],
    },
});
my $f  = HTML::FillInForm->new;
my $fl = HTML::FillInForm::Lite->new;
my $filldata = {mail => 'foobar at example.com', name => '日本語の名前', tel => '123-456-789'};

cmpthese(-1, {
    fillinall => sub {
        $t->process("html/test.html", {
            hoge => 'aha'
        }, \my $output) or die $t->error;

        $f->fill(\$output, $filldata);
    },
    fillinpart => sub {
        $t->process("html/test_part.html", {
            hoge => 'aha',
            filldata => $filldata,
        }, \my $output) or die $t->error;
    },
    fillinall_lite => sub {
        $t->process("html/test.html", {
            hoge => 'aha'
        }, \my $output) or die $t->error;

        $fl->fill(\$output, $filldata);
    },
    fillinpart_lite => sub {
        $t->process("html/test_part_lite.html", {
            hoge => 'aha',
            filldata => $filldata,
        }, \my $output) or die $t->error;
    },
});
sub fillinform {
    my ($context, $data, @options) = @_;

    return sub {
        my $html = shift;

        $f->fill(\$html, $data, @options);
    };
}
sub fillinformlite {
    my ($context, $data, @options) = @_;

    return sub {
        my $html = shift;

        $fl->fill(\$html, $data, @options);
    };
}
