#!/usr/bin/perl -w
use strict;
use lib qw(lib);
use HTML::Menu::TreeView qw(:all );
use CGI qw(-compile :all  -private_tempfiles);
use vars qw(@tree $size $style $htpath @lines $src $newsize $zoom $dump);

$style = param('style') ? param('style') : 'Crystal';
$style = $1 if $style =~ /(simple)/;
$size = param('size') ? param('size') : $style =~ /(simple)/ ? 16 : 32;
$size = $1 if $size =~ /(\d+)/;
$htpath = documentRoot();

size($size);
clasic(1) if ($style eq 'simple');
Style($style);

my @t = (
         {
          text    => 'Treeview.pm',
          href    => '/html-menu-treeview.html',
          target  => 'rightFrame',
          subtree => [openTree()],
         },
        );
$dump = './tree.pl';
loadTree($dump);
*tree = \@{$HTML::Menu::TreeView::TreeView[0]};
push @t, @tree;

$src     = $size == 16 ? 'plus.png' : 'minus.png';
$newsize = $size == 16 ? 32         : 16;
$zoom =
  $style eq 'Crystal'
  ? qq(<img src="/$src" style="cursor:pointer;" alt="zoom" align="middle" border="0" onclick="location.href='./Treenavi.pl?style=$style&amp;size=$newsize';"/>)
  : '';

print header()
  . start_html(
               -title  => 'HTML::Menu::TreeView',
               -script => jscript() . preload(),
               -style  => {-code => css()}
              ),
  Tree(\@t)
  . q(<form action="./Treenavi.pl"><table align="center" border="0" class="formLayout" cellpadding="2"  cellspacing="2" summary="mainLayout"><tr><td><select class="option" id="chooseStyle" onchange="location.href = './Treenavi.pl?style='+this.form.chooseStyle.options[this.form.chooseStyle.options.selectedIndex].value;">);

opendir(DIR, "$htpath/style/") or die ": $!";
@lines = grep { /^(\w+)$/ } readdir(DIR);
closedir(DIR);

for (@lines) {
    print $style eq $1
      ? qq(<option value="$1" selected="selected">$1</option>)
      : qq(<option value="$1">$1</option>)
      if /^(\w+)$/;
}

print qq(</select></td><td valign="middle">$zoom</td></tr></table></form><br/>
<div align="center"><a href="http://validator.w3.org/check?uri=referer" target="_parent"><img src="http://www.w3.org/Icons/valid-xhtml10" alt="Valid XHTML 1.0 Transitional" height="31" width="88" border="0"/></a><br/><a href="http://jigsaw.w3.org/css-validator/validator?uri=referer" target="_parent"><img style="border:0;width:88px;height:31px" border="0" src="http://jigsaw.w3.org/css-validator/images/vcss"  alt="Valid CSS!" /></a></div>),
  end_html;

sub openTree {
    my @TREEVIEW;

    system(
        "pod2html --noindex --title=Treeview.pm --infile=lib/HTML/Menu/TreeView.pm  --outfile=$htpath/html-menu-treeview.html"
    );
    use Fcntl qw(:flock);
    use Symbol;
    my $fh   = gensym;
    my $file = "$htpath/html-menu-treeview.html";
    open $fh, "$file" or die "$!: $file";
    seek $fh, 0, 0;
    my @lines = <$fh>;
    close $fh;

    for (@lines) {
        if ($_ =~ /<h\d id="([^"]+)">(.+)<\/h\d>/) {
            push @TREEVIEW,
              {
                text   => $2,
                href   => "/html-menu-treeview.html#$1",
                target => 'rightFrame',
              };
        }
    }
    return @TREEVIEW;
}
