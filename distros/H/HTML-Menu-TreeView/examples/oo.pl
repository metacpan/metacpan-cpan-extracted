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
             text    => 'Html::Menu::TreeView',
             subtree => [
                         {
                          text    => 'Examples',
                          subtree => [
                                      {
                                       text => 'FO Syntax',
                                       href => './fo.pl',
                                      },
                                     ],
                         },
                        ],
            },
            {
             ondblclick => "alert('ondblclick');",
             text       => 'ondblclick',
             title      => 'ondblclick',
            },
           );
my $TreeView = new HTML::Menu::TreeView();
$TreeView->Style('simple');
$TreeView->clasic(1);
my $q = new CGI;
print($q->header,
      $q->start_html(
                     -title  => 'OO',
                     -script => $TreeView->jscript() . $TreeView->preload(),
                     -style  => {-code => $TreeView->css()}
                    ),
      $TreeView->Tree(\@tree),
      $q->end_html
     );
