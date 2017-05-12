#!/usr/bin/env perl
use strict;
use Carp;
use Pod::Usage;

=head1 NAME

convertSpectra.pl


=head1 DESCRIPTION

Converts ms and msms peaklist from/to various formats. Formats can be specified or will hopefully be deduced from the files extensions

=head1 SYNOPSIS

convertSpectra.pl --in=[format:]file --out=[format:]file

=head1 ARGUMENTS

=over 4

=item -in=[format:]file

If the format is not idj, this parameter can be repeated

=item -out=[format:]file

=back

If no files are specified (thus the format must be) I/O are stdin/out.

=head1 OPTIONS

=over 4

=item --defaultcharge=charge

Defined a default charge for the precursor (msms) of the peak (ms) (it might be overwritten if the input file definesit explicitely. The charge argument can be something like '1+', '1', '2,3', '2+ AND 3+' etc.

=item --forcedefaultcharge

Will force the default charge defined into the file to be replaced

=item --title=string

Allows for setting a title (one line text)

=item --filter=file

Allows for using a filter. See 'InSilicoSpectro/t/Spectra/Filter/examples.xml' for more information.

=item --sampleinfo='name1=val1[;name2=val2[...]]'

Set sample related info example 'instrument=QTOF;instrumentId=xyz'

=item --trustprecursorcharge=medium

turn 2+ and 3+ precursor  into (2+ OR 3+)

=item --trustprecursorcharge=1:1/2:2,3/3:2,3,4

(or similar) will attribute 1+=>1+, 2+=>2+ or 3+, 3+=>2+,3+ or 4+.

=item --duplicateprecursormoz=i1:i2

If for example i1=-1 and i2=2, precursor moz will be replicate with -1, +1 and +2 Dalton

=item --skip=[msms|pmf]

Do not read msms or pmf information

=item --showinputformats

Prints all the possible format for input

=item --showoutputformats

Prints all the possible format for output

=item --showformats=(xml|json)

=item --showdef=[xml|json]

report all possible input/ouput format + relative info (optional/compulsory arguements...)

=item --propertiessave=file

=item --propertiesprefix=string

=item --usefilecaching

activates a caching system for large files

=item --version

=item --help

=item --man

=item --verbose

=back


=head1 EXAMPLE

./convertSpectra.pl --in=dta:somedir --out=somefile.idj.xml

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

use Getopt::Long;
use File::Basename;
use File::Spec qw(tempfile tempdir);
use File::Temp;
use Archive::Tar;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS);

my(@fileIn, $fileOut, $showInputFmt, $showOutputFmt, $showDef, $sampleInfo, $precursorTrustParentCharge, $defaultCharge, $forceDefaultCharge, $title, $fileFilter, $dpmStr, @skip, $doNotMergePrecursors,
   $excludeKeysFile,
   $propertiesFile,$propertiesPrefix,
   $useFileCache,
   $phenyxConfig, $help, $man, $verbose, $showVersion);

use InSilicoSpectro;
use InSilicoSpectro::Utils::io;

if (!GetOptions(
		"in=s@"=>\@fileIn,
		"out=s"=>\$fileOut,
		"sampleinfo=s"=>\$sampleInfo,
		"showinputformats"=>\$showInputFmt,
		"showoutputformats"=>\$showOutputFmt,
		"showdef=s"=>\$showDef,

		"duplicateprecursormoz=s"=>\$dpmStr,
		"donotmergeprecursors"=>\$doNotMergePrecursors,
		"trustprecursorcharge=s"=>\$precursorTrustParentCharge,
		"defaultcharge=s"=>\$defaultCharge,
		"forcedefaultcharge"=>\$forceDefaultCharge,
		"title=s"=>\$title,

		"excludekeysfile=s"=>\$excludeKeysFile,

		"filter=s"=>\$fileFilter,

		"propertiessave=s"=>\$propertiesFile,
		"propertiesprefix=s"=>\$propertiesPrefix,

		"usefilecaching"=>\$useFileCache,

		"skip=s@"=>\@skip,
		"phenyxconfig=s" => \$phenyxConfig,


                "version" => \$showVersion,
                "help" => \$help,
                "man" => \$man,
                "verbose" => \$verbose,
               )
    || $help || $man || $showVersion || (((not @fileIn) || (not $fileOut)) and  (not $showInputFmt) and (not $showOutputFmt) and (not $showDef))){

  if($showVersion){
    print basename($0)." InSilicoSpectro version $InSilicoSpectro::VERSION\n";
    exit(0);
  }

  pod2usage(-verbose=>2, -exitval=>2) if(defined $man);
  pod2usage(-verbose=>1, -exitval=>$help?0:2);
}

my %sampleInfo;
foreach(split /;/, $sampleInfo){
  my($n, $v)=split /=/, $_, 2;
  $sampleInfo{$n}=$v;
}

#CORE::die "invalid --trustprecursorcharge=(medium)" if $precursorTrustParentCharge and $precursorTrustParentCharge !~ /^(medium)$/;

use InSilicoSpectro::Spectra::MSRun;
use InSilicoSpectro::Spectra::MSSpectra;
use InSilicoSpectro::Spectra::Filter::MSFilterCollection;

#FIXME REMOOVE!
$InSilicoSpectro::Spectra::MSMSSpectra::MERGE_MULTIPLE_PREC_CHARGES=0 if $doNotMergePrecursors;

$InSilicoSpectro::Spectra::MSSpectra::USE_FILECACHED=1 if $useFileCache;
InSilicoSpectro::Utils::FileCached::verbose($verbose);

$InSilicoSpectro::Utils::io::VERBOSE=$verbose;

if ((defined $showInputFmt) or (defined $showOutputFmt)) {
  if (defined $showInputFmt) {
    print "input formats MS/MS: ".(join ',',(InSilicoSpectro::Spectra::MSRun::getReadFmtList(), InSilicoSpectro::Spectra::MSMSSpectra::getReadFmtList()))."\n";
  }
  if (defined $showOutputFmt) {
    print "output formats MS/MS: ".(InSilicoSpectro::Spectra::MSRun::getWriteFmtList(), InSilicoSpectro::Spectra::MSMSSpectra::getWriteFmtList())."\n";
  }
  exit(0);
}

if($showDef){
  getDef(out=>$showDef);
  exit(0);
}

my $run=InSilicoSpectro::Spectra::MSRun->new();
$run->set('defaultCharge', InSilicoSpectro::Spectra::MSSpectra::string2chargemask($defaultCharge));
$run->set('title', $title);

@skip = split(/,/,join(',',@skip));
foreach (@skip) {
  $_=lc $_;
  s/^ms$/pmf/;
  $run->{read}{skip}{$_}=1;
}
my $is=0;

#explodes @file into glob + archive stuff...
my @tmpFileIn;

foreach (@fileIn) {
  s/ /\\ /g;
  foreach my $fi (glob $_) {
    push @tmpFileIn, $fi;
  }
}
undef @fileIn;
while (my $fileIn=shift @tmpFileIn){
  my ($format, $source);
  if ($fileIn=~/(.*?):(.*)/) {
    ($format, $source)=(lc($1), $2);
  } else {
    ($format, $source)=(InSilicoSpectro::Spectra::MSRun::guessFormat($fileIn), $fileIn);
  }
  my $tmpdir=File::Spec->tmpdir;
  if($source=~/\.(tar|tar\.gz|tgz)$/i && $format ne 'dta'){
    my $tar=Archive::Tar->new;
    $tar->read($source, $source =~ /gz$/i);
    foreach ($tar->list_files()){
      my ($fdtmp, $tmp)=File::Temp::tempfile(SUFFIX=>$format, UNLINK=>1);
      $tar->extract_file($_, $tmp);
      push @fileIn, {format=>$format, file=>$tmp, origFile=>basename($_)};
      close $fdtmp;
    }
  }elsif($source=~/\.zip$/i && $format ne 'dta'){
    my $zip=Archive::Zip->new();
    unless($zip->read($source)==AZ_OK){
      CORE::die "zip/unzip: cannot read archive $source";
    }else{
      my @members=$zip->members();
      foreach (@members){
	my (undef, $tmp)=File::Temp::tempfile("$tmpdir/".(basename($_->fileName())."-XXXXX"), UNLINK=>1);
	$zip->extractMemberWithoutPaths($_, $tmp) && croak "cannot extract ".$_->fileName().": $!\n";
	push @fileIn, {format=>$format, file=>$tmp, origfile=>$_->fileName()};
      }
    }
    next;
  }elsif($source=~/(.*)\.gz$/i){
    my $base=$1;
    my (undef, $tmp)=File::Temp::tempfile(DIR=>$tmpdir, SUFFIX=>basename($base), UNLINK=>1);
    $source=InSilicoSpectro::Utils::io::uncompressFile($source, {remove=>0, dest=>$tmp});
    push @tmpFileIn, "$format:$source";
    next;
  }

  push @fileIn, {format=>$format, file=>$source, origFile=>$source};
}

foreach (@fileIn) {
  my ($inFormat, $src, $origFile)=($_->{format}, $_->{file}, $_->{origFile});
  $run->set('format', $inFormat);
  $run->set('source', $src);
  $run->set('origFile', $origFile);
  if((defined $InSilicoSpectro::Spectra::MSRun::autoDetectFormatHandlers{$inFormat})){
    my $tmp = $InSilicoSpectro::Spectra::MSRun::autoDetectFormatHandlers{$inFormat}{read}->($src);
    die "cannot auto detect [$inFormat] from $src" unless $tmp;
    $inFormat=$tmp;
    $run->set('format', $inFormat);
  }
  unless (defined $InSilicoSpectro::Spectra::MSRun::handlers{$inFormat}{read}) {
    my %h;
    foreach (keys %$run) {
      next if /^spectra$/;
      $h{$_}=$run->{$_};
    }
    my $sp=InSilicoSpectro::Spectra::MSSpectra->new(%h);
    $run->addSpectra($sp);
    $sp->set('sampleInfo', \%sampleInfo) if defined %sampleInfo;
    $sp->origFile($origFile);
    $sp->setSampleInfo('sampleNumber', $is++);
    $sp->open(forcedefaultcharge=>$forceDefaultCharge);
    $run->set('defaultCharge', $run->get('defaultCharge')||$sp->get('defaultCharge'));
  } else {
    croak "not possible to set multiple file in with format [$inFormat]" if $#fileIn>0 and ! $InSilicoSpectro::Spectra::MSRun::handlers{$inFormat}{readMultipleFile};
    $InSilicoSpectro::Spectra::MSRun::handlers{$inFormat}{read}->($run);
  }
}

if($excludeKeysFile){
  my %xKeys;
  open (FD, "<$excludeKeysFile") or CORE::die "cannot open for reading [$excludeKeysFile] :$!";
  while (<FD>){
    chomp;
    s/\#.*//;
    s/\s+$//;
    next unless /\S/;
    $xKeys{$_}=1;
  }
  close FD;
  my $imax=$run->getNbSpectra()-1;
  my $i=0;
  while ($i<=$imax){
    my $sp=$run->getSpectra($i);
    if($xKeys{$sp->get('key')}){
      $run->removeSpectra($i);
      $i--;
      $imax;
    }else{
      next unless ref($sp) eq 'InSilicoSpectro::Spectra::MSMSSpectra';
      my $jmax=$sp->size()-1;
      my $j=0;
      while ($j<=$jmax){
	my $cmpd=$sp->get('compounds')->[$j];
	if($xKeys{$cmpd->get('key')}){
	  print STDERR "remove $j\n";
	  splice @{$sp->get('compounds')}, $j, 1;
	  $j--;
	  $jmax--;
	}
	$j++;
      }
    }
    $i++;
  }
}


#to filter the spectra
if ($fileFilter) {
  my $fc = new InSilicoSpectro::Spectra::Filter::MSFilterCollection();
  $fc->readXml($fileFilter);
  $fc->filterSpectra($run);
  use Data::Dumper;
  print Dumper ($run);
}

if ($precursorTrustParentCharge){
  my %charge2trust;
  if ($precursorTrustParentCharge eq 'medium') {
    %charge2trust=(
		   2=>4+8,
		   3=>4+8,
		  );
  } elsif ($precursorTrustParentCharge=~/\d+:\d+/) {
    foreach(split/\//, $precursorTrustParentCharge){
      CORE::die "[$_] does not fit /\d+:\d+[</\d+[...]]/" unless /^(\d+):([\d,]+)$/;
      my $c=$1;
      my $l=$2;
      $charge2trust{$c}=0;
      foreach (split /,/, $l){
	$charge2trust{$c}|=(1<<$_);
      }
    }
  } else {
    CORE::die "unknow --trustprecursorcharge"
  }

  my $origpd_cmask;
  my $alterpd_charge;
  my $imax=$run->getNbSpectra()-1;
  foreach my $i (0..$imax) {
    my $sp=$run->getSpectra($i);
    next unless ref($sp) eq 'InSilicoSpectro::Spectra::MSMSSpectra';
    my $jmax=$sp->size()-1;
    for my $j (0..$jmax) {
      my $cmpd=$sp->get('compounds')->[$j];
      my $ipdcmask=$cmpd->get('parentPD')->getFieldIndex('chargemask');
      unless(defined $ipdcmask){
	my $ipdcharge=$cmpd->get('parentPD')->getFieldIndex('charge') or CORE::die "neither charge not chargemask is defined for cmpd parent \n$cmpd";
	if ($cmpd->get('parentPD')."" ne "$origpd_cmask") {
	  $origpd_cmask=$cmpd->get('parentPD');
	  $alterpd_charge=InSilicoSpectro::Spectra::PhenyxPeakDescriptor->new($origpd_cmask);
	  $alterpd_charge->getFields()->[$ipdcharge]='chargemask';
	  $ipdcmask=$ipdcharge;
	} else {
	  $alterpd_charge=$cmpd->get('parentPD');
	  $ipdcmask=$ipdcharge;
	}
      }
      my $cmask=$cmpd->getParentData()->[$ipdcmask];
      foreach (0..31){
	next unless $cmask & (1<<$_);
	$cmpd->getParentData()->[$ipdcmask]|=$charge2trust{$_};
      }
#      $cmpd->getParentData()->[$ipdcmask]|= (1<<3) if $cmpd->getParentData()->[$ipdcmask] & (1<<2);
#      $cmpd->getParentData()->[$ipdcmask]|= (1<<2) if $cmpd->getParentData()->[$ipdcmask] & (1<<3);
    }
  }
}
if($dpmStr){
  my $el_hplus;
  eval{
    use InSilicoSpectro;
    InSilicoSpectro::init();
    $el_hplus=InSilicoSpectro::InSilico::MassCalculator::getMass('el_H+');
  };
  if($@){
    $el_hplus=1.00728;
  }
  CORE::die "invalid value [$dpmStr] insteadd of --duplicateprecursormoz=i1:i2" unless $dpmStr=~/^([\-\d]+):([\-\d]+)$/;
  my ($min, $max)=($1, $2);
  my $imax=$run->getNbSpectra()-1;

  my $origpd_cmask;
  my $alterpd_charge;
  my $cmpdNumber=0;
  foreach my $i(0..$imax){
    my $sp=$run->getSpectra($i);
    next unless ref($sp) eq 'InSilicoSpectro::Spectra::MSMSSpectra';
    my $jmax=$sp->size()-1;
    for my $j (0..$jmax){
      my $cmpd=$sp->get('compounds')->[$j];

      my @charges=$cmpd->precursor_charges();
      CORE::die "cannot duplicate with undefined precursor charges" unless @charges;
      foreach my $c(@charges){
	my $ipdcharge=$cmpd->get('parentPD')->getFieldIndex('charge');
	unless(defined $ipdcharge){
	  my $ipdcmask=$cmpd->get('parentPD')->getFieldIndex('chargemask') or CORE::die "neither charge not chargemask is defined for cmpd parent \n$cmpd";
	  if($cmpd->get('parentPD')."" ne "$origpd_cmask"){
	    $origpd_cmask=$cmpd->get('parentPD');
	    $alterpd_charge=InSilicoSpectro::Spectra::PhenyxPeakDescriptor->new($origpd_cmask);
	    $alterpd_charge->getFields()->[$ipdcmask]='charge';
	    $ipdcharge=$ipdcmask;
	  }else{
	    #$alterpd_charge=$cmpd->get('parentPD');
	    $ipdcharge=$ipdcmask;
	  }
	}
	foreach my $shift($min..$max){
	  next if $shift==0;
	  my $newcmpd=InSilicoSpectro::Spectra::MSMSCmpd->new($cmpd);
	  $newcmpd->{compoundNumber}=$cmpdNumber++;
	  delete $newcmpd->{key};
	  my @prec=@{$cmpd->getParentData()};
	  $newcmpd->setParentData(\@prec);
	  $newcmpd->set('parentPD', $alterpd_charge);
	  $prec[$ipdcharge]=$c;
	  $prec[0]+=$el_hplus*$shift/$c;
	  $newcmpd->title(($cmpd->title() || "")." [charge=$c+, ".(($shift>0)?"+":"")."$shift isotope]");
	  $sp->addCompound($newcmpd);

	}
      }
    }
  }
}

my ($outformat, $outfile);
if ($fileOut=~/(.*?):(.*)/) {
  $outformat=$1;
  $outfile=($2 or \*STDOUT);
} else {
  $outfile=$fileOut;
  $outformat=InSilicoSpectro::Spectra::MSSpectra::guessFormat($outfile);
}

# use Data::Dumper;
# $Data::Dumper::Maxdepth=3;
# print Dumper($run);
# use Devel::Size qw(size total_size);

# InSilicoSpectro::Utils::FileCached::dump_all();

# print "mrun total_size=".total_size($run)."\n";


$run->write($outformat, ">$outfile");

if($propertiesFile){
  require Util::Properties;
  my $prop=Util::Properties->new();
  $propertiesPrefix.="." if $propertiesPrefix && $propertiesPrefix!~/\.$/;
  $prop->file_name($propertiesFile);

  #count nb frag spectra.
  my $nbFragSp=0;
  my $imax=$run->getNbSpectra()-1;
  foreach my $i(0..$imax){
    my $sp=$run->getSpectra($i);
    next unless ref($sp) eq 'InSilicoSpectro::Spectra::MSMSSpectra';
    $nbFragSp+=$sp->size();
  }
  $prop->prop_set($propertiesPrefix."msms.nbcompounds", $nbFragSp);
  

}
sub getDef{
  my %hparams=@_;
  my $out=$hparams{out} || 'xml';


  my %ret=(
	   input=>[],
	   output=>[],
	   version=>$InSilicoSpectro::VERSION,
	   #might add some compulsory attribute if needed
	   extraargs=>[
			  {
			   key=>'duplicateprecursormoz',
			   description=>['it is possible to duplicate precursor moz for example "-1,1,2,3", when tolearance is small but isotope error are suspected'],
			   shortdescription=>['dupplicate prec. m/z'],
			   type=>'String',
			   regexp=>['([\+\-]?\d+,)*[+\-]?\d+'],
			   level=>3,
			  },
			  {
			   key=>'defaultcharge',
			   description=>['precursor default charge, to be assigned when no precursor is defined for a given ion'],
			   shortdescription=>['prec. defaut charge'],
			   type=>'Select',
			   choices=>['1+', '2+', '2+ AND 3+', '3+'],
			   level=>1,
			   default=>['2+ AND 3+'],
			  },
			  {
			   key=>'title',
			   shortdescription=>['title'],
			   description=>['run general title'],
			   type=>'String',
			   level=>1,
			   compulsory=>1,
			   default=>['no title'],
			  },
			  {
			   key=>'filter',
			   shortdescription=>['peaklist filter'],
			   description=>['a configuration file to filter peaklist'],
			   type=>'File',
			   level=>3,
#			   compulsory=>0,
			   default=>[''],
			  },
			  {
			   key=>'usefilecaching',
			   shortdescription=>['use file caching'],
			   description=>['activates a memory usage control system - a CPU time cost'],
			   type=>'Flag',
			   level=>3,
#			   compulsory=>1,
			   default=>undef,
			  },
			 ],
	   );
  
  while (my ($key, $h)=each %handlers){
    if($h->{read}){
      my %h1;
      $h1{description}=[$h->{description}||""];
      $h1{type}=$key;
      $h1{aggregateruns}=[$h->{readMultipleFile}||0||'no'];
      $h1{containsmultipleruns}=['no'];
      push @{$ret{input}}, \%h1
    }
    if($h->{write}){
      my %h1;
      $h1{description}=[$h->{description}||""];
      $h1{mimetype}=[$h->{mimetype}||"text/plain"];
      $h1{type}=$key;
      push @{$ret{output}}, \%h1
    }
  }
  while (my ($key, $h)=each %InSilicoSpectro::Spectra::MSMSSpectra::handlers){
    if($h->{read}){
      my %h1;
      $h1{description}=[$h->{description}||""];
      $h1{type}=$key;
      $h1{aggregateruns}=['yes'];
      $h1{containsmultipleruns}=['no'];
      push @{$ret{input}}, \%h1
    }
  }
  if($out eq 'xml'){
    require XML::Simple;
    my $xs = XML::Simple->new;
    print $xs->XMLout(\%ret,
		      KeyAttr=>{input=>'+key'},
		      KeyAttr=>{output=>'+key'},
		      GroupTags=>{
				  extraargs=>"oneExtraArg",
				  input=>"oneinput",
				  output=>"oneoutput",
				  choices=>'oneChoice',
				 },
		      RootName=>'InSilicoSpectroFormats',
		     );
    return;
  }
  die "out [$out] is not defined";
}
