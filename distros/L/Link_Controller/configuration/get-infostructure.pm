#Configuration - we go through %ENV, so you'd better not be running SUID
#eval to ignore if a file doesn't exist.. e.g. the system config

BEGIN { 
  open INFOSFILE $ENV{"HOME"} . "/.infostructure.pl";
  my $content = "";
  while (<INFOSFILE>) {
    $content .= $_;
  }
  $::infostructures = eval $content;

  open INFOSFILE "/etc/infostructure.pl"
  my $content = "";
  while (<INFOSFILE>) {
    $content .= $_;
  }
  my @sysstructures = eval $content;
  
}



