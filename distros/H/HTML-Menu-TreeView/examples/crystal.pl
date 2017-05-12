#!/usr/bin/perl -w
use lib qw(lib);
use HTML::Menu::TreeView qw(setClasic Tree css jscript Style documentRoot size clasic preload);
use CGI qw(-compile :all  -private_tempfiles);
use strict;
my $htpath = documentRoot();
setClasic() if param('setClasic');

my $size = defined param('size') ? param('size') : 16;
$size = ($size == 22 or $size == 32 or $size == 48 or $size == 64 or $size == 128) ? $size : 16;
my @tree;
opendir(DIR, "$htpath/style/Crystal/$size/mimetypes") or die ":$htpath/style/Crystal/$size/mimetypes $/ $! $/";
my @lines = readdir(DIR);
closedir(DIR);
open(IN, "$htpath/style/Crystal/$size/html-menu-treeview/Crystal.css") or die ": $!";

while (my $line = <IN>) {
    if ($line =~ /td\.(folder.+)Closed/) {
        my $classname = $1;
        my $img       = shift @lines;
        $img = shift @lines while ($img =~ /^\..*/);
        push @tree,
          {
            text        => $classname,
            folderclass => $classname,
            subtree     => [
                        {
                         text  => $img,
                         image => $img
                        },
            ],
          };
        next;
    }
}
close(IN);
for (my $i = 0; $i < $#lines; ++$i) {
    my $img = shift @lines;
    unless ($img =~ /^\..*$/) {
        push @tree,
          {
            text  => $img,
            image => $img,
          };
    }
}
documentRoot($htpath);
Style('Crystal');
size($size);
clasic(1) if (defined param('clasic'));
my $zoom = div(
               {style => "font-size:$size" . "px;"},
                a(
                  {
                   -href  => "./crystal.pl?style=Crystal&size=$size&setClasic=1",
                   -class => "treeviewLink$size"
                  },
                  'setClasic'
                 )
                 . '&#160;|&#160;'
                 .
               a(
                  {
                   -href  => './crystal.pl?style=Crystal&size=16',
                   -class => "treeviewLink$size"
                  },
                  '16'
                 )
                 . '&#160;|&#160;'
                 . a(
                     {
                      -href  => './crystal.pl?style=Crystal&size=22',
                      -class => "treeviewLink$size"
                     },
                     '22'
                 )
                 . '&#160;|&#160;'
                 . a(
                     {
                      -href  => './crystal.pl?style=Crystal&size=32',
                      -class => "treeviewLink$size"
                     },
                     '32'
                 )
                 . '&#160;|&#160;'
                 . a(
                     {
                      -href  => './crystal.pl?style=Crystal&size=48',
                      -class => "treeviewLink$size"
                     },
                     '48'
                 )
                 . '&#160;|&#160;'
                 . a(
                     {
                      -href  => './crystal.pl?style=Crystal&size=64',
                      -class => "treeviewLink$size"
                     },
                     '64'
                 )
                 . '&#160;|&#160;'
                 . a(
                     {
                      -href  => './crystal.pl?style=Crystal&size=128',
                      -class => "treeviewLink$size"
                     },
                     '128'
                 )
);
print(
      header(),
      start_html(
                 -title  => 'Crystal',
                 -script => jscript() . preload(),
                 -style  => {-code => css()}
      ),
      div({align => 'center'}, $zoom . br() . Tree(\@tree)),
      end_html
);
