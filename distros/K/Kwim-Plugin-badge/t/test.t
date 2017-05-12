use lib 'inc';
use lib '../kwim-pm/lib';
use lib '../pegex-pm/lib';
use lib '../testml-pm/lib';

use TestML;

my $testml = join('', <DATA>);
my $debug = 0;
my $tree = 0;

if (@ARGV) {
    $testml =~ s/^/# /gm;
    $testml =~ s/^# //m for 1..5;
    my $markup = 0;
    for (@ARGV) {
        if (/^(byte|html|pod|markdown)$/) {
            $testml =~ s/^# (Label.*\n)# (.*\*$_)$/$1$2/m;
            $markup = 1;
        }
        elsif (/^diff$/) {
            $testml =~ s/^#(Diff )/$1/m;
        }
        elsif (/^debug$/) {
            $debug = 1;
        }
        elsif (/^tree$/) {
            $tree = 1;
        }
        else {
            s/\.tml$//;
            s/.*test\///;
            $testml =~ s/^# (%Include $_\.tml)$/$1/m;
        }
    }
    $testml =~ s/^# (Label.*\n)# (.*)$/$1$2/gm unless $markup;
}


TestML->new(
    testml => $testml,
    bridge => 'main',
)->run;

use base 'TestML::Bridge';
use TestML::Util;
use Kwim::Grammar;
use Kwim::Byte;
use Kwim::HTML;
use Kwim::Markdown;
use Kwim::Pod;

sub parse {
    my ($self, $kwim, $emitter) = @_;
    $kwim = $kwim->{value};
    $emitter = $emitter->{value};
    my $parser = Pegex::Parser->new(
        grammar => 'Kwim::Grammar'->new,
        receiver => "Kwim::$emitter"->new,
        debug => $debug,
    );
    eval 'use XXX; XXX($parser->grammar->tree)'
      if $tree;
    str $parser->parse($kwim);
}

__DATA__
%TestML 0.1.0

#Diff = 1
#Plan = 4

Label = 'Kwim to ByteCode - $BlockLabel'
*kwim.parse('Byte') == *byte
Label = 'Kwim to HTML - $BlockLabel'
*kwim.parse('HTML') == *html
Label = 'Kwim to Markdown - $BlockLabel'
*kwim.parse('Markdown') == *markdown
Label = 'Kwim to Pod - $BlockLabel'
*kwim.parse('Pod') == *pod

%Include func.tml
