{package LibZip::TMP ;

if ( $ARGV[0] eq '-bin' ) {

    print qq`_____________________________________________________________

TinyPerl 3.0 - Generate Binary
_____________________________________________________________

`;

  if ($#ARGV <= 1) {
    print qq`To create a binary for your script type:

  \$> tinyperl -bin script.pl newfile.exe

  OPTIONS:
  -gui      Create a non console executable.

Copyright (c) 2003-2005 Graciliano M. P. <gmpassos\@cpan.org>
_____________________________________________________________

`;
    exit ;
  }
  else {
    my $script = $ARGV[-2] ;
    my $binary = $ARGV[-1] ;
    
    if (!-e $script) { die "** Can't find script: $script\n" ;}
    if ($binary !~ /^[\w\.]+$/) { die "** Invalid name: $binary\n" ;}
    
    eval(q`use Config ;`);

    my $ext = $Config{exe_ext} ;
    if ( $binary !~ /\Q$ext\E$/i && $ext) { $binary .= $ext ;}
    
    my $gui ;
    if ($ARGV[1] =~ /^-+g/i ) { $gui = 1 ;}

    my $script_data = cat_file($script) ;
    my $binary_data = cat_file($^X) ;
    
    open (BIN,">$binary") ; binmode(BIN) ;
    print BIN $binary_data . "\npackage main;\n#line 1 main\n$script_data" ;
    close (BIN) ;
    
    print "Binary created at: $binary\n" ;
    
    if ($gui) {
      print "Converting to GUI... " ;
      &exe_type($binary,'windows') ;
      print "OK\n" ;
    }
    
    print "Enjoy ;-P\n" ;
    
    exit;
  }
}
elsif ( $ARGV[0] =~ /^-+(?:h|help)$/i ) {
  
print qq`_______________________________________________________________________________

TinyPerl 3.0 - Help
_______________________________________________________________________________

  Perl OPTIONS:

  -c              check syntax only (runs BEGIN and CHECK blocks)
  -e 'command'    one line of program (several -e's allowed, omit programfile)
  -i[extension]   edit <> files in place (makes backup if extension supplied)
  -Idirectory     specify \@INC/#include directory (several -I's allowed)  
  -T              enable tainting checks  
  -v              print version, subversion (includes VERY IMPORTANT perl info)
  -V[:variable]   print configuration summary (or a single Config.pm variable)  
  -w              enable many useful warnings (RECOMMENDED)
  -W              enable all warnings
  -X              disable all warnings
  
  EXTRA OPTIONS:
  
  -bin            generate binaries from your script (type it for help).

Copyright (c) 2003-2005 Graciliano M. P. <gmpassos\@cpan.org>
_______________________________________________________________________________

`;

exit ;
  
}


sub cat_file {
  my ($data , $fh) ;  
  open($fh,$_[0]) ; binmode($fh) ;
  #seek($fh,0,1) ;
  1 while( read($fh, $data , 1024*8 , length($data) ) ) ;
  close($fh) ;
  return $data ;
}

sub exe_type {
  my @ARGV = @_ ;

  my %subsys = (
  NATIVE => 1,
  WINDOWS => 2,
  CONSOLE => 3,
  POSIX => 7,
  WINDOWSCE => 9,
  );
  
  unless (0 < @ARGV && @ARGV < 3) {
    printf "Usage: $0 exefile [%s]\n", join '|', sort keys %subsys;
    exit;
  }
  
  $ARGV[1] = uc $ARGV[1] if $ARGV[1];
  unless (@ARGV == 1 || defined $subsys{$ARGV[1]}) {
    (my $subsys = join(', ', sort keys %subsys)) =~ s/, (\w+)$/ or $1/;
    print "Invalid subsystem $ARGV[1], please use $subsys\n";
    exit;
  }
  
  my ($record,$magic,$signature,$offset,$size);
  open EXE, "+< $ARGV[0]" or die "Cannot open $ARGV[0]: $!\n";
  binmode EXE;

  read EXE, $record, 64;
  ($magic,$offset) = unpack "Sx58L", $record;
  
  die "$ARGV[0] is not an MSDOS executable file.\n" unless $magic == 0x5a4d ;

  seek EXE, $offset, 0;
  read EXE, $record, 4+20+2;
  ($signature,$size,$magic) = unpack "Lx16Sx2S", $record;
  
  die "PE header not found" unless $signature == 0x4550;
  
  die "Optional header is neither in NT32 nor in NT64 format" unless ($size == 224 && $magic == 0x10b) || ($size == 240 && $magic == 0x20b) ;

  seek EXE, $offset+4+20+68, 0;
  if (@ARGV == 1) {
    read EXE, $record, 2;
    my ($subsys) = unpack "S", $record;
    $subsys = {reverse %subsys}->{$subsys} || "UNKNOWN($subsys)";
    print "$ARGV[0] uses the $subsys subsystem.\n";
  }
  else {
    print EXE pack "S", $subsys{$ARGV[1]};
  }
  close EXE;
}

  my $tinyperl_size = -s $^X ;
  my $tinyperl_size_org = $LibZip::MAIN::LBZ{z} + $LibZip::MAIN::LBZ{s} ;
  
  if ( $tinyperl_size > $tinyperl_size_org ) {
    my ($code,$fh) = '' ;
    open ($fh, $^X) ; binmode($fh);
    seek($fh,$tinyperl_size_org,0) ;
    1 while( read($fh, $code , 1024*4 , length($code) ) ) ;
    close ($fh) ;
    $LibZip::TMP::CODE = $code ;
    $LibZip::TMP::SCRIPT = $^X ;
  }
  else {
    my $script = shift( @ARGV ) ;
    if ($script eq '') {
      die "Usage: tinyperl script.pl\nHelp: tinyperl -h\n" ;
    }
    elsif (! -e $script || $script eq '') {
      die "Can't find file: $script\n" ;
    }
    else {
      $LibZip::TMP::SCRIPT = $script ;
    }
  }
}

{package main ;
  if ( $LibZip::TMP::CODE ) {
    eval("\n#line 1 $LibZip::TMP::SCRIPT\n" . $LibZip::TMP::CODE) ;
    die $@ if $@ ;  
  }
  elsif ($LibZip::TMP::SCRIPT) {
    do $LibZip::TMP::SCRIPT ;
  }
}

