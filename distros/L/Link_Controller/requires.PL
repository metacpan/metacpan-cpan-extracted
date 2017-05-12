use FileHandle ();

=head1 NAME

requires.PL - work out which RPMs are being used by Link_Controller.

=head1 DESCRIPTION

Based on the bundle file this works out the list of RPMs that are
required to install Link_Controller

=head1 BUGS

This is rather carless about running RPM on systems which don't have
it but should result in an empty output file anyway.

=cut


END {
  $? && do {
    print STDERR <<EOF;
requires.PL tried to give non zero exit status: $?.  Exiting zero
instead.  This allows build to proceed even if RPM isn't present.  You
probably don't need to worry about this unless you were trying to
build an RPM of this software
EOF
      $? = 0;
  };
}

$found=0;
DIRCHECK: foreach (split /:/, $ENV{"PATH"}) {
  -x $_ . '/' . 'cdbmake' && do {
    $found=1;
    last DIRCHECK;
  };
}
unless ($found) {
  print STDERR <<EOF unless $found;
No rpm program found so we won't try to generate dependency file
EOF
  exit 0;
}

#It would be nice to implement this using the functions from CPAN
#which read the contents of a bundle but they don't seem to be
#stable.
#

$bfile="lib/Bundle/Link_Controller.pm";
$verbose=0;
@result=();

my $fh = FileHandle->new;
open($fh,$bfile) or die "Could not open '$bfile': $!";

#straight from CPAN module
while (<$fh>) {
    $inpod = m/^=(?!head1\s+CONTENTS)/ ? 0 :
    m/^=head1\s+CONTENTS/ ? 1 : $inpod;
    next unless $inpod;
    next if /^=/;
    next if /^\s+$/;
    chomp;
    push @result, (split " ", $_, 2)[0];
}
close $fh;

$rfile = "pkg-data-rpm/requires";
my $rfh = FileHandle->new;
open($rfh,"> $rfile") or die "Could not open '$bfile': $!";

my @foundrpm=();

MOD: foreach my $mod (@result) {
    $mod=~ s,::,/,g;
    $mod .= ".pm";
    foreach my $ldir (@INC) {
	my $modf=$ldir . '/' . $mod;
	print "try $modf\n" if $verbose & 8;
	-e $modf or next;
	my $pkg = `rpm -qf $modf`;
	chomp $pkg;
	$pkg =~ m/\s/ and do {
	  warn "didn't expect a space from rpm";
	  print "rpm gave $pkg\n" if $verbose & 2;
	  next;
	};
	print "was in $pkg\n" if $verbose & 2;
	$pkg =~ s/-[^-]+-[^-]+$//;
	$pkg && ( push @foundrpm, $pkg ) or
	    warn "File $modf doesn't belong to an rpm";
	next MOD;
    }
}

push @foundrpm,
    "cdb";

my @reqrpm=sort @foundrpm;
push @reqrpm, ""; #terminator

for(my $i=0; $i < $#reqrpm; $i++) {
    my $reps=1;
    $reps++ while ( $reqrpm[$i] eq $reqrpm[$i+$reps] );
    splice (@reqrpm, $i+1, ($reps - 1) );
}

print $rfh join("\n", @reqrpm );

