use strict;
use warnings;
use Devel::StackTrace::AsHTMLExtended;
use Devel::StackTrace::WithLexicals;
use File::Slurp;
my $html;

sub foo {
    my $t = Devel::StackTrace::WithLexicals->new;
    $html = $t->as_html_extended;
    print $html;
}

sub bar { foo("bar", "test", { asdf => 'asdf', nums => [2,2,2,1, 40..120]}) }
bar(2);




