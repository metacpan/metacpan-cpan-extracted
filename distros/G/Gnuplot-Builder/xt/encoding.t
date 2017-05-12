use strict;
use warnings;
use utf8;
use Test::More;
use Gnuplot::Builder::Script;
use Gnuplot::Builder::Dataset;
use Gnuplot::Builder::Process;
use Encode qw(encode_utf8);
use lib "xt";
use testlib::XTUtil qw(if_no_file);

sub contains_encoded {
    my ($containing_string, $decoded_substring) = @_;
    return (index($containing_string, encode_utf8($decoded_substring)) != -1);
}

$Gnuplot::Builder::Process::ENCODING = "utf8";

my $tapped = "";
$Gnuplot::Builder::Process::TAP = sub {
    my ($pid, $event, $body) = @_;
    $tapped .= $body if $event eq "write";
};

my $base_script = Gnuplot::Builder::Script->new(
    term => "pngcairo size 500,500"
);

if_no_file "test_enc_plot.png", sub {
    my $file = shift;
    $tapped = "";
    my $script = $base_script->new_child->setq(
        title => '日本語タイトル'
    );
    $script->add("print 'ほげほげ'");
    my $out = $script->plot_with(
        dataset => "sin(x)",
        output => $file
    );
    ok contains_encoded($tapped, '日本語タイトル'), "encoded title found in tapped";
    ok contains_encoded($tapped, 'ほげほげ'), "encoded print text found in tapped";
    ok contains_encoded($out, 'ほげほげ'), "encoded print text found in out";
};

if_no_file "test_enc_multiplot.png", sub {
    my $file = shift;
    $tapped = "";
    my $script = $base_script->new_child;
    my $dataset = Gnuplot::Builder::Dataset->new("cos(x)")->setq(title => 'コサイン・エックス');
    $script->multiplot_with(
        option => "layout 2,1",
        output => $file,
        do => sub {
            my ($writer) = @_;
            $writer->('plot sin(x) title "サイン・エックス"');
            $writer->("\n");
            Gnuplot::Builder::Script->new->plot($dataset);
        }
    );
    ok contains_encoded($tapped, 'サイン・エックス'), "encoded sin(x) title found in tapped";
    ok contains_encoded($tapped, 'コサイン・エックス'), "encoded cos(x) tilte found in tapped";
};

if_no_file 'test_enc_run.png', sub {
    my $file = shift;
    $tapped = "";
    my $script = $base_script->new_child;
    my $out = $script->run(sub {
        my $writer = shift;
        $writer->("print 'ほげほげ'\n");
        Gnuplot::Builder::Script->new->plot_with(
            output => $file,
            dataset => 'sin(x) title "サイン・エックス"'
        );
    });
    ok contains_encoded($tapped, 'ほげほげ'), 'encoded hoge found in tapped';
    ok contains_encoded($tapped, 'サイン・エックス'), 'encoded sin(x) found in tapped';
    ok contains_encoded($tapped, 'ほげほげ'), 'encoded hoge found in out';
};

done_testing;
