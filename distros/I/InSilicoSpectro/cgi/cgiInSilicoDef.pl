#!/usr/bin/env perl
use strict;
use Carp;
use  Pod::Usage;

=head1 NAME

=head1 DESCRIPTION

This program is only useful for InSilicoSpectro used in the Phenyx environment.
Returns a given file corresponding to a given user (for example, the file with the user modifications).

=head1 SYNOPSIS

http://www.phenyx-ms.com/tools/cgi/getUserFile.pl?user=jo&file=modres.xml

=head1 ARGUMENTS

=over 4

=item user=name

=item file=filename

=back

=head1 OPTIONS

=over 4

=item zip=1

Make a zip archive with the file.

=item opt=1

Does not CORE::die if a requested file does not exist

=item help=1

=back

=head1 COPYRIGHT

Copyright (C) 2004-2005  Geneva Bioinformatics www.genebio.com

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=head1 AUTHORS

Alexandre Masselot, www.genebio.com

=cut

BEGIN{
  eval{
   require DefEnv;
   DefEnv::read();
  };
  if($@){
  }
}

END{
}

$|=1;		        #  flush immediately;

my $isCGI;
use CGI qw(:standard);
if($isCGI){
  use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
  warningsToBrowser(1);
}

use InSilicoSpectro;
use InSilicoSpectro::InSilico::CleavEnzyme;
use InSilicoSpectro::InSilico::ModRes;

BEGIN{
  $isCGI=$ENV{GATEWAY_INTERFACE}=~/CGI/;
  sub carp_error{
    my $msg=shift;
    if ($isCGI){
      my $q=new CGI;
      error($q, $msg);
    }else{
      print STDERR $msg;
    }
  }
  CGI::Carp::set_message(\&carp_error);# if $isCGI;

  sub error(){
    my($q, $msg)=@_;
    #  $q->header;
    print $q->start_html(-title=>"$0",
			 -author=>'alexandre.masselot@genebio.com',
			 -BGCOLOR=>'white');
    print "<center><h1>$0</h1></center>\n";
    print  "<i>$msg</i>\n";
    $q->end_html;
    exit;
  }
}


my $query = new CGI;

my $frame=$query->param('frame');

my @args;
push @args, "file=".$query->param('file') if $query->param('file');
push @args, "user=".$query->param('user') if $query->param('user');
my $edit=$query->param('edit');
my $username=$query->param('user');
my $filename=$query->param('file');
my $args=join '&', @args;

unless(defined $frame){
  print $query->header;
  print <<EOT;
<html>
  <head>
    <title>$0</title>
    <frameset cols="200,*" frameborder="1">
      <frame name="contents" src="?frame=contents&$args"/>
      <frame name="main" src="about:blank"/>
    </frameset>
  </head>
</html>
EOT
  exit(0);
}elsif($frame eq 'contents'){
  print $query->header;
  print <<EOT;
<html>
  <body>
    <ul>
      <li><a href=?cat=cleavenzyme&frame=main&$args target="main">cleavage enzymes</a></li>
      <li><a href=?cat=modres&frame=main&$args target="main">residue modif.</a></li>
  </body>
</html>
EOT
  exit(0);
}

#}elsif($frame eq 'main'){

print $query->header;

my $defFile=$query->param('file');
if($query->param('user')){
  require Phenyx::Config::GlobalParam;
  Phenyx::Config::GlobalParam::readParam();
  require Phenyx::Manage::User;
  my $user=Phenyx::Manage::User->new({name=>$query->param('user')});
  $defFile=$user->getFile("insilicodef.xml");
}
unless ($defFile){
  undef $edit;
  my @tmp=InSilicoSpectro::getInSilicoDefFiles();
  require XML::Merge;
  require File::Spec;
  use File::Copy;
  use File::Temp qw(tempfile);
  my $tmpdir=File::Spec->tmpdir();
  (undef, $defFile) = tempfile('insilicodef-XXXXX', SUFFIX=>'.xml', UNLINK=>1, DIR=>$tmpdir);
  my $first=shift @tmp or CORE::die "empty list of insilico def files";
  copy $first, $defFile;
  my $merge_obj = XML::Merge->new(filename => $defFile);
  foreach (@tmp){
    $merge_obj->merge(filename => $_);
  }
  $merge_obj->tidy();
  $merge_obj->write();
}

my $cat=$query->param('cat');
CORE::die "argument cat=(modres|cleavenzyme)" unless $cat=~/^(modres|cleavenzyme)$/;

use XML::Twig;
my $twig=XML::Twig->new(pretty_print=>'indented');
$twig->parsefile($defFile) or croak "cannot parse xml file [$defFile]";

my $testSequence=$query->param('sequence')||'MKWVTFISLLFLFSSAYSRGVFRRDAHKSEVAHRFKDLGEENFKALVLIAFAQYLQQCPF
EDHVKLVNEVTEFAKTCVADESAENCDKSLHTLFGDKLCTVATLRETYGEMADCCAKQEP
ERNECFLQHKDDNPNLPRLVRPEVDVMCTAFHDNEETFLKKYLYEIARRHPYFYAPELLF
FAKRYKAAFTECCQAADKAACLLPKLDELRDEGKASSAKQRLKCASLQKFGERAFKAWAV
ARLSQRFPKAEFAEVSKLVTDLTKVHTECCHGDLLECADDRADLAKYICENQDSISSKLK
ECCEKPLLEKSHCIAEVENDEMPADLPSLAADFVESKDVCKNYAEAKDVFLGMFLYEYAR
RHPDYSVVLLLRLAKTYETTLEKCCAAADPHECYAKVFDEFKPLVEEPQNLIKQNCELFE
QLGEYKFQNALLVRYTKKVPQVSTPTLVEVSRNLGKVGSKCCKHPEAKRMPCAEDYLSVV
LNQLCVLHEKTPVSDRVTKCCTESLVNRRPCFSALEVDETYVPKEFNAETFTFHADICTL
SEKERQIKKQTALVELVKHKPKATKEQLKAVMDDFAAFVEKCCKADDKETCFAEEGKKLV
AASQAALGL';

print <<EOT;

<html>
<head>
  <script language='javascript'>
    var defList=new Array();
EOT
use LockFile::Simple qw(lock trylock unlock);
my $lockmgr = LockFile::Simple->make(-format => '%f.lck',
				      -max => 20, -delay => 1, -nfs => 1, -autoclean => 1);
if($cat){
  print <<EOT;
    function newObj(cat){
      document.define.key.value='CHANGE_ME';
      document.define.key.disabled=0;
      if(cat == 'cleavenzyme'){
        document.define.sitetype[0].checked=1;
        selectCleavSiteMode('classic');
        document.define.site_terminus[0].checked=1;
        document.define.NTermGain.value='H';
        document.define.CTermGain.value='OH';
      }
      if(cat == 'modres'){
        document.define.sitetype[0].checked=1;
        selectSiteMode('classic');
        document.define.delta_mono.value=9999;
        document.define.delta_avg.value=9999;
      }
    }

    function saveObj(){
      document.define.key.disabled=0;
      document.define.actiontype.value='save';
      document.define.submit();
      return 1;
    }
    function removeObj(){
      if(confirm("do you really want to delete enzyme "+document.define.key.value+"?")){
        document.define.key.disabled=0;
        document.define.actiontype.value='delete';
        document.define.submit();
        return 1;
      }else{
        return 0;
      }
    }
  </script>
EOT
}


if($query->param('actiontype') eq 'save'){
  my $defUser=Phenyx::Manage::User->new(name=>'default');
  InSilicoSpectro::InSilico::MassCalculator::init($defUser->getFile('insilicodef.xml'));
}

my $target=$username?"user [$username]":"file [$filename] (server side)";
if($cat eq 'cleavenzyme'){
  print "<h3>Cleavage enzymes setup for $target</h3>\n";
  my $key=$query->param('key');
  $key=~s/\s/_/g;
  if($query->param('actiontype') eq 'save'){
    my @tmp=$twig->root->get_xpath("//oneCleavEnzyme[\@name='$key']");
    my $el;
    if(@tmp){
      $el=$tmp[0];
    }else{
      $el=XML::Twig::Elt->new()->parse("<oneCleavEnzyme name='$key'/>")->paste(last_child=> $twig->root->first_child('cleavEnzymes'));
    }
    query2cleavEnzyme($query, $el);
    $lockmgr->trylock("$defFile") || croak "can't lock [$defFile]: $!\n";
    open (fd, ">$defFile") or CORE::die "cannot open for writeing [$defFile]: $!";
    $twig->print(\*fd);
    close fd;
    $lockmgr->unlock("$defFile") || croak "can't unlock [$defFile]: $!\n";

  }
  if($query->param('actiontype') eq 'delete'){
    my @tmp=$twig->root->get_xpath("//oneCleavEnzyme[\@name='$key']");
    my $el;
    if(@tmp){
      $el=$tmp[0];
      $el->delete;
      $lockmgr->trylock("$defFile") || croak "can't lock [$defFile]: $!\n";
      open (fd, ">$defFile") or CORE::die "cannot open for writeing [$defFile]: $!";
      $twig->print(\*fd);
      close fd;
      $lockmgr->unlock("$defFile") || croak "can't unlock [$defFile]: $!\n";
    }
  }
  print "  <script language='javascript'>\n";
  my @keys;
  foreach ($twig->root->get_xpath("//oneCleavEnzyme")) {
    my $key=$_->atts->{name};
    push @keys, $key;
    print "    defList['$key']=new Array();\n";
    print "    defList['$key']['name']='$key';\n";
    if (my $els=$_->first_child('site')) {
      print "    defList['$key']['site']=new Array();\n";
      print "    defList['$key']['site']['cleavSite']='".$els->first_child("cleavSite")->text."';\n";
      print "    defList['$key']['site']['adjacentSite']='".$els->first_child("adjacentSite")->text."';\n";
      print "    defList['$key']['site']['terminus']='".$els->first_child("terminus")->text."';\n";
    } else {
      print "    defList['$key']['siteRegexp']='".$_->first_child('siteRegexp')->text."';\n";
    }
    print "    defList['$key']['NTermGain']='".$_->first_child('NTermGain')->text."';\n";
    print "    defList['$key']['CTermGain']='".$_->first_child('CTermGain')->text."';\n";
  }
  print <<EOT;

    function id2cleavenzymeForm(id){
      document.define.key.value=id;
      document.test.key.value=id;

      document.define.key.disabled=1;
      ce=defList[id];
      if(ce['site']!=null){
        selectCleavSiteMode('classic');
        document.define.sitetype[0].checked=1;
        document.define.site_cleav.value=ce['site']['cleavSite'];
        document.define.site_adjacent.value=ce['site']['adjacentSite'];
        term=ce['site']['terminus'];
        document.define.site_terminus[((term == 'C')?0:1)].checked=1;
      }else{
        selectCleavSiteMode('regexp');
        document.define.sitetype[1].checked=1;
        document.define.siteregexp.value=ce['siteRegexp'];
      }
      document.define.NTermGain.value=ce['NTermGain'];
      document.define.CTermGain.value=ce['CTermGain'];
    }

    function selectCleavSiteMode(val){
      if(val == 'classic'){
        document.getElementById('cleavsite_regexp').bgColor='lightgrey';
        document.getElementById('cleavsite_classic').bgColor='white';
        document.define.site_cleav.disabled=0;
        document.define.site_adjacent.disabled=0;
        document.define.site_terminus[0].disabled=0;
        document.define.site_terminus[1].disabled=0;
        document.define.siteregexp.disabled=1;
        document.define.siteregexp.value='';
        return;
      }
      if(val == 'regexp'){
        document.getElementById('cleavsite_classic').bgColor='lightgrey';
        document.getElementById('cleavsite_regexp').bgColor='white';
        document.define.site_cleav.disabled=1;
        document.define.site_adjacent.disabled=1;
        document.define.site_terminus[0].disabled=1;
        document.define.site_terminus[1].disabled=1;
        document.define.site_cleav.value='';
        document.define.site_adjacent.value='';
        document.define.siteregexp.disabled=0;
        return;
      }
    }
    function check(){
      return 1;
    }

    </script>
  </head>
  <body>
    <form name="define"  method="get">
    <table border='1' cellspacing='0'>
      <tr>
        <td valign='top'>
          <select size=20 onchange="id2cleavenzymeForm(this.value)">
EOT
  foreach (sort @keys) {
    print "            <option value='$_' ".(($_ eq $key)?'selected="1"':'').">$_</option>\n";
  }
    print <<EOT;
          </select>
        </td>
        <td>
          <h5>Name <input type='textfield' name='key'/></h5>
          <h5>Cleavage site</h5>
          <table border=1 cellspacing=0>
            <tr id="cleavsite_classic">
              <td valign='top'>Site</td>
              <td valign='top'><input type="radio" name="sitetype" value="classic" onclick="selectCleavSiteMode('classic');"/></td>
              <td>
                <table>
                  <tr>
                  <td>cleav at</td>
                  <td><input type='textfield' name='site_cleav'/></td>
                  </tr>
                  <tr>
                  <td>adjacent</td>
                  <td><input type='textfield' name='site_adjacent'/></td>
                  </tr>
                  <tr>
                  <td valign='top'>terminus</td>
                  <td><input type="radio" name="site_terminus" value="C" SELECTED/>C<br/><input type="radio" name="site_terminus" value="N"/>N</td>
                  </tr>
                </table>
              </td>
            </tr>
            <tr id="cleavsite_regexp">
              <td valign='top'>Regular expression</td>
              <td valign='top'><input type="radio" name="sitetype"  value="regexp" onclick="selectCleavSiteMode('regexp');"/></td>
              <td><input type='textfield' name='siteregexp'/></td>
            </tr>
          </table>

          <h5>Gain (formula)</h5>
          <table border=1 cellspacing=0>
            <tr>
              <td>N-term</td>
              <td><input type="textfield" name="NTermGain"/></td>
            </tr>
            <tr>
              <td>C-term</td>
              <td><input type="textfield" name="CTermGain"/></td>
            </tr>
          </table>
        </td>
      </tr>
      <tr>
EOT
  if ($edit){
    print <<EOT;
        <td colspan='2'>
          <input type="button" value="new" onclick="newObj('$cat');"/>
          <input type="button" value="delete" onclick="removeObj();"/>
          <input type="submit" value="save" onclick="saveObj();"/>
          <input type='hidden' name='edit' value='1'/>
        </td>
EOT
  }
  print <<EOT;
      </tr>
    </table>
EOT

  foreach (@args){
    my ($n, $v)=split /=/, $_, 2;
    print "    <input type='hidden' name='$n' value='$v'/>\n";
  }
  print "    <input type='hidden' name='cat' value='cleavenzyme'/>\n";
  print "    <input type='hidden' name='actiontype' value='n/A'/>\n";

  print "    <input type='hidden' name='frame' value='main'/>\n";

print <<EOT;
    </form>
EOT

print <<EOT;
<form name='test'>
  <textarea name='sequence' cols=60 rows=5>$testSequence</textarea>
  <br/>
  <input type="submit" value="test"/>
EOT

  foreach (@args){
    my ($n, $v)=split /=/, $_, 2;
    print "    <input type='hidden' name='$n' value='$v'/>\n";
  }
  print "    <input type='hidden' name='cat' value='cleavenzyme'/>\n";
  print "    <input type='hidden' name='actiontype' value='test'/>\n";
  print "    <input type='hidden' name='key' value=''/>\n";
  print "    <input type='hidden' name='edit' value='1'/>\n" if $edit;

  print "    <input type='hidden' name='frame' value='main'/>\n";
  print "  </form>\n";

print "  <script language='javascript'>id2cleavenzymeForm('$key')</script>\n" if defined $key;


  if($query->param('actiontype') eq 'test'){
    my $el=($twig->root->get_xpath("//oneCleavEnzyme[\@name='$key']"))[0];
    twig_addEnzyme($twig, $el);
    my $enzyme=InSilicoSpectro::InSilico::CleavEnzyme::getFromDico($key);
    print "/".($enzyme->regexp)."/\n";
    print "<pre>\n";
    foreach(split $enzyme->regexp, $testSequence){
      print "<tt>$_</tt>\n";
    }
    print "</pre>\n";
  }

print <<EOT;
  </body>
</html>
EOT
}

###############################################################

if($cat eq 'modres'){
  print "<h3>Residue modifications setup for $target</h3>\n";
  my $key=$query->param('key');
  $key=~s/\s/_/g;
  if($query->param('actiontype') eq 'save'){
    my @tmp=$twig->root->get_xpath("//oneModRes[\@name='$key']");
    my $el;
    if(@tmp){
      $el=$tmp[0];
    }else{
      $el=XML::Twig::Elt->new()->parse("<oneModRes name='$key'/>")->paste(last_child=> $twig->root->first_child('modRes'));
    }
    query2modres($query, $el);
    $lockmgr->trylock("$defFile") || croak "can't lock [$defFile]: $!\n";
    open (fd, ">$defFile") or CORE::die "cannot open for writeing [$defFile]: $!";
    $twig->print(\*fd);
    close fd;
    $lockmgr->unlock("$defFile") || croak "can't unlock [$defFile]: $!\n";
  }
  if($query->param('actiontype') eq 'delete'){
    my @tmp=$twig->root->get_xpath("//oneModRes[\@name='$key']");
    my $el;
    if(@tmp){
      $el=$tmp[0];
      $el->delete;
      $lockmgr->trylock("$defFile") || croak "can't lock [$defFile]: $!\n";
      open (fd, ">$defFile") or CORE::die "cannot open for writeing [$defFile]: $!";
      $twig->print(\*fd);
      close fd;
      $lockmgr->unlock("$defFile") || croak "can't unlock [$defFile]: $!\n";
    }
  }
  print "  <script language='javascript'>\n";
  my @keys;
  foreach ($twig->root->get_xpath("//oneModRes")) {
    my $key=$_->atts->{name};
    push @keys, $key;
    print "    defList['$key']=new Array();\n";
    print "    defList['$key']['name']='$key';\n";
    my $descr=$_->first_child('description')->text;
    $descr=~s/'/ /g;
    $descr=~s/[\r\n]//g;
    print "    defList['$key']['description']='$descr';\n";
    if (my $els=$_->first_child('site')) {
      print "    defList['$key']['residue']='".$els->first_child("residue")->text."';\n";
      print "    defList['$key']['nterm']=".($els->first_child("nterm")?'1':'0').";\n";
      print "    defList['$key']['cterm']=".($els->first_child("cterm")?'1':'0').";\n";
    } elsif($_->first_child('siteRegexp')){
      print "    defList['$key']['siteRegexp']='".$_->first_child('siteRegexp')->text."';\n";
      print "    defList['$key']['nterm']=".(0+$_->atts->{nterm}).";\n";
      print "    defList['$key']['cterm']=".(0+$_->atts->{cterm}).";\n";
    }else{#oldfashion
      print "    defList['$key']['residue']='".$_->first_child('residue')->atts->{a}."';\n";
    }
    print "    defList['$key']['delta_mono']='".$_->first_child('delta')->atts->{monoisotopic}."';\n";
    print "    defList['$key']['delta_avg']='".$_->first_child('delta')->atts->{average}."';\n";
    print "    defList['$key']['formula']='".($_->first_child('formula')?$_->first_child('formula')->text:'')."';\n";
    my $spft=($_->first_child('sprotFT'))?($_->first_child('sprotFT')->text):"";
    print "    defList['$key']['sprotFT']=\"$spft\";\n";
  }
  print <<EOT;

    function id2modresForm(id){
      document.define.key.value=id;
      document.test.key.value=id;

      document.define.key.disabled=1;
      mr=defList[id];
      document.define.description.value=mr.description;
      if(mr['residue']!=null){
        selectSiteMode('classic');
        document.define.sitetype[0].checked=1;
        document.define.residue.value=mr['residue'];
      }else{
        selectSiteMode('regexp');
        document.define.sitetype[1].checked=1;
        document.define.siteregexp.value=mr['siteRegexp'];
      }
      document.define.nterm.checked=mr['nterm'];
      document.define.cterm.checked=mr['cterm'];
      document.define.delta_mono.value=mr['delta_mono'];
      document.define.delta_avg.value=mr['delta_avg'];
      document.define.formula.value=mr['formula'];
      document.define.sprotFT.value=mr['sprotFT'];

    }

    function selectSiteMode(val){
      if(val == 'classic'){
        document.getElementById('site_regexp').bgColor='lightgrey';
        document.getElementById('site_classic').bgColor='white';
        document.define.sitetype[0].checked=1;
        document.define.residue.disabled=0;
        document.define.siteregexp.disabled=1;
        document.define.siteregexp.value='';
        return;
      }
      if(val == 'regexp'){
        document.getElementById('site_classic').bgColor='lightgrey';
        document.getElementById('site_regexp').bgColor='white';
        document.define.sitetype[1].checked=1;
        document.define.residue.disabled=1;
        document.define.residue.value='';
        document.define.siteregexp.disabled=0;
        return;
      }
    }

    function check(){
      return 1;
    }

    </script>
  </head>
  <body>
    <form name="define"  method="get">
    <table border='1' cellspacing='0'>
      <tr>
        <td valign='top'>
          <select size=20 onchange="id2modresForm(this.value)">
EOT
  foreach (sort @keys) {
    print "            <option value='$_' ".(($_ eq $key)?'selected="1"':'').">$_</option>\n";
  }
    print <<EOT;
          </select>
        </td>
        <td>
          <h5>Name <input type='textfield' name='key'/></h5>
          <h5>Description</h5>
            <input type='textfield' size=80 name='description'/>
          <hr width="100%"/>
          <center><h4>Position</h4></center>
          <h5>Modif site</h5>
          <table border=1 cellspacing=0>
            <tr id="site_classic">
              <td valign='top'>Residue</td>
              <td valign='top'><input type="radio" name="sitetype" value="classic" onclick="selectSiteMode('classic');"/></td>
              <td>
                <input type='textfield' name='residue'/>
              </td>
            </tr>
            <tr id="site_regexp">
              <td valign='top'>Regular expression</td>
              <td valign='top'><input type="radio" name="sitetype"  value="regexp" onclick="selectSiteMode('regexp');"/></td>
              <td><input type='textfield' name='siteregexp'/></td>
            </tr>
          </table>

          <h5>Peptide terminus</h5>
          nterm <input type="checkbox" name="nterm"/>
          cterm <input type="checkbox" name="cterm"/>

          <hr width="100%"/>
          <center><h4>Mass modification</h4></center>
          <h5>Delta mass</h5>
          <table border=1 cellspacing=0>
            <tr>
              <td>mono isotopic</td>
              <td><input type="textfield" name="delta_mono"/></td>
            </tr>
            <tr>
              <td>average</td>
              <td><input type="textfield" name="delta_avg"/></td>
            </tr>
          </table>

          <h5>Formula</h5>
          <input type="textfield" name="formula"/>

          <hr width="100%"/>
          <center><h4>Uniprot annotations</h4></center>
          <h5>Uniprot FT mask</h5>
          <input type='textfield' size=80 name='sprotFT'/>
        </td>
      </tr>
      <tr>
EOT
  if ($edit){
    print <<EOT;
        <td colspan='2'>
          <input type="button" value="new" onclick="newObj('$cat');"/>
          <input type="button" value="delete" onclick="removeObj();"/>
          <input type="submit" value="save" onclick="saveObj();"/>
          <input type='hidden' name='edit' value='1'/>
        </td>
      </tr>
    </table>
EOT
  }
  print <<EOT;
      </tr>
    </table>
EOT

  foreach (@args){
    my ($n, $v)=split /=/, $_, 2;
    print "    <input type='hidden' name='$n' value='$v'/>\n";
  }
  print "    <input type='hidden' name='cat' value='modres'/>\n";
  print "    <input type='hidden' name='actiontype' value='n/A'/>\n";

  print "    <input type='hidden' name='frame' value='main'/>\n";

print <<EOT;
    </form>
EOT

print <<EOT;
<form name='test'>
  <textarea name='sequence' cols=60 rows=5>$testSequence</textarea>
  <br/>
  <input type="submit" value="test"/>
EOT

  foreach (@args){
    my ($n, $v)=split /=/, $_, 2;
    print "    <input type='hidden' name='$n' value='$v'/>\n";
  }
  print "    <input type='hidden' name='cat' value='modres'/>\n";
  print "    <input type='hidden' name='actiontype' value='test'/>\n";
  print "    <input type='hidden' name='key' value=''/>\n";
  print "    <input type='hidden' name='edit' value='1'/>\n" if $edit;

  print "    <input type='hidden' name='frame' value='main'/>\n";
  print "  </form>\n";

print "  <script language='javascript'>id2modresForm('$key')</script>\n" if defined $key;


  if($query->param('actiontype') eq 'test'){
    my $el=($twig->root->get_xpath("//oneModRes[\@name='$key']"))[0];
    twig_addModRes($twig, $el);
    my $mr=InSilicoSpectro::InSilico::ModRes::getFromDico($key);
    my $qr=$mr->regexp;
    print "<h4>$qr</h4>\n";
    $testSequence=~s/($qr)/<b>$1<\/b>/g;
    print "<tt>$testSequence</tt>\n";

  }


print <<EOT;
  </body>
</html>
EOT
}





sub query2cleavEnzyme{
  my ($q, $el)=@_;
  foreach ($el->children){
    $_->delete;
  }
  if($q->param('sitetype')eq 'classic'){
    my $els=XML::Twig::Elt->new()->parse("
<site>
  <cleavSite>".(uc $q->param('site_cleav'))."</cleavSite>
  <adjacentSite>".((uc $q->param('site_adjacent'))||'.')."</adjacentSite>
  <terminus>".(uc $q->param('site_terminus'))."</terminus>
</site>
")->paste(first_child=>$el);;
  }else{
    my $els=XML::Twig::Elt->new()->parse("<siteRegexp><![CDATA[".$q->param('siteregexp')."]]></siteRegexp>")->paste(first_child=>$el);;
  }
  XML::Twig::Elt->new()->parse("<CTermGain>".$q->param('CTermGain')."</CTermGain>")->paste(last_child=>$el);
  XML::Twig::Elt->new()->parse("<NTermGain>".$q->param('NTermGain')."</NTermGain>")->paste(last_child=>$el);

}

sub query2modres{
  my ($q, $el)=@_;
  foreach ($el->children){
    $_->delete;
  }
  XML::Twig::Elt->new()->parse("<description>".$q->param('description')."</description>")->paste(last_child=>$el);

  if($q->param('sitetype')eq 'classic'){
    my $contents="<site>";
    $contents.="<residue>".(uc $q->param('residue'))."</residue>";
    $contents.="<nterm/>" if $q->param('nterm');
    $contents.="<cterm/>" if $q->param('cterm');
    $contents.="</site>";
    my $els=XML::Twig::Elt->new()->parse($contents)->paste(last_child=>$el);;
  }else{
    my $atts;
    $atts.=" nterm='yes'" if $q->param('nterm');
    $atts.=" cterm='yes'" if $q->param('cterm');
    my $els=XML::Twig::Elt->new()->parse("<siteRegexp$atts><![CDATA[".$q->param('siteregexp')."]]></siteRegexp>")->paste(first_child=>$el);
  }
  my $formula=$q->param('formula');
  my $dm_mono=$q->param('delta_mono')||-999;
  my $dm_avg=$q->param('delta_avg')||-999;
  if ($formula){
    ($dm_mono, $dm_avg)=InSilicoSpectro::InSilico::MassCalculator::massFromComposition($formula);
  }
  XML::Twig::Elt->new()->parse("<delta monoisotopic='$dm_mono' average='$dm_avg'/>")->paste(last_child=>$el);
  XML::Twig::Elt->new()->parse("<formula>$formula</formula>")->paste(last_child=>$el) if $q->param('formula');
  XML::Twig::Elt->new()->parse("<sprotFT><![CDATA[".$q->param('sprotFT')."]]></sprotFT>")->paste(last_child=>$el);
}
