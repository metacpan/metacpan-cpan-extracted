use strict;
use warnings;
use FindBin qw($Bin);
use File::Spec;
use lib '../lib';

use Test::More tests => 5;
BEGIN { use_ok('HTML::Template::Nest') };

my $template_dir = File::Spec->catdir($Bin,'templates');

my $nest = HTML::Template::Nest->new(
    template_dir => $template_dir,
    template_ext => '.html',
    name_label => 'NAME'
);

my $td = 
my $table = {
    NAME => 'table',
    rows => [{
        NAME => 'tr',
        cols => {
            NAME => 'td',
            contents => '1'
        }
    },{
        NAME => 'tr',
        cols => {
            NAME => 'td',
            contents => '2'
        }
    }]
};


my $html = $nest->to_html( $table );
my $x_html = "<table><tr><td>1</td></tr><tr><td>2</td></tr></table>";

ok( $html, "html is returned" );
is( ref($html),'',"returned html is a scalar" );

$html =~ s/\s//gs;

is( $html, $x_html, "returned html is correct" );


$nest->comment_tokens("<!--","-->");
$nest->show_labels(1);
$html = $nest->to_html( $table );

$html =~ s/\s//gs;

$x_html = "<!--BEGINtable--><table><!--BEGINtr--><tr><!--BEGINtd--><td>1</td><!--ENDtd--></tr><!--ENDtr--><!--BEGINtr--><tr><!--BEGINtd--><td>2</td><!--ENDtd--></tr><!--ENDtr--></table><!--ENDtable-->";

is( $html, $x_html, "html correct with show_labels=1" );

