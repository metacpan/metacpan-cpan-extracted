#!/usr/bin/env perl
use strict;
use Carp;
use Pod::Usage;

=head1 NAME

cgiComputePI.pl

=head1 DESCRIPTION

Predict peptide PI based on sequence

=head1 SYNOPSIS


=head1 ARGUMENTS

=over 4

=item -in=file

Text file. Each line starts with a peptide sequence


=back


=head1 OPTIONS

=over 4

=item expdata=(calibrate)

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


use InSilicoSpectro::InSilico::IsoelPoint;
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


  my %method2authors=(
		      iterative=>InSilicoSpectro::InSilico::IsoelPoint::getAuthorList('iterative'),
		     );


  print <<EOT;
<body onload='initSelects()'>
  <script language='javascript'>
    var method2authors=new Array();
EOT

  foreach my $meth (sort keys %method2authors){
    print "method2authors['$meth']=new Array()\n";
    print STDERR "method2authors['$meth']=new Array()\n";
    print STDERR "$method2authors{$meth}\n";
    if($method2authors{$meth}){
      foreach(sort @{$method2authors{$meth}}){
        print <<EOT;
        var el=document.createElement('option');
        el.text='$_';
        el.value='$_';
        method2authors['$meth'].push(el);
EOT
	print STDERR "method2authors['$meth'].push(el);\n";
      }
    }
  }
  print <<EOT;
    function getMethod(){
      var i=document.computepi.method.selectedIndex;
      if(i<0){
        return null;
      }
      return method=document.computepi.method.options[i].value;
    }
    function changedMethod(){
      var method=getMethod();
      authorsel=document.computepi.author;
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
      methodsel=document.computepi.method;
      for (i=0; i<methodsel.options.length; i++){
        if(methodsel.options[i].value == s){
         methodsel.selectedIndex=i;
        }
      }
      changedMethod();
    }


    function selectAuthor(s){
      authorsel=document.computepi.author;
      for (i=0; i<authorsel.options.length; i++){
        if(authorsel.options[i].value == s){
         authorsel.selectedIndex=i;
        }
      }
    }

   var isCompulsExpData;
   function setCompulsExpData(b){
      cbcalib=document.computepi.cb_exp_calibrate;
      if(cbcalib == null){
        //page has not yet been totally built;
        return;
      }
      authorsel=document.computepi.author;
      document.getElementById('opt_or_compuls_exp').innerHTML='optional';

     cbcalib.disabled=b;
     isCompulsExpData=b;
   }

   function setCBExp(cb){
      cbcalib=document.computepi.cb_exp_calibrate;
    }
EOT
  print <<EOT;
  </script>
  <center>
    <h1>$script</h1>
    <h3>An amino acid sequence => PI predictor (<a href="$script?doc=1">?</a>)</h3>
  </center>
  <form name='computepi' method='post' enctype='multipart/form-data'>
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
        <input type="checkbox" name="cb_exp_calibrate" onchange='setCBExp(this)'/> calibrate from
      </td>
      <td><textarea name="expdata" rows=10 cols=80></textarea></td>
    </tr>

  </table>
  <input type="hidden" name="action" value="predict"/>
  <input type="submit" value="predict PI"/>
  </form>
EOT
  print $query->end_html;
  exit(0);
}


my $method=$query->param('method')||CORE::die "must provide method parameter";
my $author=$query->param('author');
my $peptseq=$query->param('peptseq');
my $expdata=$query->param('expdata');
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

my $pi=InSilicoSpectro::InSilico::IsoelPoint->new(method=>$method,current=>$author);

if ($cb_exp_calibrate) {
  my $ec=InSilicoSpectro::InSilico::ExpCalibrator->new(fitting=>'linear');
  $pi->calibrate(data=>{calseqs=>\@expSeq,caltimes=>\@expTimes},calibrator=>$ec);
}
foreach (split /\n/, $peptseq){
  s/\s+$//;
  next unless /\S/;
  my ($peptide,$remaining)=split(' ',$_,2);
  chomp $remaining;
  my $pt=$pi->predict(peptide => uc $peptide);
  print "$peptide $remaining $pt \n"; 
}


__DATA__
<html>
  <head>
    <title>cgiComputePI.pl - HPLC retention time predictor</title>
  </head>
  <body>
    <center>
      <h1>cgiComputePI.pl</h1>
      <h3>Peptide Isolelectric point predictor</h3>
    </center>
  <a name="goal"/><h3>Goal</h3>
  <i>cgiComputerPI.pl</i> is a cgi application for predicting PI. It is a weaker version of the <i>computePI.pl</i> that comes with the library InSilicoSpectro and which gives you much more flexibility</i>.
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
      <li><b>calibrating:</b> if not enough valid experimental data are available, one can use published parameters and make a linear calibration with his own data at the end of the computation.</i>
    </ul>
    The command-line version <i>computePI.pl</i> will allow, for instance, to save the learned parameters in a file and re-use them later.
  <p/>
  <body>
</html>

