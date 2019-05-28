#!/usr/bin/perl -w
use lib qw(lib);
use HTML::Menu::TreeView;
use CGI;
use strict;
my @tree = (
    {
     onclick => "alert('onclick');",
     text    => 'onclick',
    },
    {
     text  => 'Html::Menu::TreeView',
     href  => "./open.pl?open=1",
     empty => 1,                        # this is the important line
    }
);
my $TreeView = new HTML::Menu::TreeView();
my $q        = new CGI;
if ($q->param('open')) {
    $tree[1]{subtree} = [
                         {
                          text    => 'Examples',
                          subtree => [
                                      {
                                       text => 'FO Syntax',
                                       href => './fo.pl',
                                      },
                                     ],
                         },
                        ];
    undef $tree[1]{empty};

}
print($q->header
        . $q->start_html(
                         -title  => 'OO',
                         -script => $TreeView->jscript() . $TreeView->preload(),
                         -style  => {-code => $TreeView->css()}
                        )
        . $TreeView->Tree(\@tree)
        . $q->end_html
     );
