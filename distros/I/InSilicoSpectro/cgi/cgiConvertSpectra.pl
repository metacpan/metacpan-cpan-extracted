#!/usr/bin/env perl
use strict;
use Carp;
use Pod::Usage;

=head1 NAME

cgiConvertSpectra.pl


=head1 DESCRIPTION

Converts MS and MS/MS peak lists from/to various formats. See convertSpectra.pl documentation for more details.

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

Alexandre Masselot, Roman Mylonas, www.genebio.com

=cut


$|=1;		        #  flush immediately;

BEGIN{
  eval{
   require DefEnv;
   DefEnv::read();
  };
}

END{
}

use File::Temp qw(tempfile);
use File::Spec;
use Util::Properties;


my $isCGI;
use CGI qw(:standard);
if($isCGI){
  use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
  warningsToBrowser(1);
}

BEGIN{
  $isCGI=$ENV{GATEWAY_INTERFACE}=~/CGI/;
#  sub carp_error{
#    my $msg=shift;
#    if ($isCGI){
#      my $q=new CGI;
#      error($q, $msg);
#    }else{
#      print STDERR $msg;
#    }
#  }
#  CGI::Carp::set_message(\&carp_error) if $isCGI;

#  sub error(){
#    my($q, $msg)=@_;
#    #  $q->header;
#    print $q->start_html(-title=>"$0 - ms/ms peaklist converter",
#			 -author=>'alexandre.masselot@genebio.com',
#			 -BGCOLOR=>'white');
#    print "<center><h1>$0</h1></center>\n";
#    print  "<pre>$msg</pre>\n";
#    $q->end_html;
#    exit;
#  }
}

use InSilicoSpectro::Spectra::MSRun;
use InSilicoSpectro::Spectra::MSSpectra;
use InSilicoSpectro::Spectra::Filter::MSFilterCollection;
use InSilicoSpectro::Utils::io;
use File::Basename;
use CGI qw(:standard);

my $query = new CGI;

if($query->param('doc')){
  print $query->header;
  while(<DATA>){
    print $_;
  }
  exit(0);
}

if ($query->param('action') eq 'upload'){
  uploadManager();
  exit(0);
}

unless($query->param('inputfile')){
  my %cookies=$query->cookie('cgiConvertSpectra.pl');
  my $inputformat=$cookies{inputformat};
  my $outputformat=$cookies{outputformat};
  my $defaultcharge=$cookies{defaultcharge};
  my $filter=$cookies{filter};
  my $filter_activated=$cookies{filter_activated};

  my $script=basename $0;
  print $query->header;
 # print $query->start_html(-title=>"$script - ms/ms peaklist converter",
#			   -author=>'alexandre.masselot@genebio.com',
#			   -script=>[
#				     {
#				      -src      => 'elementControl.js',
#				      -language=> 'JavaScript',
#				     }
#				    ]

#			  );


  print <<EOT;
<head>	
		<title>Submission Page</title>
        <script type="text/javascript">

					//---------------------------------------------------------------------
					// 						blocks collapsing/extending
					//---------------------------------------------------------------------


					function setImage(image, src, display) {
					
						if(image!=null) {
							image.src=src;
                       		image.style.display=display;
						}
					}

                   /*
                    * toggles hide/display of argument element and updates argument image
                    */ 
                   function expandCollapse(currElement, image) {

                     if(currElement.style.display=="none") {
                       expand(currElement, image);
                     } else {
                       collapse(currElement, image);
                     }
                   }


					/**
					 * shows argument element and updates argument image
					 */ 
					function expand(currElement, image) {                    	
                       	currElement.style.display="";
                       	setImage(image, "/images/opentriangle.png", "");                   		
					}
					
					
					/**
					 * hides argument element and updates argument image
					 */
					function collapse(currElement, image) {
                       	currElement.style.display="none";
                       	setImage(image, "/images/triangle.png", "");
					}

					//---------------------------------------------------------------------
					// 						blocks enabling/disabling
					//---------------------------------------------------------------------

					/**
					 * toggles element 
					 */
					function enableDisable(checkBox, currElement, image, doExpand) {
					
					
						if(checkBox.checked==true) {
						
							if(enableDisable.length==4) {
								if(doExpand==true) {
									enable(currElement, image, true);
								} else {
									enable(currElement, image, false);
								}
							} else {
								enable(currElement, image);
							}
						} else {
							disable(currElement, image);
						}					
					}


					/**
					 * enables component ans sets image
					 */
					function enable(currElement, image, doExpand) {
										
						if(enable.length=3) {
							if(doExpand==true) {
								expand(currElement, image);
							} else {
								collapse(currElement, image);
							}
						} else {
							enable(currElement, image, false);
						}
					}
					

					/*
					 * disables component and sets image
					 */
					function disable(currElement, image) {
						collapse(currElement, null);
						setImage(image, "/images/opentriangle.png", "none");
					}


</script>



</head>

<body>
  <center>
    <h1>$script</h1>
    <h3>ms/ms peaklist converter (<a href="$script?doc=1">?</a>)</h3>
  </center>
  <form name='spetraconvertor' method='post' enctype='multipart/form-data'>
  <table border=1 cellspacing=0>
    <tr>
      <td>Input file (<a href="$script?doc=1#inputfile">?</a>)</td>
      <td><input type='file' name='inputfile'></td>
    </tr>
    <tr>
      <td>Input format (<a href="$script?doc=1#inputformat">?</a>)</td>
      <td><select name='inputformat'>
EOT
  foreach (InSilicoSpectro::Spectra::MSMSSpectra::getReadFmtList()){
    print "         <option value='$_'".(($_ eq $inputformat)?' selected="selected"':'').">".InSilicoSpectro::Spectra::MSMSSpectra::getFmtDescr($_)."</option>\n";
  }
  foreach (InSilicoSpectro::Spectra::MSRun::getReadFmtList()){
    print "         <option value='$_'".(($_ eq $inputformat)?' selected="selected"':'').">".InSilicoSpectro::Spectra::MSRun::getFmtDescr($_)."</option>\n";
  }
  print <<EOT;
        </select>
      </td>
    </tr>
    <tr>
      <td>Default charge (<a href="$script?doc=1#defaultcharge">?</a>)</td>
      <td><select name='defaultcharge'>
EOT
  foreach (('1+', '2+', '3+', '2+,3+', '4+')){
    print "         <option value='$_'".(($_ eq $defaultcharge)?' selected="selected"':'').">$_</option>\n";
  }
  print <<EOT;
        </select>
      </td>
    </tr>
    <tr>
      <td>Output format (<a href="$script?doc=1#outputformat">?</a>)</td>
      <td><select name='outputformat'>
EOT
  foreach (InSilicoSpectro::Spectra::MSMSSpectra::getWriteFmtList()){
    print "         <option value='$_'".(($_ eq $outputformat)?' selected="selected"':'').">".InSilicoSpectro::Spectra::MSMSSpectra::getFmtDescr($_)."</option>\n";
  }
  print <<EOT;
        </select>
      </td>
    </tr>
    <tr>
      <td>Title (<a href="$script?doc=1#title">?</a>)</td>
      <td><input type='textfield' name='title' size=80/></td>
    </tr>
    <tr>
      <td>Filter (<a href="$script?doc=1#title">?</a>)</td>
      <td>

      <div id="div_filter" style="position:static;display:">
      <table   width="100%" align="left" >
      <tr>
      <td>	<input type="checkbox" class="submit_input" onclick="enableDisable(this, document.getElementById('expandable_div_textarea'),
        				document.getElementById('expandable_div_image'), true);"
					id="activation_filter" 
					name="activation_filter"
EOT
  print "checked\n" if($filter_activated);

print <<EOT;
                                                                  >
      
    		<A HREF="" onclick="expandCollapse(document.getElementById('expandable_div_textarea'), 
        		document.getElementById('expandable_div_image')); return false;"><IMG border="none" id="expandable_div_image" SRC="/images/triangle.png"><A>
      
      
      
      
	<div  id="expandable_div_textarea" style="position:static;display:none">
      
      
      <textarea name="filter" rows="20" cols="80">$filter</textarea>
      
 </td>
</tr>
      </table>
      </div>
      </div>
      </td>
    </tr>
    <tr><td>Extra convertSpectra.pl arguments</td><td><input type='textfield' name='convertspectraxtraargs' size=80/></td>
  </table>
  <input type="submit" value="convert"/>
  </form>




	<!-- sets filter enablement initial state-->
	<script type="text/javascript">	
	
	
        	// checks if initially selected
        	if(document.getElementById('activation_filter').checked==true) {
                	
        			enable(document.getElementById('expandable_div_image'), 
        				document.getElementById('expandable_div_image'));
        	
        		
        } else {
                	
        			disable(document.getElementById('expandable_div_image'), 
        				document.getElementById('expandable_div_image'));
        	
        }
        	
	</script>


EOT
  print $query->end_html;
  exit(0);
}


my $fileIn=$query->param('inputfile')||CORE::die "must provide input file";
my $inputFormat=$query->param('inputformat')||CORE::die "must provide input format";
my $outputFormat=$query->param('outputformat')||CORE::die "must provide output format";
my $defaultCharge=$query->param('defaultcharge') || CORE::die "must provide default parent charge";
my $title=$query->param('title');
my $filter=$query->param('filter');
my $filter_activated=$query->param('activation_filter');
my $convertSpectraXtraArgs=$query->param('convertspectraxtraargs');

my $help=$query->param('help');
pod2usage(-verbose=>2, -exitval=>2) if(defined $help);


my %cookies;
$cookies{inputformat}=$inputFormat;
$cookies{outputformat}=$outputFormat;
$cookies{defaultcharge}=$defaultCharge;
$cookies{filter}=$filter;
$cookies{filter_activated}=$filter_activated;
$cookies{convertspectraxtraargs}=$convertSpectraXtraArgs;

use File::Basename;
use File::Temp qw(tempfile);
#upload
my $ext=".tmp";
$ext=".gz" if ($fileIn=~/.t?gz$/i);
$ext=".zip" if ($fileIn=~/.zip$/i);
my $fhin=upload('inputfile')||CORE::die "cannot convert [$fileIn] into filehandle";
my $bn=basename $fileIn;
my ($fhout, $finTmp)=tempfile(unlink=>1, SUFFIX=>$ext);
while (<$fhin>){
  print $fhout $_;
}
close $fhin;
close $fhout;



#my @fileIn;
#if($fileIn =~ /\.(tgz|tar\.gz|tar)$/i){
#  use Archive::Tar;
#  my $tar=Archive::Tar->new;
#  $tar->read($finTmp,$fileIn =~ /\.(tgz|tar\.gz)$/i);
#  foreach ($tar->list_files()){
#    my ($fdtmp, $tmp)=tempfile(SUFFIX=>$inputFormat, UNLINK=>1);
#    $tar->extract_file($_, $tmp);
#    push @fileIn, {format=>$inputFormat, file=>$tmp, origFile=>basename($_)};
#    close $fdtmp;
#  }
#}elsif($fileIn=~s/\.zip$//i){
#  eval{
#    require Archive::Zip;
#  };
#  if ($@) {
#    CORE::die "cannot open .zip format (missing Archive::Zip): $@";
#  }
#  my $zip = Archive::Zip->new();
#  CORE::die "ZIP read error in [$finTmp]" unless $zip->read( $finTmp ) == Archive::Zip::AZ_OK;
#  my @members = $zip->members();
#  foreach my $mb (@members) {
#    my ($fdtmp, $tmp)=tempfile(SUFFIX=>$inputFormat, S=>1);
#    $mb->extractToFileNamed($tmp);
#    push @fileIn, {format=>$inputFormat, file=>$tmp, origFile=>basename($mb->externalFileName())};
#    close $fdtmp;
#  }
#} else {
#  if($fileIn=~/\.gz$/i){
#    my (undef , $ftmp)=tempfile(UNLINK=>1);
#    print STDERR "fin=$finTmp\n";
#    InSilicoSpectro::Utils::io::uncompressFile($finTmp, {remove=>0, dest=>$ftmp});
#    $fileIn=~s/\.gz$//i;
#    $fileIn=~s/\.tgz$/.tar/i;
#  }

#  @fileIn=({file=>$finTmp, origFile=>basename($fileIn)});
#}


#my $run=InSilicoSpectro::Spectra::MSRun->new();
#$run->set('defaultCharge', InSilicoSpectro::Spectra::MSSpectra::string2chargemask($defaultCharge));
#$run->set('title', $title);
#$run->set('format', $inputFormat);
#$run->set('origFile', basename $fileIn);
#$run->set('source', $finTmp);

#my $is=0;
#foreach (@fileIn){
#  unless (defined $InSilicoSpectro::Spectra::MSRun::handlers{$inputFormat}{read}) {
#    my %h;
#    foreach (keys %$run) {
#      next if /^spectra$/;
#      $h{$_}=$run->{$_};
#    }
#    my $sp=InSilicoSpectro::Spectra::MSSpectra->new(%h);
#    $sp->{source}=$_->{file};
#    $sp->{origFile}=$_->{origFile};
#    $sp->{title}="$title";
#    $run->addSpectra($sp);
#    $sp->open();
#  } else {
#    CORE::die "not possible to set multiple file in with format [$inputFormat]" if $#fileIn>0;
#    $InSilicoSpectro::Spectra::MSRun::handlers{$inputFormat}{read}->($run);
#  }
#}

my $dest=basename $fileIn;
$dest=~s/\.$inputFormat//i;
$dest.=".$outputFormat";
my $cookie=cookie(-name=>'cgiConvertSpectra.pl',
		  -value=>\%cookies,
		  -expires=>'+100d'
		 );

print $query->header(-type=>'text/plain',
		     -cookie=>$cookie,
		     -attachment=>$dest,
		    );



my $cmdprefix=findCmdPrefix(cmd=>"convertSpectra.pl");

CORE::die "no convertSpectra.pl executable was found in $ENV{PATH}. \nnor in ".dirname($ENV{SCRIPT_FILENAME})."/../; fix your path..." unless defined $cmdprefix;
my $cmd=$cmdprefix."convertSpectra.pl";
my $cmdArgs="--in=$inputFormat:$finTmp ";
$cmdArgs.=" --defaultcharge=\"$defaultCharge\"" if $defaultCharge;
$cmdArgs.=" --title=\"$title\"" if $title;

if($filter_activated){
  my $fc = new InSilicoSpectro::Spectra::Filter::MSFilterCollection();
  $fc->readXmlString($filter);
  my ($fd, $f)=tempfile(UNLINK=>1, SUFFIX=>".filter.xml");
  print $fd $filter;
  close $fd;
  $cmdArgs.=" --filter=$f";
}

$cmdArgs.=" $convertSpectraXtraArgs" if $convertSpectraXtraArgs;

$cmd.=" $cmdArgs --out=$outputFormat:-";
system("$cmd ") && CORE::die "cannot execute $cmd";

#$run->write($outputFormat, \*STDOUT);


sub findCmdPrefix{
  my %hp=@_;
  my $cmd=$hp{cmd}||die "no cmd argument to findCmdPrefix";
  my $opt=$hp{opt}||"--version";
  
  my $cmdtest="$cmd $opt";
  my $ret=`$cmdtest`;
  if ($ret){
  	return "";
  }
  $cmdtest="$^X ".dirname($ENV{SCRIPT_FILENAME})."/../$cmd $opt";
  my $ret=`$cmdtest`;
   if ($ret){
 	return "$^X ".dirname($ENV{SCRIPT_FILENAME})."/../";
  }
  
  $cmdtest="$^X ".dirname($ENV{SCRIPT_FILENAME})."\\..\\$cmd $opt";
  my $ret=`$cmdtest`;
  if ($ret){
  	return "$^X ".dirname($ENV{SCRIPT_FILENAME})."\\..\\";
  }
  return undef;
}


__DATA__
<html>
  <head>
    <title>cgiConvertSpectra.pl - ms/ms peaklist converter</title>
  </head>
  <body>
    <center>
      <h1>cgiConvertSpectra</h1>
      <h3>ms/ms peaklist converter</h3>
    </center>
  <a name="goal"/><h3>Goal</h3>
  This script converts peak list in various formats to other proposed formats.
  <p/>
  If two fragmentation spectra have the same fragment masses, and compatible precursor data, they will be merged automatically and the precursor assigned a multi-charge, e.g. <i>2+ AND 3+</i>.
  <p/>Selections will be stored on the browser via a set of cookies.
  <a name="inputfile"/><h3>Inut File</h3>
  Peak list data, provided in the input format. It is possible to provide compressed <i>.gz</i> or in <i>.tar</i> (or even <i>.tar.gz</i> or <i>.tgz</i>), <i>.zip</i> files.
  <a name="inputformat"/><h3>Input format</h3>
  The list of formats with available <i>read</i> handlers.
  <a name="defaultcharge"/><h3>Default charge</h3>
  In case no default parent charge is given in the input file, the selected charge(s) will be applied to precursors.
  <a name="outputformat"/><h3>Ouput format</h3>
  The list of formats with available <i>write</i> handlers.
  <a name="title"/><h3>Title</h3>
  Some formats allow for a title (ex: the <i>COM</i> line in an mgf file).
  <a name="filter"/><h3>Filter</h3>
  
  You can use a filter to keep only a defined amount of peaks or MSMSCompounds in your file which fullfill certain criterias. You have to use a XML-format to set one or several filters which are described in the following paragraphs. You can find an example at the end of this text:
        	

<pre>
   &lt;ExpMsMsSpectrumFilter&gt;
</pre>

You can have several <i>oneExpMsMsSpectrumFilter</i> in <i>ExpMsMsSpectrumFilter</i> each of the filters will be processed consecutively.
You can choose between <i>spectrumType</i> "msms" and "ms". Usually you have to use "msms";

<pre>
   &lt;oneExpMsMsSpectrumFilter spectrumType="msms" name="dummy"&gt;
</pre>

The level on which the filter will be applied can be either <i>msmsCompounds</i> or <i>peaks</i>. Most filters can only be applied on one of the two levels. 

<pre>
   &lt;level&gt;peaks&lt;/level&gt;         
   &lt;action type="removeOther"&gt;
</pre>

The action-type can be <!--"label", -->"removeOther", "remove" and "algorithm"<!--. Using "label" you can set a label for the selected msmsCompounds (you cannot label peaks)-->:


<!--
<pre>
    &lt;action type="label"&gt;
        &lt;labelValue&gt;%.3f&lt;/labelValue&gt;   
	&lt;labelName&gt;some name&lt;/labelName&gt;
</pre>
  
The <i>labelValue</i> is the resulting value of the filter for each compound. The result can be formated using the printf-perl-syntax.
-->


Use "removeOther" - to keep just the selected peaks or msmsCompounds - and "remove" to remove the selected ones. "algorithm" leaves it up to the algorithm to take off or change the peaks/peak-intensities. "algorithm" can only be set for the filters "banishNeighbors" and "smartPeaks".<br> 


You can choose which part of the msmsCompounds or peaks should be selected to apply the <i>action</i> on. <i>relativeTo</i> can have the values <i>nFix</i>, <i>absValue</i>, <i>relMax</i> and <i>quantile</i>. The <i>comparator</i> can be <i>ge</i> , <i>gt</i>, <i>le</i> and <i>lt</i>. Using the three parameters <i>relativeTo</i>, <i>thresholdValue</i> and <i>comparator</i> you can choose a certain part of msmsCompounds/peaks to select. 


<pre>
               &lt;threshold type="sort"&gt;	
			   &lt;relativeTo&gt;nFix&lt;/relativeTo&gt; 
                           &lt;thresholdValue&gt;100&lt;/thresholdValue&gt;
			   &lt;comparator&gt;ge&lt;/comparator&gt;
               &lt;/threshold&gt;

</pre>



The type of the filters can be either "directValue" for directly accessible information of the spectra and <i>algorithm</i> for the more complex algorithms. 

<pre>
     &lt;/action&gt;
      &lt;filterValue type="directValue"&gt;

                &lt;name&gt;fragment.intensity&lt;/name&gt;
</pre>

you can choose which type of spectra-values can be used. You can choose either the <i>intensity</i> or <i>moz</i> of the <i>fragments</i> (only on level <i>peaks</i>) or the <i>precursor</i> (only on level <i>msmsCompounds</i>). <i>size</i> gives back the number of peaks in a compound and can only be applied on the level <i>msmsCompounds</i>. <i>sum</i> summs up the fragment values of choice.  

The filterValue type <i>algorithm</i> uses more complex filter algorithms

For <i>balance</i> the moz-range (between minMoz and maxMoz) of the spectra is divided into the number of <i>bands</i>. For each band the total raw intensity is calculated ant the standard deviation between the bands is the resulting value. 

<pre>
      &lt;filterValue type="algorithm"&gt; 
                &lt;name&gt;balance&lt;/name&gt;
                &lt;param name="bands"&gt;10&lt;/param&gt;    
                &lt;param name="minMoz"&gt;300&lt;/param&gt;    this parameter isn't mandatory   
                &lt;param name="maxMoz"&gt;900&lt;/param&gt;    this parameter isn't mandatory   
      &lt;/filterValue&gt;                   
</pre>


The algorithm <i>smartPeaks</i> change the probability for peaks of regions of low intensities and/or only a few peaks to be selected. If you use the action type="algorithm" the intensities of the fragments in the spectra are changed. 

<pre>
            &lt;name&gt;smartPeaks&lt;/name&gt;
            &lt;param name="winSize"&gt;100&lt;/param&gt;
            &lt;param name="stepSize"&gt;20&lt;/param&gt;
            &lt;param name="weightIntensity"&gt;0.8&lt;/param&gt;
            &lt;param name="weightDensity"&gt;1&lt;/param&gt;
</pre>


The sum of all normalized peaks which have the distance of one of the 20 amino-acids. You can set a tolerance and which type of mass (<i>mono</i> or <i>average</i>) to use. 

<pre>
            &lt;name&gt;goodDiff.normRank&lt;/name&gt;
            &lt;param name="tolerance"&gt;0.37&lt;/param&gt;
            &lt;param name="toleranceUnit"&gt;Da&lt;/param&gt;
            &lt;param name="mass"&gt;mono&lt;/param&gt;
</pre>
                        

You can directly choose a maximal number of peaks to consider:


<pre>
            &lt;param name="filter"&gt;intensity&lt;/param&gt;
            &lt;param name="peakNr"&gt;50&lt;/param&gt;
</pre>


Or you use <i>smartPeaks</i> to increase the probability to choose peaks in regions of low intensities. 


<pre>
            &lt;param name="filter"&gt;smartPeaks&lt;/param&gt;
            &lt;param name="peakNr"&gt;50&lt;/param&gt;
            &lt;param name="winSize"&gt;100&lt;/param&gt;
            &lt;param name="stepSize"&gt;20&lt;/param&gt;
            &lt;param name="weightIntensity"&gt;0.8&lt;/param&gt;
            &lt;param name="weightDensity"&gt;1&lt;/param&gt;
</pre>


<i>waterLosses</i> sums up the peaks having the distance of water (18 Da). <i>Complements</i> sums up the peaks which sums up to the moz-value of the precursor-ion considering the possible charge states. The syntax is the same as for <i>goodDiff</i>.


<i>banishNeighbors</i> can be used to take off small peaks near strong peaks. <i>selectStrongest</i> indicates the percentage of the peaks to be considered as strong ones. The peaks in the <i>banishRange</i> of a strong peak not bigger than <i>banishLimit</i> of the highest peak in this range are prepared to be taken off. Either you can use action type="removeOther" and level="peaks" to take of the amount of peaks you want. If you use the action type="algorithm" all the peaks which fulfill the condition are taken off and spectra with less than "skipSpectraBelow" peaks are skipped.  

<pre>
            &lt;name&gt;banishNeighbors&lt;/name&gt;
            &lt;param name="selectStrongest"&gt;0.8&lt;/param&gt;
            &lt;param name="banishRange"&gt;0.5&lt;/param&gt;
            &lt;param name="banishLimit"&gt;0.9&lt;/param&gt;
            &lt;param name="rangeUnit"&gt;Da&lt;/param&gt;
            &lt;param name="skipSpectraBelow"&gt;100&lt;/param&gt;


	&lt;/oneExpMsMsSpectrumFilter&gt;
   &lt;/ExpMsMsSpectrumFilter&gt;
</pre>


<h3>Example of a filter</h3>

You can process a spectrum successively by several filters. <i>banishNeighbors</i> is applied only on compounds containing at least 100 fragments. The 100 strongest peaks of each compound are kept and the 10% percent of all compounds with the lowest goodDiff-score are deleted<br>

<pre>
&lt;ExpMsMsSpectrumFilter&gt;
        &lt;oneExpMsMsSpectrumFilter spectrumType="msms" name="dummy"&gt;
	        &lt;level&gt;peaks&lt;/level&gt;	
		&lt;action type="algorithm"&gt;
                &lt;/action&gt;
		&lt;filterValue type="algorithm"&gt;	
                        &lt;name&gt;banishNeighbors&lt;/name&gt;
                        &lt;param name="selectStrongest"&gt;0.2&lt;/param&gt;
                        &lt;param name="banishRange"&gt;0.5&lt;/param&gt;
                        &lt;param name="banishLimit"&gt;0.8&lt;/param&gt;
                        &lt;param name="rangeUnit"&gt;Da&lt;/param&gt;
                        &lt;param name="skipSpectraBelow"&gt;100&lt;/param&gt;
	       &lt;/filterValue&gt;
	&lt;/oneExpMsMsSpectrumFilter&gt;


        &lt;oneExpMsMsSpectrumFilter spectrumType="msms" name="dummy"&gt;
	        &lt;level&gt;peaks&lt;/level&gt;	
		&lt;action type="removeOther"&gt;		
		       &lt;threshold type="sort"&gt;	
			   &lt;relativeTo&gt;nFix&lt;/relativeTo&gt;							
			   &lt;thresholdValue&gt;100&lt;/thresholdValue&gt;
			   &lt;comparator&gt;ge&lt;/comparator&gt;						
		       &lt;/threshold&gt;
                &lt;/action&gt;
		&lt;filterValue type="directValue"&gt;							
			&lt;name&gt;fragment.intensity&lt;/name&gt;						
		&lt;/filterValue&gt;
	&lt;/oneExpMsMsSpectrumFilter&gt;


        &lt;oneExpMsMsSpectrumFilter spectrumType="msms" name="dummy"&gt;
	        &lt;level&gt;msmsCompounds&lt;/level&gt;	
		&lt;action type="removeOther"&gt;		
		       &lt;threshold type="sort"&gt;	
			   &lt;relativeTo&gt;quantile&lt;/relativeTo&gt;							
			   &lt;thresholdValue&gt;0.1&lt;/thresholdValue&gt;
			   &lt;comparator&gt;ge&lt;/comparator&gt;						
		       &lt;/threshold&gt;
                &lt;/action&gt;
		&lt;filterValue type="algorithm"&gt;	
	                &lt;name&gt;complements.normRank&lt;/name&gt;
                        &lt;param name="tolerance"&gt;0.4&lt;/param&gt;
                        &lt;param name="toleranceUnit"&gt;Da&lt;/param&gt;
                        &lt;param name="mass"&gt;average&lt;/param&gt;
                        &lt;param name="filter"&gt;intensity&lt;/param&gt;
                        &lt;param name="peakNr"&gt;50&lt;/param&gt;
 		&lt;/filterValue&gt;
	&lt;/oneExpMsMsSpectrumFilter&gt;


&lt;/ExpMsMsSpectrumFilter&gt;
</pre>








  <body>
</html>
