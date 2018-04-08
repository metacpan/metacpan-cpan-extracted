#!perl
use strict;
use CGI qw(-compile :all :cgi-lib -private_tempfiles);
use CGI::Carp qw(fatalsToBrowser);
use lib qw(lib);
use HTML::Menu::TreeView qw(:all);
use vars qw(@m_aTree %tempNode $tN $m_nRid $deleteTempIndex $tempDeleteRef $m_hrTempNode %disallowedKeys);
my $action   = param('action') ? param('action') : "editable";
my $m_sDump     = "./tree.pl";
my $down     = 0;
my $m_sStyle = "Crystal";
my $m_nSize     = param('size') ? param('size') : 32;
prefix('/');
$m_nSize = ($m_nSize == 22 or $m_nSize == 16 or $m_nSize == 48) ? $m_nSize : 32;
%disallowedKeys = (
                   action   => 1,
                   folder   => 1,
                   subtree  => 1,
                   class    => 1,
                   dump     => 1,
                   sid      => 1,
                  );
size($m_nSize);
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
size = $m_nSize;
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

if (-e $m_sDump) {
    loadTree($m_sDump);
    *tree = \@{$HTML::Menu::TreeView::TreeView[0]};
}
if ($#m_aTree == -1) {
    @m_aTree = (
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
    saveTree($m_sDump, \@m_aTree);
}
my $zoom = div(
               {style => "font-size:$m_nSize" . "px;text-align:center;"},
               a(
                  {
                   -href  => './edit.pl?style=Crystal&size=16',
                   -class => "treeviewLink$m_nSize"
                  },
                  '16'
                )
                 . '&#160;|&#160;'
                 . a(
                     {
                      -href  => './edit.pl?style=Crystal&size=22',
                      -class => "treeviewLink$m_nSize"
                     },
                     '22'
                    )
                 . '&#160;|&#160;'
                 . a(
                     {
                      -href  => './edit.pl?style=Crystal&size=32',
                      -class => "treeviewLink$m_nSize"
                     },
                     '32'
                    )
                 . '&#160;|&#160;'
                 . a(
                     {
                      -href  => './edit.pl?style=Crystal&size=48',
                      -class => "treeviewLink$m_nSize"
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
      . br() . qq|
	  <div class="popup" id="popup" style="display:none;" >
<div id="popupContent1" class="popupContent1" align="right" >
<div class="popupCaption" onmousedown="startdrag('popupContent1');">
<div id="popupTitle" class="popupTitle" style="float:left"></div>
  <div id="closeButton" class="closeButton">X</div>
</div>
<div id="popupContent" class="popupContent"></div>
</div>
</div>

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
<table align="center" class="mainborder" cellpadding="0"  cellspacing="0" summary="mainLayout" ><tr><td align="left">|
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
        &updateTree(\@m_aTree);
        TrOver(1);
        print Tree(\@m_aTree);
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
    print Tree(\@m_aTree);
}

print "</td></tr></table>", end_html;


sub newTreeviewEntry {
    &newEntry();
}

sub saveTreeviewEntry {
    &load();
    &saveEntry(\@m_aTree, $m_nPrid);
    _Tree();
}

sub addTreeviewEntry {
    &load();
    &addEntry(\@m_aTree, $m_nPrid);
    _Tree();
}

sub editTreeview {
    &load();
    &rid();
    saveTree($m_sDump, \@m_aTree);
    _Tree();
}

sub _Tree {
    &updateTree(\@m_aTree);
    TrOver(1);

    print
      qq(<div align="center"><form action="$ENV{SCRIPT_NAME}" method="POST" accept-charset="UTF-8"><input type="hidden" name="action" value="deleteTreeviewEntrys"/><table class="marginTop"><tr><td>);

    print table(
                {
                 align => 'center',
                 width => '100%'
                },
                Tr(td(Tree(\@m_aTree)))
               );
    my $delete   = 'delete';
    my $mmark    = 'selected';
    my $markAll  = 'select_all';
    my $umarkAll = 'unselect_all';
    my $rebuild  = 'rebuild';
    print
      qq{</td></tr><tr><td><table align="center" border="0" cellpadding="0"  cellspacing="0" summary="layout" width="100%" ><tr><td style="padding-left:18px;text-align:left;"><a id="markAll" href="javascript:markInput(true);" class="links">$markAll</a><a class="links" id="umarkAll" style="display:none;" href="javascript:markInput(false);">$umarkAll</a></td><td align="right"><select  name="MultipleRebuild"  onchange="if(this.value != '$mmark' )submitForm(this.form,'links','links')"><option  value="$mmark" selected="selected">$mmark</option><option value="delete">$delete</option></select></td></tr></table></td></tr></table></div>};
    TrOver(0);
    undef @m_aTree;
}

sub editTreeviewEntry {
    &load();
    &editEntry(\@m_aTree, $m_nPrid);
}

sub deleteTreeviewEntry {
    &load();
    &deleteEntry(\@m_aTree, $m_nPrid);
    _Tree();
}

sub upEntry {
    &load();
    &sortUp(\@m_aTree, $m_nPrid);
    _Tree();
}

sub MoveTreeViewEntry {
    &load();
    my $from = param('from');
    $from =~ s/^a(\d+)/$1/;
    my $to = param('to');
    $to =~ s/^a(\d+)/$1/;
    &getEntry(\@m_aTree, $from, $to);
    &rid();
    saveTree($m_sDump, \@m_aTree);
    _Tree();
}

sub moveEntry {
    my $t    = shift;
    my $find = shift;
    for (my $i = 0 ; $i <= @$t ; $i++) {
        next if ref @$t[$i] ne 'HASH';
        if (@$t[$i]) {
            if (@$t[$i]->{rid} eq $find) {
                splice @$tempDeleteRef, $deleteTempIndex, 1;
                splice @$t, $i, 0, $m_hrTempNode;
                return 1;
            }
            no warnings;
            if (ref @$t[$i]->{subtree} eq 'ARRAY') {
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
        next if ref @$t[$i] ne 'HASH';
        no warnings;
        if (@$t[$i]->{rid} eq $find) {
            undef $m_hrTempNode;
            foreach (keys %{@$t[$i]}) {
                $m_hrTempNode->{$_} = @$t[$i]->{$_};
            }
            $tempDeleteRef = $t;
            $deleteTempIndex = $i;
            moveEntry(\@m_aTree, $goto);
            
        } elsif (ref @$t[$i]->{subtree} eq 'ARRAY') {
            getEntry(\@{@$t[$i]->{subtree}}, $find, $goto);
        }
    }
}

sub downEntry {
    &load();
    $down = 1;
    &sortUp(\@m_aTree, $m_nPrid);
    &updateTree(\@m_aTree);
    _Tree();
}

sub newEntry {
    my $value = param('title') ? param('title') : '';
    my $push = '';

    if (param('addBookMark')) {
        &load();
        &rid();
        saveTree($m_sDump, \@m_aTree);
        $m_nPrid = $m_nRid;
        $push    = '<input type="hidden" name="addBookMark" value="addBookMark"/>';
    }
    my $new = 'newEntry';
    print qq(
<div align="center" class="marginTop">
<b>$new</b>
<form action="$ENV{SCRIPT_NAME}" onsubmit="submitForm(this,'addTreeviewEntry','addTreeviewEntry');return false;">
<input type="hidden" name="rid" value="a$m_nPrid"/>$push<br/>
<table align="center" class="mainborder" cellpadding="2"  cellspacing="2" summary="mainLayolut">
<tr><td>) . 'txt' . qq(</td><td><input type="text" value="$value" name="text"/></td></tr>
<tr><td>) . 'folder' . qq(</td><td><input type="checkbox" name="folder"/></td></tr>);

    my $node = help();

    foreach my $key (sort keys %{$node}) {
        $value = "";
        $value = param('addBookMark') if ($key eq 'href' && param('addBookMark'));
        $value = param('title') if ($key eq 'title' && param('title'));
        $value = 'a' . $m_nPrid if ($key eq 'id' && param('addBookMark'));
        print
          qq(<tr><td></td><td>$node->{$key}</td></tr><tr><td>$key :</td><td><input type="text" value="$value" name="$key" id="$key"/><br/></td></tr>)
          unless $disallowedKeys{$key};
    }
    print
      qq|<tr><td><input type="hidden" name="action" value="addTreeviewEntry"/></td><td><input type="submit"/></td></tr></table></form></div>|;
}

sub addEntry {
    my $t    = shift;
    my $find = shift;
    $find = $find ? $find : 1;
    for (my $i = 0 ; $i < @$t ; $i++) {
        no warnings;
        if (@$t[$i]->{rid} eq $find) {
            my %params = Vars();
            my $node   = {};
            foreach my $key (sort(keys %params)) {
                $node->{$key} = $params{$key} unless $disallowedKeys{$key};
                $node->{$key} =
                  "$ENV{SCRIPT_NAME}?action=$1"
                  if ($key eq 'href' && $params{$key} =~ /^action:\/\/(.*)$/);
            }
            if (param('folder')) {
                $node->{'subtree'} = [
                                      {
                                       text => 'Empty Folder',
                                      }
                                     ];
            }
            if (param('addBookMark')) {
                unless ($node->{'text'} eq $m_aTree[$#m_aTree]->{'text'}) {
                    push @$t, $node;
                    &rid();
                    saveTree($m_sDump, \@m_aTree);
                    return;
                }
            }
            splice @$t, $i, 0, $node;
            &rid();
            saveTree($m_sDump, \@m_aTree);
            return;
        } elsif (ref @$t[$i]->{subtree} eq 'ARRAY') {
            &addEntry(\@{@$t[$i]->{subtree}}, $find);
        }
    }
}

sub saveEntry {
    my $t    = shift;
    my $find = shift;
    for (my $i = 0 ; $i < @$t ; $i++) {
        no warnings;
        if (@$t[$i]->{rid} eq $find) {
            my %params = Vars();
            foreach my $key (keys %params) {
                @$t[$i]->{$key} = $params{$key} unless $disallowedKeys{$key};
                @$t[$i]->{$key} =
                  "$ENV{SCRIPT_NAME}?action=$1"
                  if ($key eq 'href' && $params{$key} =~ /^action:\/\/(.*)$/);
            }
            &saveTree($m_sDump, \@m_aTree);
            return;
        } elsif (ref @$t[$i]->{subtree} eq 'ARRAY') {
            &saveEntry(\@{@$t[$i]->{subtree}}, $find);
        }
    }
}

sub editEntry {
    my $t    = shift;
    my $find = shift;
    my $href = "submitForm(this ,'editTreeviewEntry','editTreeviewEntry');return false;";
    my $node = help();
    for (my $i = 0 ; $i < @$t ; $i++) {
        no warnings;
        if (@$t[$i]->{rid} eq $find) {
            print '<div align="center" class="marginTop"><b>'
              . @$t[$i]->{text}
              . '</b><form onsubmit="'
              . $href
              . '"><table align=" center " class=" mainborder " cellpadding="0"  cellspacing="0" summary="mainLayolut">';
            print qq(<tr><td>)
              . 'txt'
              . qq(</td><td><input type="text" value="@$t[$i]->{text}" name="text" /></td></tr>);
            print qq(<tr><td>)
              . 'right'
              . qq(</td><td><input type="text" value="@$t[$i]->{right}" name="right" /></td></tr>);
            foreach my $key2 (
                sort {
                    return $a cmp $b if @$t[$i]->{$a} && @$t[$i]->{$b};
                    return -1        if @$t[$i]->{$a};
                    return +1        if @$t[$i]->{$b};
                    return $a cmp $b;
                } keys %{$node}
              ) {
                unless ($disallowedKeys{$key2}) {
                    print
                      qq(<tr><td></td><td>$node->{$key2}</td></tr><tr><td>$key2 :</td><td><input type="text" value="@$t[$i]->{$key2}" name="$key2"/><br/></td></tr>);
                }
            }
            print
              qq(<tr><td><input type="hidden" name="action" value="saveTreeviewEntry"/><input type="hidden" name="rid" value="@$t[$i]->{rid}"/></td><td><input type="submit" value="save"/></td></tr></table></form></div>);
            saveTree($m_sDump, \@m_aTree);
            return;
        } elsif (ref @$t[$i]->{subtree} eq 'ARRAY') {
            &editEntry(\@{@$t[$i]->{subtree}}, $find);
        }
    }
}

sub sortUp {
    my $t    = shift;
    my $find = shift;
    for (my $i = 0 ; $i <= @$t ; $i++) {
        no warnings;
        if (defined @$t[$i]) {
            if (@$t[$i]->{rid} eq $find) {
                $i++ if ($down);
                return if (($down && $i eq @$t) or (!$down && $i eq 0));
                splice @$t, $i - 1, 2, (@$t[$i], @$t[$i - 1]);
                saveTree($m_sDump, \@m_aTree);
            }
            if (ref @$t[$i]->{subtree} eq 'ARRAY') {
                sortUp(\@{@$t[$i]->{subtree}}, $find);
                saveTree($m_sDump, \@m_aTree);
            }
        }
    }
}

sub deleteEntry {
    my $t    = shift;
    my $find = shift;
    for (my $i = 0 ; $i < @$t ; $i++) {
        no warnings;
        if (@$t[$i]->{rid} eq $find) {
            splice @$t, $i, 1;
            saveTree($m_sDump, \@m_aTree);
        } elsif (ref @$t[$i]->{subtree} eq 'ARRAY') {
            deleteEntry(\@{@$t[$i]->{subtree}}, $find);
        }
    }
}

sub updateTree {
    my $t = shift;
    for (my $i = 0 ; $i < @$t ; $i++) {
        no warnings;
        if (defined @$t[$i]) {
            @$t[$i]->{onmouseup} = 'confirmMove()';

            #             @$t[$i]->{id}          = @$t[$i]->{id};
            @$t[$i]->{name}        = @$t[$i]->{id};
            @$t[$i]->{onmousedown} = "prepareMove('" . @$t[$i]->{id} . "')";
            @$t[$i]->{onmousemove} = "enableDropZone('" . @$t[$i]->{id} . "')";
            @$t[$i]->{onmouseout}  = "disableDropZone('" . @$t[$i]->{id} . "')";
            my $nPrevId = 'a' . (@$t[$i]->{rid} - 1);
            @$t[$i]->{addition} =
              qq|<table border="0" cellpadding="0" cellspacing="0" align="right" summary="layout"><tr>
<td><a class="treeviewLink$m_nSize" target="_blank" title="@$t[$i]->{text}" href="@$t[$i]->{href}"><img src="/style/$m_sStyle/$m_nSize/mimetypes/www.png" border="0" alt=""></a></td>
<td><a class="treeviewLink$m_nSize" href="$ENV{SCRIPT_NAME}?action=editTreeviewEntry&rid=@$t[$i]->{rid}"><img src="/style/$m_sStyle/$m_nSize/mimetypes/edit.png" border="0" alt="edit"></a></td><td><a class="treeviewLink$m_nSize" onclick="location.href='$ENV{SCRIPT_NAME}?action=deleteTreeviewEntry&rid=@$t[$i]->{rid}'"><img src="/style/$m_sStyle/$m_nSize/mimetypes/editdelete.png" border="0" alt="delete"></a></td><td><a class="treeviewLink$m_nSize" href="$ENV{SCRIPT_NAME}?action=upEntry&rid=@$t[$i]->{rid}#@$t[$i]->{id}"><img src="/style/$m_sStyle/$m_nSize/mimetypes/up.png" border="0" alt="up"></a></td><td><a class="treeviewLink$m_nSize" href="$ENV{SCRIPT_NAME}?action=downEntry&rid=@$t[$i]->{rid}"><img src="/style/$m_sStyle/$m_nSize/mimetypes/down.png" border="0" alt="down"></a></td><td><a class="treeviewLink$m_nSize" href="$ENV{SCRIPT_NAME}?action=newTreeviewEntry&rid=@$t[$i]->{rid}"><img src="/style/$m_sStyle/$m_nSize/mimetypes/filenew.png" border="0" alt="new"></a></td><td><input type="checkbox" name="markBox$i" class="markBox" value="@$t[$i]->{rid}" /></td></tr></table>|;
            @$t[$i]->{href} = '';
            updateTree(\@{@$t[$i]->{subtree}}) if (ref @$t[$i]->{subtree} eq 'ARRAY');
        }
    }
}

sub rid {
    no warnings;
    $m_nRid = 0;
    &getRid(\@m_aTree);

    sub getRid {
        my $t = shift;
        for (my $i = 0 ; $i < @$t ; $i++) {
            $m_nRid++;
            next unless ref @$t[$i] eq 'HASH';
            @$t[$i]->{rid} = $m_nRid;
            @$t[$i]->{id}  = "a$m_nRid";
            getRid(\@{@$t[$i]->{subtree}}) if (ref @$t[$i]->{subtree} eq 'ARRAY');
        }
    }
}

sub load {
    if (-e $m_sDump) {
        loadTree($m_sDump);
        *m_aTree = \@{$HTML::Menu::TreeView::TreeView[0]};
    }
}

sub deleteTreeviewEntrys {
    &load();
    my @params = param();

    for (my $i = 0 ; $i <= $#params ; $i++) {
        if ($params[$i] =~ /markBox\d?/) {

            my $id = param($params[$i]);
            &deleteEntry(\@m_aTree, $id);

        }
    }
    editTreeview();
}
1;
