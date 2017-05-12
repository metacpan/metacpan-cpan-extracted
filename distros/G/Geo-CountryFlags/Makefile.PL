use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $pkg = 'Geo::CountryFlags';
$pkg =~ /[^:]+$/;
my $module = $& .'.pm';

WriteMakefile(
    'NAME'		=> $pkg,
    'PREREQ_PM'		=> {	'LWP::Simple'	=> '0',
				'File::SafeDO'	=> 0.11,
			},
    'VERSION_FROM'	=> $module, 	# finds $VERSION
    'dist'		=> {COMPRESS=>'gzip', SUFFIX=>'gz'},
    'clean'		=> {FILES => "tmp* *~ ${lib}/*~"},
    'realclean'		=> {FILES => $checked},
);

(my $lib = $pkg) =~ s|::|/|g;
$lib = 'lib/'. $lib;

require $lib .'/Util.pm' or die "${lib}/Util missing from package or could not load\n";
my $pku = $pkg . '::Util';

# local files
my $validurls	= './Valid_Urls';
my $exceptions	= './Map_Exceptions';
my $checked	= './data_checked';
my $updatexref	= 0;

# check that url's are up to date

if ($pku->is_obsolete($validurls,$lib .'/URLs.pm') &&
    (my $gcu = $pku->url_fetch() or die "could not open $validurls\n")) {
  $gcu->mkmodule('URLs');
  $updatexref = 1;
}

require $lib .'/URLs.pm' or die "${lib}/URLs.pm failed to load\n";
my $pkr = $pkg .'::URLs';

# check that exceptions are upd to date
if ($pku->is_obsolete($exceptions,$lib .'/XCPs.pm') &&
    (my $gcx = $pku->xcp_fetch() or die "could not open $exceptions\n")) {
  $gcx->mkmodule('XCPs');
  $updatexref = 1;
}

# see if there is a forced check
unless (-e $checked) {			# skip forced check
  if (my $gcc = $pku->cia_fetch($pkr->CIA)) {
    $gcc->mkmodule('CIA');
    $updatexref = 1;
  }
  else {
    print "WARNING: could not access\n", $pkr->CIA,"\n";
  }
  if (my $gci = $pku->iso_fetch($pkr->ISO)) {
    $gci->mkmodule('ISO');
    $updatexref = 1;
  }
  else {
    print "WARNING: could not access\n", $pkr->ISO,"\n";
  }
# update the 'checked' file
  local *CHKD;
  open (CHKD,'>'. $checked) or die "could not open $checked\n";
  close CHKD;
}

unless (-e $lib .'/CIA.pm') {
  my $gcc = $pku->cia_fetch or die "could not access\n", $pkr->CIA,"\n";
  $gcc->mkmodule('CIA');
  $updatexref = 1;
}

unless (-e $lib .'/ISO.pm') {
  my $gci = $pku->iso_fetch or die "could not access\n", $pkr->ISO,"\n";
  $gci->mkmodule('ISO');
  $updatexref = 1;
}

my($excp,$flag,$real);

sub formprt {
  my($rk,$k) = @_;
  foreach (sort keys %$rk) {
    $excp = $_;
    $flag = $rk->{$excp};
    $real = $k->{$flag};
    write;
  }
}

if ($updatexref || ! -e $lib .'/I2C.pm') {
  $updatexref = 1;
  require $lib .'/XCPs.pm' or die "${lib}/XCPs.pm failed to load\n";
  require $lib .'/CIA.pm' or die "${lib}/CIA.pm failed to load\n";
  require $lib .'/ISO.pm' or die "${lib}/ISO.pm failed to load\n";
  my $pkx = $pkg .'::XCPs';
  my $pkc = $pkg .'::CIA';
  my $pki = $pkg .'::ISO';

  my $xcp = $pkx->hashptr($pku);	# get exceptions
  my $gci = $pki->hashptr($pku);	# get ISO
  my $gcc = $pkc->hashptr($pku);	# get CIA
  my $rgci = $gci->revcomp;	# rev/compress ISO hash
  my $rgcc = $gcc->revcomp;	# rev/compress CIA hash  

  $rgci->mapexceptions($xcp);		# map exceptions into ISO hash
  my $cr = $rgci->matcheq($rgcc);	# match up all easy place names
  $rgci->parsBYword($rgcc,$cr);		# match up similar place names
  $cr->mkmodule('I2C');		# make the cross reference module

  format STDOUT =
@<<<<<<<<<<<<<<<<<<<<<<<<<< => @|| => @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$excp, $flag, $real   
.

  print "\nremaining ISO's\n";
  formprt($rgci,$gci);
 
  print "\nremaining CIA's\n";
  formprt($rgcc,$gcc);
}

if ($updatexref) {		# update the flags and MANIFEST
  require './CountryFlags.pm' or die "$pkg is broken, comment out this line a debug\n";
  print "\nplease wait... updating ./flags directory\n";
  foreach(keys %$cr) {
    $pkg->get_flags($_);
  }

  if (-d 'flags') {
    local(*M,*MI,*D);
    opendir(D,'flags') or die "could not read ./flags directory\n";
    my @flags = grep(!/^\./,readdir(D));
    closedir D;
    if (@flags) {
      print "\nre-writing MANIFEST\n\n";
      open(MI,'MANIFEST.in') or die "could not open MANIFEST.in\n";
      unless (open(M,'>MANIFEST')) {
	close MI;
	die "could not open MANIFEST for write\n";
      }
      {
	undef local $/;
	$_ = <MI>;
	close MI;
      }
      print M $_;
      foreach(sort @flags) {
	print M 'flags/',$_,"\n";
      }
      close M;
    }
  }
}

1;
