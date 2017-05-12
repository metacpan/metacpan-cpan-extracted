use Unicode::UCD qw(charinfo);

my $output = 'eucJP-ascii.ucm';
rename $output, "$output.old" if -e $output;
open EUCJP, '>', $output or die $!;
my $prologue = <<'EOF';
#
# eucJP-ascii.ucm
#
<code_set_name>  "eucJP-ascii"
<code_set_alias> "eucjp-ascii"
<code_set_alias> "x-eucjp-open-19970715-ascii"
<mb_cur_min> 1
<mb_cur_max> 3
<subchar> \xA2\xAE
<uconv_class> "MBCS"
#
CHARMAP
EOF
print EUCJP $prologue;

my $dir = $ARGV[0] || 'www.opengroup.or.jp/jvc/cde';
my %ucs = ();
my %rev = ();
my %ext = ();

# C0/C1 controls (except SS2/SS3) and DEL.
foreach my $c ((0x00..0x1F, 0x7F, 0x80..0x8D, 0x90..0x9F)) {
    $ucs{sprintf "%04X", $c} = [sprintf "\\x%02X", $c];
    $rev{sprintf "\\x%02X", $c} = [sprintf "%04X", $c];
}
# eucJP-ascii mappings.
foreach my $map (qw(0201A 0208A 13th 0212A udc ibmext)) {
  open MAP, "$dir/eucJP-$map.txt" or die $!;
  while (<MAP>) {
    chomp $_;
    my ($euc, $ucs) = split /\s+/;
    $euc =~ s/^0x// || die "$_";
    $ucs =~ s/^0x// || die "$_";
    my @euc = grep { $_ } split /([0-9A-F]{2})/, $euc;
    $euc = "\\x".join("\\x", @euc);
    $ucs{$ucs} ||= [];
    push @{$ucs{$ucs}}, $euc;
    $rev{$euc} ||= [];
    push @{$rev{$euc}}, $ucs;
  }
  close MAP;
}
# eucJP-ms reverse fallbacks.
foreach my $ext (qw(0208M 0212M)) {
  open EXT, "$dir/eucJP-$ext.txt" or die $!;
  while (<EXT>) {
    chomp $_;
    my ($euc, $ucs) = split /\s+/;
    $euc =~ s/^0x// || die "$_";
    $ucs =~ s/^0x// || die "$_";
    my @euc = grep { $_ } split /([0-9A-F]{2})/, $euc;
    $euc = "\\x".join("\\x", @euc);
    next if defined $ucs{$ucs};
    $ext{$ucs} = $euc;
    $ucs{$ucs} = undef;
  }
  close EXT;
}

# Output.
foreach my $u (sort keys %ucs) {
    $name = charinfo(hex("0x$u"))->{name} ||
	    ('E000' le $u and $u le 'F8FF' and '<Private Use>') || '';
    unless (defined $ucs{$u}) {
	print EUCJP "<U$u> $ext{$u} |1 # $name\n";
	next;
    }
    my @u = @{$ucs{$u}};
    if ($#u == 0) {
	print EUCJP "<U$u> $u[0] |0 # $name\n";
    } else {
	print EUCJP "<U$u> ".shift(@u)." |0 # $name\n";
	foreach my $c (@u) {
	    print EUCJP "<U$u> $c |3 # $name\n";
	}
    }
}
# Verify duplicated mapping.
my $dup = 0;
foreach my $e (sort keys %rev) {
    my @e = @{$rev{$e}};
    if ($#e != 0) {
	print STDERR "$e <U".join(">,<U", @e).">\n";
	$dup++;
    }
}
warn "$dup duplicated mapping" if $dup;

my $epilogue = <<'EOF';
END CHARMAP
EOF
print EUCJP $epilogue;
close EUCJP;

