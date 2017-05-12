#!/usr/bin/env perl
use strict;
use Carp;
use Pod::Usage;

=head1 NAME

cgiComputeRT.pl

=head1 DESCRIPTION

Predict HPLC retention times

=head1 SYNOPSIS


=head1 ARGUMENTS

=over 4

=item -in=file

Text file. Each line starts with a peptide sequence


=back


=head1 OPTIONS

=over 4

=item expdata=(learn|calibrate)

Prints all possible output formats

=item --help

=item --man

=item --verbose

=back


=head1 EXAMPLE



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

Pablo Carbonell

Alexandre Masselot, www.genebio.com

=cut


$|=1;		        #  flush immediately;

BEGIN{
  use File::Basename;
  push @INC, basename($0);
}
BEGIN {
  use CGIUtils;
}


use InSilicoSpectro::InSilico::RetentionTimer;
use InSilicoSpectro::InSilico::RetentionTimer::Hodges;
use InSilicoSpectro::InSilico::RetentionTimer::Petritis;
eval{
  require  InSilicoSpectro::InSilico::RetentionTimer::Krokhin;
};
use InSilicoSpectro::InSilico::ExpCalibrator;


my $query = new CGI;

if($query->param('doc')){
  print $query->header;
  while(<DATA>){
    print $_;
  }
  exit(0);
}

my $help=$query->param('help');
if(defined $help){
  print $query->header('text/plain');
  pod2usage(-verbose=>2, -exitval=>0);
}

my $peptideList=join("\n", split(/:/, $query->param('peptideList')));
my $action=$query->param('action');
my $script=basename $0;
unless($action){
  my %cookies=$query->cookie($script);
  my $method=$cookies{method};
  my $author=$cookies{author};

  print $query->header;
  print $query->start_html(-title=>"$script - ms/ms peaklist converter",
			   -author=>'alexandre.masselot@genebio.com'
			  );


  my @tmpH=InSilicoSpectro::InSilico::RetentionTimer::Hodges::getAuthorList();
  my %method2authors=(
		      Hodges=>\@tmpH,
		      Petritis=>undef,
		     );


  print <<EOT;
<body onload='initSelects()'>
  <script language='javascript'>
    var method2authors=new Array();
EOT

  foreach my $meth (sort keys %method2authors){
    print "method2authors['$meth']=new Array()\n";
    if($method2authors{$meth}){
      foreach(sort @{$method2authors{$meth}}){
        print <<EOT;
        var el=document.createElement('option');
        el.text='$_';
        el.value='$_';
        method2authors['$meth'].push(el);
EOT
      }
    }
  }
  print <<EOT;
    function getMethod(){
      var i=document.computert.method.selectedIndex;
      if(i<0){
        return null;
      }
      return method=document.computert.method.options[i].value;
    }
    function changedMethod(){
      var method=getMethod();
      authorsel=document.computert.author;
      authorsel.options.length=0;
      for(i=0; i<method2authors[method].length; i++){
        authorsel.add(method2authors[method][i], null);
      }

      if(method == 'Hodges'){
        setCompulsExpData(0);
      }
      if(method == 'Petritis'){
        setCompulsExpData(1);
      }
    }

    function initSelects(){
      changedMethod();
    }


    function selectMethod(s){
      methodsel=document.computert.method;
      for (i=0; i<methodsel.options.length; i++){
        if(methodsel.options[i].value == s){
         methodsel.selectedIndex=i;
        }
      }
      changedMethod();
    }


    function selectAuthor(s){
      authorsel=document.computert.author;
      for (i=0; i<authorsel.options.length; i++){
        if(authorsel.options[i].value == s){
         authorsel.selectedIndex=i;
        }
      }
    }

   var isCompulsExpData;
   function setCompulsExpData(b){
      cblearn=document.computert.cb_exp_learn;
      cbcalib=document.computert.cb_exp_calibrate;
      if(cblearn == null){
        //page has not yet been totally built;
        return;
      }
      authorsel=document.computert.author;
     if(b){
       cblearn.checked=1;
       setCBExp(cblearn);
       document.getElementById('opt_or_compuls_exp').innerHTML='COMPULSORY';
     }else{
       document.getElementById('opt_or_compuls_exp').innerHTML='optional';
     }
     cbcalib.disabled=b;
     authorsel.disabled=b;
     isCompulsExpData=b;
   }

   function setCBExp(cb){
      cblearn=document.computert.cb_exp_learn;
      cbcalib=document.computert.cb_exp_calibrate;
      if(isCompulsExpData){
        cblearn.checked=1;
        return;
      }
      if(cb == cblearn){
        cbcalib.checked=0;
      }
      if(cb == cbcalib){
       cblearn.checked=0;
      }
      document.computert.author.disabled= cblearn.checked;
    }
EOT
  print <<EOT;
  </script>
  <center>
    <h1>$script</h1>
    <h3>An HPLC peptide retention time predictor (<a href="$script?doc=1">?</a>)</h3>
  </center>
  <form name='computert' method='post' enctype='multipart/form-data'>
  <table border=1 cellspacing=0>
    <tr>
      <td>Method (<a href="$script?doc=1#author">?</a>)</td>
      <td>
        <select name="method" onchange='changedMethod();'>
EOT
  foreach (sort keys %method2authors){
    print "           <option value='$_'>$_</option>\n";
  }
  print <<EOT;
        </select>
      </td>
    </tr>
    <tr>
      <td>Author (<a href="$script?doc=1#method">?</a>)</td>
      <td><select name='author'/>
    </tr>
    <tr>
      <td valign=top>Peptide sequence(s) (<a href="$script?doc=1#peptseq">?</a>)</td>
      <td><textarea name="peptseq" rows=10 cols=80>$peptideList</textarea></td>
    </tr>
    <script language='javascript'>
      selectMethod('$method');
      selectAuthor('$author');
    </script>
    <tr>
      <td valign=top>
        Experimental data (<a href="$script?doc=1#expdata">?</a>)<br/>
        <font color="red"><a id="opt_or_compuls_exp"></a></font><br/>
        <input type="checkbox" name="cb_exp_learn" onchange='setCBExp(this)'/> learn from<br/>
        <input type="checkbox" name="cb_exp_calibrate" onchange='setCBExp(this)'/> calibrate from
      </td>
      <td><textarea name="expdata" rows=10 cols=80></textarea></td>
    </tr>

  </table>
  <input type="hidden" name="action" value="predict"/>
  <input type="submit" value="predict RT"/>
  </form>
EOT
  print $query->end_html;
  exit(0);
}


my $method=$query->param('method')||CORE::die "must provide method parameter";
my $author=$query->param('author');
my $peptseq=$query->param('peptseq');
my $expdata=$query->param('expdata');
my $cb_exp_learn=$query->param('cb_exp_learn');
my $cb_exp_calibrate=$query->param('cb_exp_calibrate');


my %cookies;
$cookies{method}=$method;
$cookies{author}=$author;


my $cookie=$query->cookie(-name=>$script,
			  -value=>\%cookies,
			  -expires=>'+100d'
			 );

print $query->header(-type=>'text/plain',
		     -cookie=>$cookie,
		    );


my (@expSeq, @expTimes);
if($expdata){
  foreach (split /\n/, $expdata){
    next unless /\S/;
    my @tmp=split;
    push @expSeq, $tmp[0];
    push @expTimes, $tmp[1];
  }
}

print "#method=$method parameter set=$author\n";

my $rt="InSilicoSpectro::InSilico::RetentionTimer::$method"->new(current=>$author);

if ($cb_exp_calibrate) {
  my $ec=InSilicoSpectro::InSilico::ExpCalibrator->new(fitting=>'linear');
  $rt->calibrate(data=>{calseqs=>\@expSeq,caltimes=>\@expTimes},calibrator=>$ec);
}
if ($cb_exp_learn){
  if ($method eq 'Hodges') {
    $rt->learn(data=>{expseqs=>\@expSeq,exptimes=>\@expTimes},
	       current=>'Test',overwrite=>0,comments=>'Test Hodges',
	       );
  } elsif ($method eq 'Petritis') {
    $rt->learn(data=>{expseqs=>\@expSeq,exptimes=>\@expTimes},
	       maxepoch=>30,sqrerror=>1e-3,mode=>'quiet',
	       nnet=>{learningrate=>0.05},layers=>[{nodes=>20},{nodes=>6},{nodes=>1}],
	       );
  }
}
foreach (split /\n/, $peptseq){
  s/\s+$//;
  next unless /\S/;
  my ($peptide,$remaining)=split(' ',$_,2);
  chomp $remaining;
  my $pt=$rt->predict(peptide => uc $peptide);
  print "$peptide $remaining $pt \n"; 
}


__DATA__
<html>
  <head>
    <title>cgiComputeRT - HPLC retention time predictor</title>
  </head>
  <body>
    <center>
      <h1>cgiComputeRT.pl</h1>
      <h3>HPLC retention time predictor</h3>
    </center>
  <a name="goal"/><h3>Goal</h3>
  <i>cgiComputerRT.pl</i> is a cgi application for predicting peptide HPLC retention times. It is a weaker version of the <i>computeRT.pl</i> that comes with the library InSilicoSpectro and which gives you much more flexibility</i>.
  <p/>
  For this script man page, plese click <a href="?help=1">here</a>.
  <a name="parameters"/><h3>Parameters</h3>
  <a name="method"/><h4>Method</h4>
    The method used by the prediciton algorithm (summing weighted residues, neural network, etc.).
  <a name="author"/><h4>Author</h4>
    For a given method, it is possible to use different sets of published parameters.
  <a name="peptseq"/><h4>Petide sequences</h4>
  Paste your data here. Each line must start with a petpide amino acid sequence. The rest of the line will be repeated on the output, with the predicted retention time appended as the last column.
  <a name="expdata"/><h4>Experimental data</h4>
    Experimental data (each line contains a peptide sequence, a space, and one number for time) can be used for:
    <ul>
      <li><b>learning:</b> the <i>author</i> set of parameters will not be taken into account, but parameters will be recomputed from the provided data;</li>
      <li><b>calibrating:</b> if not enough valid experimental data are available, one can use published parameters and make a linear calibration with his own data at the end of the computation.</i>
    </ul>
    For some methods, there is not pre-learned parameters, therefore you must provide experimental data to learn parameters. The command-line version <i>computeRT.pl</i> will allow, for instance, to save the learned parameters in a file and re-use them later.
  <p/>
  <body>
</html>

