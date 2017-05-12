#!/usr/bin/perl -W
use strict;
use CGI qw(-compile :all :cgi-lib -private_tempfiles);
use CGI::Carp qw(fatalsToBrowser);
use lib qw(lib);
use HTML::Menu::TreeView qw(:all);
use vars qw(@tree $m_sContent %tempNode $tN $m_nRid);
my $action   = param('action') ? param('action') : "editable";
my $dump     = "./tree.pl";
my $down     = 0;
my $m_sStyle = "Crystal";
my $size     = param('size') ? param('size') : 32;
$size = ($size == 22 or $size == 16 or $size == 48) ? $size : 32;
size($size);
clasic(1) if (defined param('clasic'));
my $jspart = qq|
//<<drag&drop
var dragobjekt = null;
var dragX = 0;
var dragY = 0;
var posX = 0;
var posY = 0;
var dropenabled = false;
document.onmousemove = drag;
document.onmouseup = drop;
dropText = null;
dropzone = null;
dropid = null;
m_bOver = true;
m_bNoDrop = false;
offsetLeft = 0;
size = $size;
function startdrag(element){
  dropid = element;
  dragobjekt = document.getElementById(element);
  dragX = posX - dragobjekt.offsetLeft;
  dragY = posY - dragobjekt.offsetTop;
}
function drop(){
  if(dropenabled && dragobjekt && !m_bNoDrop){
    m_bOver = true;
    dragobjekt.style.cursor = "";
    dragobjekt.style.position ="";
  }
  if(!m_bNoDrop)
    dragobjekt = null;
}
function drag(EVENT) {
  posX = document.all ? window.event.clientX : EVENT.pageX;
  posY = document.all ? window.event.clientY : EVENT.pageY;
    
  if(dragobjekt && !m_bNoDrop){
    dragobjekt.style.cursor ="pointer";
    dragobjekt.style.left = (posX -dragX )+"px";
    dragobjekt.style.top = (posY - dragY)+"px";
  }
}
//drag&drop>>

function prepareMove(id){
  dragobjekt = document.getElementById(id);
  dragX = posX - dragobjekt.offsetLeft;
  dragY = posY - dragobjekt.offsetTop;
  dropenabled = true;
  m_bOver = false;
  var o = getElementPosition(id);
  move(id,o.x+25,o.y+25);
  startdrag(id);
}
function enableDropZone(id){
      if(!dragobjekt) return;
      dropzone = id;
      if(dragobjekt.id != dropzone) document.getElementById(id).className = "dropzone"+size;
}
function disableDropZone(id){
	document.getElementById(id).className = "treeviewLink"+size;
}
function confirmMove(){
  m_bNoDrop = true;
  if(dropzone && dragobjekt.id != dropzone){
    moveHere("Move "+dragobjekt.innerHTML+" to "+document.getElementById(dropzone).innerHTML+" ?" ,function(){
    location.href = "edit.pl?action=MoveTreeViewEntry&dump=./tree.pl&from="+document.getElementById(dropid).id+"&to="+document.getElementById(dropzone).id+"#"+document.getElementById(dropzone).id;
    });
  }
  m_bOver = true;
}
function moveHere(txt,sub,arg,arg2,arg3)
{
  visible('moveHere');
  window.document.title = txt;
  setText('moveHere','<div id="moveButton" class="moveButton" style="padding:0.4em;">Move Here</div><div id="moveCancelButton" class="moveButton" style="padding:0.4em;">Cancel</div>');
  var node = document.getElementById("moveButton");
  document.getElementById('moveHere').style.position ="absolute";
  document.getElementById('moveHere').style.left = (posX -dragX )+"px";
  document.getElementById('moveHere').style.top  = (posY - dragY)+"px";  
 
  node.addEventListener ('click',function (evt){
    stopDrop();
    evt.stopPropagation();
    sub(arg,arg2,arg3);
  });
  var node2 = document.getElementById("moveCancelButton");
  node2.addEventListener ('click',function (evt){
    stopDrop();
    evt.stopPropagation();
  });
}
function stopDrop(){
  hide('moveHere');
  dragobjekt.style.position ="";
  dropenabled = false;
  dragobjekt.className = "treeviewLink"+size;
  dragobjekt = null;
  m_bNoDrop = false;
}
function getElementPosition(id){
  var node = document.getElementById(id);
  var offsetLeft = 0;
  var offsetTop  = 0;
  while (node){
    offsetLeft += node.offsetLeft;
    offsetTop += node.offsetTop;
    node = node.offsetParent;
  }
  var position = new Object();
  position.x = offsetLeft;
  position.y = offsetTop;
  return position;
}
function move(id,x,y){
  Element = document.getElementById(id);
  Element.style.position = "absolute";
  Element.style.left = x + "px";
  Element.style.top  = y + "px";
}
function setText(id,string){
var element = document.getElementById(id);
if(element)
element.innerHTML = string;
else
window.status = id+string;
}
function getText(id){
var element = document.getElementById(id);
if(element)
return element.innerHTML;
}
function hide(id){
if(document.getElementById(id))
document.getElementById(id).style.display = "none";
}
function visible(id){
      if(document.getElementById(id))
      document.getElementById(id).style.display = "";
}
|;

if (-e $dump) {
    loadTree($dump);
    *tree = \@{$HTML::Menu::TreeView::TreeView[0]};
}
if ($#tree == -1) {
    @tree = (
             {
              'text'    => 'Related Sites',
              'subtree' => [
                            {
                             'target'  => '_parent',
                             'text'    => 'Lindnerei.de',
                             'href'    => 'http://lindnerei.de/',
                             'subtree' => [],
                             'id'      => 'a2',
                             'rid'     => 2
                            },
                            {
                             'target'  => '_parent',
                             'href'    => 'http://search.cpan.org/dist/HTML-Menu-TreeView/',
                             'text'    => 'cpan.org',
                             'subtree' => [],
                             'id'      => 'a3',
                             'rid'     => 3
                            },
                           ],
              'id'  => 'a1',
              'rid' => 1
             },
             {
              'text'    => 'Examples',
              'subtree' => [
                            {
                             'target'  => 'rightFrame',
                             'text'    => 'OO Syntax',
                             'href'    => 'oo.pl',
                             'subtree' => [
                                           {
                                            'target'  => 'rightFrame',
                                            'text'    => 'Source',
                                            'href'    => 'ooSource.pl',
                                            'subtree' => [],
                                            'rid'     => 7,
                                            'id'      => 'a7'
                                           }
                                          ],
                             'rid' => 6,
                             'id'  => 'a6'
                            },
                            {
                             'target'  => 'rightFrame',
                             'href'    => 'fo.pl',
                             'text'    => 'FO Syntax',
                             'subtree' => [
                                           {
                                            'target'  => 'rightFrame',
                                            'text'    => 'Source',
                                            'href'    => 'foSource.pl',
                                            'subtree' => [],
                                            'id'      => 'a9',
                                            'rid'     => 9
                                           }
                                          ],
                             'id'  => 'a8',
                             'rid' => 8
                            },
                            {
                             'target'  => 'rightFrame',
                             'href'    => 'crystal.pl',
                             'text'    => 'Crystal',
                             'subtree' => [
                                           {
                                            'target'  => 'rightFrame',
                                            'href'    => 'crystalSource.pl',
                                            'text'    => 'Source',
                                            'subtree' => [],
                                            'id'      => 'a11',
                                            'rid'     => 11
                                           }
                                          ],
                             'id'  => 'a10',
                             'rid' => 10
                            },
                            {
                             'target'  => 'rightFrame',
                             'text'    => 'Sort the Treeview',
                             'href'    => 'folderFirst.pl',
                             'subtree' => [
                                           {
                                            'target'  => 'rightFrame',
                                            'href'    => 'folderSource.pl',
                                            'text'    => 'Source',
                                            'subtree' => [],
                                            'id'      => 'a13',
                                            'rid'     => 13
                                           }
                                          ],
                             'id'  => 'a12',
                             'rid' => 12
                            },
                            {
                             'target'  => 'rightFrame',
                             'href'    => 'edit.pl',
                             'text'    => 'Edit',
                             'subtree' => [
                                           {
                                            'target'  => 'rightFrame',
                                            'href'    => 'editSource.pl',
                                            'text'    => 'Source',
                                            'subtree' => [],
                                            'id'      => 'a15',
                                            'rid'     => 15
                                           }
                                          ],
                             'id'  => 'a14',
                             'rid' => 14
                            },
                            {
                             'target'  => 'rightFrame',
                             'href'    => 'select.pl',
                             'text'    => 'Select',
                             'subtree' => [
                                           {
                                            'target'  => 'rightFrame',
                                            'text'    => 'Source',
                                            'href'    => 'selectSource.pl',
                                            'subtree' => [],
                                            'rid'     => 17,
                                            'id'      => 'a17'
                                           }
                                          ],
                             'rid' => 16,
                             'id'  => 'a16'
                            },
                            {
                             'target'  => 'rightFrame',
                             'href'    => 'open.pl',
                             'text'    => 'Closed Folder ',
                             'subtree' => [
                                           {
                                            'target'  => 'rightFrame',
                                            'href'    => 'openSource.pl',
                                            'text'    => 'Source',
                                            'subtree' => [],
                                            'id'      => 'a19',
                                            'rid'     => 'a19'
                                           }
                                          ],
                             'id'  => 'a18',
                             'rid' => 'a18'
                            },
                            {
                             'target'  => 'rightFrame',
                             'text'    => 'Columns',
                             'href'    => 'columns.pl',
                             'subtree' => [
                                           {
                                            'target'  => 'rightFrame',
                                            'href'    => 'columnsSource.pl',
                                            'text'    => 'Source',
                                            'subtree' => [],
                                            'id'      => 'a21',
                                            'rid'     => 21
                                           }
                                          ],
                             'id'  => 'a20',
                             'rid' => 20
                            }
                           ],
              'id'  => 'a5',
              'rid' => 5
             },
             {
              'text'    => 'Kontakt',
              'href'    => 'mailto:dirk.lze@gmail.com',
              'subtree' => [],
              'id'      => 'a22',
              'rid'     => 22
             }
            );
    saveTree($dump, \@tree);
}
my $zoom = div(
               {style => "font-size:$size" . "px;text-align:center;"},
               a(
                  {
                   -href  => './edit.pl?style=Crystal&size=16',
                   -class => "treeviewLink$size"
                  },
                  '16'
                )
                 . '&#160;|&#160;'
                 . a(
                     {
                      -href  => './edit.pl?style=Crystal&size=22',
                      -class => "treeviewLink$size"
                     },
                     '22'
                    )
                 . '&#160;|&#160;'
                 . a(
                     {
                      -href  => './edit.pl?style=Crystal&size=32',
                      -class => "treeviewLink$size"
                     },
                     '32'
                    )
                 . '&#160;|&#160;'
                 . a(
                     {
                      -href  => './edit.pl?style=Crystal&size=48',
                      -class => "treeviewLink$size"
                     },
                     '48'
                    )
              );
print(
    header(),
    start_html(
        -title  => 'Edit',
        -script => jscript() . preload() . $jspart,
        -style  => {
            -code => css() . qq|
               .moveHereContent{
		  background-color:rgba(214, 210, 208,0.9);
		  -webkit-box-shadow:0px 0px 1px rgba(0,0,0,0.4);/*black */
		  -moz-box-shadow:0px 0px 1px rgba(0,0,0,0.4);/*black */
		  box-shadow:0px 0px 1px black;
		  z-index:3;
		}
		.moveButton{
		  background-color:rgba(255,255,255,0.1);
		  cursor:pointer;
		}
		.moveButton:hover{
		  background-color:rgba(134, 171, 218,0.2);
		  cursor:pointer;
		}
               |
                  }
              ),
    $zoom
      . br() . '
<div id="moveHere" style="display:none;" class="moveHereContent" width="100px"></div>
<script language="javascript" type="text/javascript">
if (typeof document.body.onselectstart!="undefined") //ie
document.body.onselectstart=function(){return false};
else if (typeof document.body.style.MozUserSelect!="undefined") //gecko
document.body.style.MozUserSelect="none";
else //Opera
document.body.onmousedown=function(){return false}

document.body.style.cursor = "default";
</script>
<table align="center" class="mainborder" cellpadding="0"  cellspacing="0" summary="mainLayout" ><tr><td align="left">'
     );

my $m_nPrid = param('rid');
$m_nPrid =~ s/^a(.*)/$1/;

SWITCH: {
    if ($action eq 'newEntry') {
        &newEntry();
        last SWITCH;
    }
    if ($action eq 'saveTreeviewEntry') {
        &saveTreeviewEntry();
        last SWITCH;
    }
    if ($action eq 'addTreeviewEntry') {
        &addTreeviewEntry();
        last SWITCH;
    }
    if ($action eq 'editable') {
        &updateTree(\@tree);
        TrOver(1);
        print Tree(\@tree);
        last SWITCH;
    }
    if ($action eq 'editTreeviewEntry') {
        &editTreeviewEntry();
        last SWITCH;
    }
    if ($action eq 'deleteTreeviewEntry') {
        deleteTreeviewEntry();
        last SWITCH;
    }
    if ($action eq 'upEntry') {
        &upEntry();
        last SWITCH;
    }
    if ($action eq 'downEntry') {
        downEntry();
        last SWITCH;
    }
    if ($action eq 'MoveTreeViewEntry') {
        MoveTreeViewEntry();
        last SWITCH;
    }
    print Tree(\@tree);
}

print "$m_sContent</td></tr></table>", end_html;

sub saveTreeviewEntry {
    &load();
    &saveEntry(\@tree, $m_nPrid);
    &updateTree(\@tree);
    TrOver(1);
    $m_sContent .= br();
    $m_sContent .= table(
                         {
                          align => 'center',
                          width => '*'
                         },
                         Tr(td(Tree(\@tree)))
                        );
    TrOver(0);
}

sub addTreeviewEntry {
    &load();
    &addEntry(\@tree, $m_nPrid);
    &updateTree(\@tree);
    TrOver(1);
    $m_sContent .= br();
    $m_sContent .= table(
                         {
                          align => 'center',
                          width => '*'
                         },
                         Tr(td(Tree(\@tree)))
                        );
    TrOver(0);
}

sub editTreeview {
    &load();
    &rid();
    saveTree($dump, \@tree);
    &updateTree(\@tree);
    TrOver(1);
    $m_sContent .= br();
    $m_sContent .= table(
                         {
                          align => 'center',
                          width => '*'
                         },
                         Tr(td(Tree(\@tree)))
                        );
    TrOver(0);
}

sub editTreeviewEntry {
    &load();

    &editEntry(\@tree, $m_nPrid);
}

sub deleteTreeviewEntry {
    &load();
    &deleteEntry(\@tree, $m_nPrid);
    &updateTree(\@tree);
    TrOver(1);
    $m_sContent .= br();
    $m_sContent .= table(
                         {
                          align => 'center',
                          width => '*'
                         },
                         Tr(td(Tree(\@tree)))
                        );
    TrOver(0);
}

sub upEntry {
    &load();
    &sortUp(\@tree, $m_nPrid);
    &updateTree(\@tree);
    TrOver(1);
    $m_sContent .= br();
    $m_sContent .= table(
                         {
                          align => 'center',
                          width => '*'
                         },
                         Tr(td(Tree(\@tree)))
                        );
    TrOver(0);
}

sub MoveTreeViewEntry {
    &load();

    my $f = param('from');
    $f =~ s/^a(.*)/$1/;
    my $t = param('to');
    $t =~ s/^a(.*)/$1/;
    &getEntry(\@tree, $f, $t);
    &rid();
    saveTree($dump, \@tree);
    &updateTree(\@tree);
    TrOver(1);
    $m_sContent .= table(
                         {
                          align => 'center',
                          width => '*'
                         },
                         Tr(td(Tree(\@tree)))
                        );
    TrOver(0);
}

sub moveEntry {
    my $t    = shift;
    my $find = shift;
    for (my $i = 0 ; $i <= @$t ; $i++) {
        next if ref @$t[$i] ne "HASH";
        if (@$t[$i]) {
            if (@$t[$i]->{rid} == $find && defined $tN->{id}) {
                splice @$t, $i, 0, $tN;
                return 1;
            }
            if (defined @{@$t[$i]->{subtree}}) {
                moveEntry(\@{@$t[$i]->{subtree}}, $find);
            }
        }
    }
}

sub getEntry {
    my $t    = shift;
    my $find = shift;
    my $goto = shift;
    for (my $i = 0 ; $i < @$t ; $i++) {
        next if ref @$t[$i] ne "HASH";
        if (@$t[$i]->{rid} == $find) {
            $tN->{$_} = @$t[$i]->{$_} foreach keys %{@$t[$i]};
            splice @$t, $i, 1;
            moveEntry(\@tree, $goto);
        } elsif (defined @{@$t[$i]->{subtree}}) {
            getEntry(\@{@$t[$i]->{subtree}}, $find, $goto);
        }
    }
}

sub downEntry {
    &load();
    $down = 1;
    &sortUp(\@tree, $m_nPrid);
    &updateTree(\@tree);
    TrOver(1);
    $m_sContent .= table(
                         {
                          align => 'center',
                          width => '*'
                         },
                         Tr(td(Tree(\@tree)))
                        );
    TrOver(0);
}

sub newEntry {
    $m_sContent .=
      qq(<b>New Entry</b><form action="$ENV{SCRIPT_NAME}#a$m_nPrid"><br/><table align="center" class="mainborder" cellpadding="2"  cellspacing="2" summary="mainLayolut"><tr><td>Text:</td><td><input type="text" value="" name="text"></td></tr><tr><td>Folder</td><td><input type="checkbox" name="folder" /></td></tr>);
    my $node = help();
    foreach my $key (sort(keys %{$node})) {
        $m_sContent .=
          qq(<tr><td></td><td>$node->{$key}</td></tr><tr><td>$key :</td><td><input type="text" value="" name="$key"/><br/></td></tr>)
          if ($key ne 'class');
    }
    $m_sContent .=
      '<tr><td><input type="hidden" name="action" value="addTreeviewEntry"/><input type="hidden" name="rid" value="a'
      . $m_nPrid
      . '"></td><td><input type="submit"/></td></tr></table></form>';
}

sub addEntry {
    my $t    = shift;
    my $find = shift;
    for (my $i = 0 ; $i < @$t ; $i++) {
        if (@$t[$i]->{rid} == $find) {
            my %params = Vars();
            my $node   = {};
            foreach my $key (sort(keys %params)) {
                $node->{$key} = $params{$key}
                  if (   $params{$key}
                      && $key ne 'action'
                      && $key ne 'folder'
                      && $key ne 'subtree'
                      && $key ne 'class'
                      && $key ne 'dump');
                $node->{$key} = "$ENV{SCRIPT_NAME}?action=$1"
                  if ($key eq 'href' && $params{$key} =~ /^action:\/\/(.*)$/);
            }
            if (param('folder')) {
                $node->{'subtree'} = [
                                      {
                                       text => 'Empty Folder',
                                      }
                                     ];
            }
            splice @$t, $i, 0, $node;
            &rid();
            saveTree($dump, \@tree);
            return;
        } elsif (defined @{@$t[$i]->{subtree}}) {
            &addEntry(\@{@$t[$i]->{subtree}}, $find);
        }
    }
}

sub saveEntry {
    my $t    = shift;
    my $find = shift;
    for (my $i = 0 ; $i < @$t ; $i++) {
        if (@$t[$i]->{rid} == $find) {
            my %params = Vars();
            foreach my $key (sort keys %params) {
                @$t[$i]->{$key} = $params{$key}
                  if (   $params{$key}
                      && $key ne 'action'
                      && $key ne 'folder'
                      && $key ne 'subtree'
                      && $key ne 'class'
                      && $key ne 'dump');
                @$t[$i]->{$key} = "$ENV{SCRIPT_NAME}?action=$1"
                  if ($key eq 'href' && $params{$key} =~ /^action:\/\/(.*)$/);
            }
            saveTree($dump, \@tree);
            return;
        } elsif (defined @{@$t[$i]->{subtree}}) {
            &saveEntry(\@{@$t[$i]->{subtree}}, $find);
        }
    }
}

sub editEntry {
    my $t    = shift;
    my $find = shift;
    my $href = "$ENV{SCRIPT_NAME}?action=editTreeviewEntry";
    for (my $i = 0 ; $i < @$t ; $i++) {
        if (@$t[$i]->{rid} == $find) {
            $m_sContent .= br();
            $m_sContent .= "<b>"
              . @$t[$i]->{text}
              . '</b><form action="'
              . $href
              . "#a$m_nPrid"
              . '><table align=" center " class=" mainborder " cellpadding="0"  cellspacing="0" summary="mainLayolut">';
            language('de') if $ENV{HTTP_ACCEPT_LANGUAGE} =~ /^de.*/;
            my $node = help();
            foreach my $key (sort(keys %{@$t[$i]})) {
                $m_sContent .= "<tr><td></td><td>$node->{$key}</td></tr>"
                  if (defined $node->{$key});
                $m_sContent .=
                  qq(<tr><td>$key </td><td><input type="text" value="@$t[$i]->{$key}" name="$key"></td></tr>)
                  if (   $key ne 'subtree'
                      && $key ne 'rid'
                      && $key ne 'action'
                      && $key ne 'dump'
                      && $key ne 'class'
                      && $key ne 'addition');
            }
            foreach my $key2 (sort(keys %{$node})) {
                unless (defined @$t[$i]->{$key2}) {
                    $m_sContent .=
                      qq(<tr><td></td><td>$node->{$key2}</td></tr><tr><td>$key2 :</td><td><input type="text" value="" name="$key2"/><br/></td></tr>);
                }
            }
            $m_sContent .=
              qq(<tr><td><input type="hidden" name="action" value="saveTreeviewEntry"/><input type="hidden" name="rid" value="@$t[$i]->{id}"/></td><td><input type="submit" value="save"/></td></tr></table></form>);
            saveTree($dump, \@tree);
            return;
        } elsif (defined @{@$t[$i]->{subtree}}) {
            &editEntry(\@{@$t[$i]->{subtree}}, $find);
        }
    }
}

sub sortUp {
    my $t    = shift;
    my $find = shift;
    for (my $i = 0 ; $i <= @$t ; $i++) {
        if (defined @$t[$i]) {
            if (@$t[$i]->{rid} == $find) {
                $i++ if ($down);
                return if (($down && $i == @$t) or (!$down && $i == 0));
                splice @$t, $i - 1, 2, (@$t[$i], @$t[$i - 1]);
                saveTree($dump, \@tree);
            }
            if (defined @{@$t[$i]->{subtree}}) {
                sortUp(\@{@$t[$i]->{subtree}}, $find);
                saveTree($dump, \@tree);
            }
        }
    }
}

sub deleteEntry {
    my $t    = shift;
    my $find = shift;
    for (my $i = 0 ; $i < @$t ; $i++) {
        if (@$t[$i]->{rid} == $find) {
            splice @$t, $i, 1;
            saveTree($dump, \@tree);
        } elsif (defined @{@$t[$i]->{subtree}}) {
            deleteEntry(\@{@$t[$i]->{subtree}}, $find);
        }
    }
}

sub updateTree {
    my $t = shift;
    for (my $i = 0 ; $i < @$t ; $i++) {
        if (defined @$t[$i]) {
            @$t[$i]->{onmouseup}   = "confirmMove()";
            @$t[$i]->{id}          = @$t[$i]->{id};
            @$t[$i]->{name}        = @$t[$i]->{rid};
            @$t[$i]->{onmousedown} = "prepareMove('" . @$t[$i]->{id} . "')";
            @$t[$i]->{onmousemove} = "enableDropZone('" . @$t[$i]->{id} . "')";
            @$t[$i]->{onmouseout}  = "disableDropZone('" . @$t[$i]->{id} . "')";

            @$t[$i]->{addition} =
              qq(<table border="0" cellpadding="0" cellspacing="0" align="right" summary="layout"><tr>
<td><a class="treeviewLink$size" target="_blank" title="@$t[$i]->{text}" href="@$t[$i]->{href}"><img src="/style/$m_sStyle/$size/mimetypes/www.png" border="0" alt=""/></a></td>
<td ><a class="treeviewLink$size" href="$ENV{SCRIPT_NAME}?action=editTreeviewEntry&amp;rid=@$t[$i]->{id}"><img src="/style/$m_sStyle/$size/mimetypes/edit.png" border="0" alt="edit"/></a></td><td><a class="treeviewLink$size" href="$ENV{SCRIPT_NAME}?action=deleteTreeviewEntry&amp;rid=@$t[$i]->{id}"><img src="/style/$m_sStyle/$size/mimetypes/editdelete.png" border="0" alt="delete"/></a></td><td><a class="treeviewLink$size" href="$ENV{SCRIPT_NAME}?action=upEntry&amp;rid=@$t[$i]->{id}#@$t[$i]->{id}"><img src="/style/$m_sStyle/$size/mimetypes/up.png" border="0" alt="up"/></a></td><td><a class="treeviewLink$size" href="$ENV{SCRIPT_NAME}?action=downEntry&amp;rid=@$t[$i]->{id}#@$t[$i]->{id}"><img src="/style/$m_sStyle/$size/mimetypes/down.png" border="0" alt="down"/></a></td><td><a class="treeviewLink$size" href="$ENV{SCRIPT_NAME}?action=newEntry&amp;rid=@$t[$i]->{id}"><img src="/style/$m_sStyle/$size/mimetypes/filenew.png" border="0" alt="new"/></a></td></tr></table>);
            @$t[$i]->{href} = '';
            updateTree(\@{@$t[$i]->{subtree}}) if (defined @{@$t[$i]->{subtree}});
        }
    }
}

sub rid {
    no warnings;
    $m_nRid = 0;
    &getRid(\@tree);

    sub getRid {
        my $t = shift;
        for (my $i = 0 ; $i < @$t ; $i++) {
            $m_nRid++;
            next unless ref @$t[$i] eq "HASH";
            @$t[$i]->{rid} = $m_nRid;
            @$t[$i]->{id}  = "a$m_nRid";
            getRid(\@{@$t[$i]->{subtree}}) if (defined @{@$t[$i]->{subtree}});
        }
    }
}

sub load {
    if (-e $dump) {
        loadTree($dump);
        *tree = \@{$HTML::Menu::TreeView::TreeView[0]};
    }
}
1;
