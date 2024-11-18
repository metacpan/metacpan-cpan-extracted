package Devel::PatchPerl::Plugin::Darwin;

require Devel::PatchPerl;

use strict;
use warnings;
use version;

our $VERSION = 'v0.1.2';

my @patch = (
    {
	perl => [ '5.6.0' ],
	subs => [ [ \&_patch_h2ph_pht560 ], [ \&_patch_h2ph_h560 ], [ \&_patch_h2ph560 ] ],
    },
    {
	perl => [ qr/^5\.6\.[1-2]$/ ],
	subs => [ [ \&_patch_darwin_locale_test561 ], [ \&_patch_x2p_util561 ], [ \&_patch_timelocal_test561 ],
	    [ \&_patch_h2ph_pht560 ], [ \&_patch_h2ph_h560 ], [ \&_patch_h2ph560 ], [ \&_patch_pwent_test561 ] ],
    },
    {
	perl => [ qw/5.8.9 5.10.1 5.11.0/, qr/^5\.9\.[0-5]$/ ],
	subs => [ [ \&_patch_darwin_locale_test589 ] ],
    },
    {
	perl => [ qr/^5\.11\.[1-5]$/, qr/^5\.12\.[0-4]/, '5.13.0' ],
	subs => [ [ \&_patch_darwin_locale_test5111 ] ],
    },
    {
	perl => [ '5.12.5', qr/^5\.14\.[0-4]/ ],
	subs => [ [ \&_patch_darwin_locale_test5125 ] ],
    },
    {
	perl => [ qr/^5\.13\.[1-9]$/, qr/^5\.13\.(10|11)/ ],
	subs => [ [ \&_patch_darwin_locale_test5131 ] ],
    },
    {
	perl => [ qr/^5\.15\.[0-7]$/ ],
	subs => [ [ \&_patch_darwin_locale_test5150 ] ],
    },
    {
	perl => [ qr/^5\.15\.[89]$/, qr/^5\.16\.[0-3]$/, qr/^5\.17\.\d+/, qr/^5\.18\.[0-4]$/, qr/^5\.19\.[0-8]/ ],
	subs => [ [ \&_patch_darwin_locale_test5158 ] ],
    },
    {
	perl => [ qr/^5\.18\.[0-4]$/ ],

	subs => [ [ \&_patch_darwin_gdbm_fatal_test5180 ] ],
    },
    {
	perl => [ qr/^5\.22\.[34]$/ ],
	subs => [ [ \&_patch_darwin_customized_dat5223 ] ],
    },
    {
	perl => [ qr/^5\.22\.[0-4]$/, qr/^5\.23\.[0-9]$/, qr/^5\.24\.[0-4]$/ ],
	subs => [ [ \&_patch_darwin_libperl_test5230 ] ],
    },
    {
	perl => [ qr/^5\.24\.[1-4]$/ ],
	subs => [ [ \&_patch_darwin_customized_dat5241 ] ],
    },
    {
	perl => [ qr/^5\.25\.]d+/, qr/^5\.26\.[0-3]$/, qr/^5\.27\.\d+/, qr/^5\.28\.[0-3]$/ ],
	subs => [ [ \&_patch_darwin_libperl_test5250 ] ],
    },
    {
	perl => [ qr/^5\.30\.\d+/, qr/^5\.32\.\d+/, qr/^5\.33\.0/ ],
	subs => [ [ \&_patch_darwin_libperl_test5300 ] ],
    },
);

sub patchperl {
    my $class = shift;
    my %args = @_;
    my ($vers, $source, $patchexe) = @args{'version', 'source', 'patchexe'};
    for my $p ( grep { Devel::PatchPerl::_is( $_->{perl}, $vers ) } @patch) {
	for my $s (@{$p->{subs}}) {
	    my($sub, @args) = @$s;
	    push @args, $vers unless scalar @args;
	    $sub->(@args);
	}
    }
}

sub _patch_pwent_test561 {
    my $patch = <<'END';
--- t/op/pwent.t
+++ t/op/pwent.t
@@ -1,5 +1,7 @@
 #!./perl

+my $data;
+
 BEGIN {
     chdir 't' if -d 't';
     @INC = '../lib';
@@ -41,6 +43,47 @@ BEGIN {
 	}
     }

+    if (not defined $where && $^O eq 'darwin') {
+	my %want = do {
+	    my $inx = 0;
+	    map {$_ => {inx => $inx++, mung => sub {$_[0]}}}
+		qw{RecordName Password UniqueID PrimaryGroupID
+		RealName NFSHomeDirectory UserShell};
+	};
+	$want{RecordName}{mung} = sub {(split '\s+', $_[0], 2)[0]};
+	$want{UniqueID}{mung} = $want{PrimaryGroupID}{mung} = sub {
+	    unpack 'L', pack 'l', $_[0]};
+	foreach my $dscl (qw(/usr/bin/dscl)) {
+	    -x $dscl or next;
+	    open (my $fh, '-|', join (' ', $dscl, qw{. -readall /Users},
+		    keys %want, '2>/dev/null')) or next;
+	    my @rec;
+	    while (<$fh>) {
+		chomp;
+		if ($_ eq '-') {
+		    @rec and $data .= join (':', @rec) . "\n";
+		    @rec = ();
+		    next;
+		}
+		my ($name, $value) = split ':\s+', $_, 2;
+		unless (defined $value) {
+		    s/:$//;
+		    $name = $_;
+		    $value = <$fh>;
+		    chomp $value;
+		    $value =~ s/^\s+//;
+		}
+		if (defined (my $info = $want{$name})) {
+		    $rec[$info->{inx}] = $info->{mung}->($value);
+		}
+	    }
+	    @rec and $data .= join (':', @rec) . "\n";
+	    $where = "dscl . -readall /Users";
+	    undef $reason;
+	    last;
+	}
+    }
+
     if (not defined $where) {	# Try local.
 	my $PW = "/etc/passwd";
 	if (-f $PW && open(PW, $PW) && defined(<PW>)) {
@@ -69,51 +112,90 @@ my %perfect;
 my %seen;

 setpwent();
-while (<PW>) {
-    chomp;
-    # LIMIT -1 so that users with empty shells don't fall off
-    my @s = split /:/, $_, -1;
-    my ($name_s, $passwd_s, $uid_s, $gid_s, $gcos_s, $home_s, $shell_s);
-    if ($^O eq 'darwin') {
-       ($name_s, $passwd_s, $uid_s, $gid_s, $gcos_s, $home_s, $shell_s) = @s[0,1,2,3,7,8,9];
-    } else {
-       ($name_s, $passwd_s, $uid_s, $gid_s, $gcos_s, $home_s, $shell_s) = @s;
-    }
-    next if /^\+/; # ignore NIS includes
-    if (@s) {
-	push @{ $seen{$name_s} }, $.;
-    } else {
-	warn "# Your $where line $. is empty.\n";
-	next;
-    }
-    if ($n == $max) {
-	local $/;
-	my $junk = <PW>;
-	last;
-    }
-    # In principle we could whine if @s != 7 but do we know enough
-    # of passwd file formats everywhere?
-    if (@s == 7 || ($^O eq 'darwin' && @s == 10)) {
-	@n = getpwuid($uid_s);
-	# 'nobody' et al.
-	next unless @n;
-	my ($name,$passwd,$uid,$gid,$quota,$comment,$gcos,$home,$shell) = @n;
-	# Protect against one-to-many and many-to-one mappings.
-	if ($name_s ne $name) {
-	    @n = getpwnam($name_s);
-	    ($name,$passwd,$uid,$gid,$quota,$comment,$gcos,$home,$shell) = @n;
-	    next if $name_s ne $name;
-	}
-	$perfect{$name_s}++
-	    if $name    eq $name_s    and
-               $uid     eq $uid_s     and
-# Do not compare passwords: think shadow passwords.
-               $gid     eq $gid_s     and
-               $gcos    eq $gcos_s    and
-               $home    eq $home_s    and
-               $shell   eq $shell_s;
+
+if ($^O eq 'darwin') {
+    my @lines = split(/\n/, $data);
+    foreach my $line (@lines) {
+	my @s = split /:/, $line, -1;
+	my ($name_s, $passwd_s, $uid_s, $gid_s, $gcos_s, $home_s, $shell_s) = @s;
+	next if /^\+/; # ignore NIS includes
+	if (@s) {
+	    push @{ $seen{$name_s} }, $.;
+	} else {
+	    warn "# Your $where line $. is empty.\n";
+	    next;
+	}
+	if ($n == $max) {
+	    local $/;
+	    my $junk = <PW>;
+	    last;
+	}
+	if (@s == 7 || ($^O eq 'darwin' && @s == 10)) {
+	    @n = getpwuid($uid_s);
+	    next unless @n;
+	    my ($name,$passwd,$uid,$gid,$quota,$comment,$gcos,$home,$shell) = @n;
+	    if ($name_s ne $name) {
+		@n = getpwnam($name_s);
+		($name,$passwd,$uid,$gid,$quota,$comment,$gcos,$home,$shell) = @n;
+		next if $name_s ne $name;
+	    }
+	    $perfect{$name_s}++
+		if $name    eq $name_s    and
+		$uid     eq $uid_s     and
+		$gid     eq $gid_s     and
+		$gcos    eq $gcos_s    and
+		$home    eq $home_s    and
+		$shell   eq $shell_s;
+	}
+	$n++;
+    }
+} else {
+    while (<PW>) {
+	chomp;
+	# LIMIT -1 so that users with empty shells don't fall off
+	my @s = split /:/, $_, -1;
+	my ($name_s, $passwd_s, $uid_s, $gid_s, $gcos_s, $home_s, $shell_s);
+	if ($^O eq 'darwin') {
+	    ($name_s, $passwd_s, $uid_s, $gid_s, $gcos_s, $home_s, $shell_s) = @s[0,1,2,3,7,8,9];
+	} else {
+	    ($name_s, $passwd_s, $uid_s, $gid_s, $gcos_s, $home_s, $shell_s) = @s;
+	}
+	next if /^\+/; # ignore NIS includes
+	if (@s) {
+	    push @{ $seen{$name_s} }, $.;
+	} else {
+	    warn "# Your $where line $. is empty.\n";
+	    next;
+	}
+	if ($n == $max) {
+	    local $/;
+	    my $junk = <PW>;
+	    last;
+	}
+	# In principle we could whine if @s != 7 but do we know enough
+	# of passwd file formats everywhere?
+	if (@s == 7 || ($^O eq 'darwin' && @s == 10)) {
+	    @n = getpwuid($uid_s);
+	    # 'nobody' et al.
+	    next unless @n;
+	    my ($name,$passwd,$uid,$gid,$quota,$comment,$gcos,$home,$shell) = @n;
+	    # Protect against one-to-many and many-to-one mappings.
+	    if ($name_s ne $name) {
+		@n = getpwnam($name_s);
+		($name,$passwd,$uid,$gid,$quota,$comment,$gcos,$home,$shell) = @n;
+		next if $name_s ne $name;
+	    }
+	    $perfect{$name_s}++
+		if $name    eq $name_s    and
+		$uid     eq $uid_s     and
+		# Do not compare passwords: think shadow passwords.
+		$gid     eq $gid_s     and
+		$gcos    eq $gcos_s    and
+		$home    eq $home_s    and
+		$shell   eq $shell_s;
+	}
+	$n++;
     }
-    $n++;
 }
 endpwent();
END
    Devel::PatchPerl::_patch($patch);
}

sub _patch_h2ph_pht560 {
    my $patch = <<'END';
--- t/lib/h2ph.pht
+++ t/lib/h2ph.pht
@@ -29,7 +29,7 @@ unless(defined(&_H2PH_H_)) {
     if(!(defined (defined(&__SOMETHING_MORE_IMPORTANT) ? &__SOMETHING_MORE_IMPORTANT : 0))) {
     }
  elsif(!(defined (defined(&__SOMETHING_REALLY_REALLY_IMPORTANT) ? &__SOMETHING_REALLY_REALLY_IMPORTANT : 0))) {
-	die("Nup\,\ can\'t\ go\ on\ ");
+	die("Nup, can't go on");
     } else {
 	eval 'sub EVERYTHING_IS_OK () {1;}' unless defined(&EVERYTHING_IS_OK);
     }
@@ -49,7 +49,7 @@ unless(defined(&_H2PH_H_)) {
     require 'sys/ioctl.ph';
     eval {
 	my(%INCD) = map { $INC{$_} => 1 } (grep { $_ eq "sys/fcntl.ph" } keys(%INC));
-	my(@REM) = map { "$_/sys/fcntl.ph" } (grep { not exists($INCD{"$_/sys/fcntl.ph"})and -f "$_/sys/fcntl.ph" } @INC);
+	my(@REM) = map { "$_/sys/fcntl.ph" } (grep { not exists($INCD{"$_/sys/fcntl.ph"}) and -f "$_/sys/fcntl.ph" } @INC);
 	require "$REM[0]" if @REM;
     };
     warn($@) if $@;
END
    Devel::PatchPerl::_patch($patch);
}

sub _patch_h2ph_h560 {
    my $patch = <<'END';
--- t/lib/h2ph.h
+++ t/lib/h2ph.h
@@ -38,7 +38,7 @@
 #if !(defined __SOMETHING_MORE_IMPORTANT)
 #    warn Be careful...
 #elif !(defined __SOMETHING_REALLY_REALLY_IMPORTANT)
-#    error Nup, can't go on /* ' /* stupid font-lock-mode */
+#    error "Nup, can't go on" /* ' /* stupid font-lock-mode */
 #else /* defined __SOMETHING_MORE_IMPORTANT && defined __SOMETHING_REALLY_REALLY_IMPORTANT */
 #    define EVERYTHING_IS_OK
 #endif
END
    Devel::PatchPerl::_patch($patch);
}

sub _patch_h2ph560 {
    my $patch = <<'END';
--- utils/h2ph.PL.orig	2021-02-14 16:41:47.000000000 +0900
+++ utils/h2ph.PL	2021-02-14 16:43:37.000000000 +0900
@@ -120,9 +120,7 @@ while (defined (my $file = next_file()))
 	open(OUT,">$Dest_dir/$outfile") || die "Can't create $outfile: $!\n";
     }

-    print OUT
-        "require '_h2ph_pre.ph';\n\n",
-        "no warnings 'redefine';\n\n";
+    print OUT "require '_h2ph_pre.ph';\n\n";

     while (defined (local $_ = next_line($file))) {
 	if (s/^\s*\#\s*//) {
@@ -195,19 +193,18 @@ while (defined (my $file = next_file()))
 			   "eval {\n");
                 $tab += 4;
                 $t = "\t" x ($tab / 8) . ' ' x ($tab % 8);
-                    print OUT ($t, "my(\@REM);\n");
                     if ($incl_type eq 'include_next') {
 		print OUT ($t,
 			   "my(\%INCD) = map { \$INC{\$_} => 1 } ",
 			           "(grep { \$_ eq \"$incl\" } ",
                                    "keys(\%INC));\n");
 		print OUT ($t,
-			           "\@REM = map { \"\$_/$incl\" } ",
+			           "my(\@REM) = map { \"\$_/$incl\" } ",
 			   "(grep { not exists(\$INCD{\"\$_/$incl\"})",
 			           " and -f \"\$_/$incl\" } \@INC);\n");
                     } else {
                         print OUT ($t,
-                                   "\@REM = map { \"\$_/$incl\" } ",
+                                   "my(\@REM) = map { \"\$_/$incl\" } ",
                                    "(grep {-r \"\$_/$incl\" } \@INC);\n");
                     }
 		print OUT ($t,
@@ -436,7 +433,7 @@ sub expr {
 		}
 	    } else {
 		if ($inif && $new !~ /defined\s*\($/) {
-		    $new .= '(defined(&' . $id . ') ? &' . $id . ' : undef)';
+		    $new .= '(defined(&' . $id . ') ? &' . $id . ' : 0)';
 		} elsif (/^\[/) {
 		    $new .= " \$$id";
 		} else {
END
    Devel::PatchPerl::_patch($patch);
}

sub _patch_x2p_util561 {
    my $patch = <<'END';
--- x2p/util.c
+++ x2p/util.c
@@ -204,7 +204,7 @@ fatal(char *pat,...)
 }

 #if defined(__APPLE_CC__)
-__private_extern__	/* warn() conflicts with libc */
+__private_extern__;	/* warn() conflicts with libc */
 #endif
 void
 warn(char *pat,...)
END
    Devel::PatchPerl::_patch($patch);
}

sub _patch_timelocal_test561 {
    my $patch = <<'END';
--- t/lib/timelocal.t
+++ t/lib/timelocal.t
@@ -27,11 +27,12 @@ print "1..", @time * 2 + 5, "\n";
 $count = 1;
 for (@time) {
     my($year, $mon, $mday, $hour, $min, $sec) = @$_;
-    $year -= 1900;
+    $year -= 1900 if ($year < 1900);
     $mon --;
     my $time = timelocal($sec,$min,$hour,$mday,$mon,$year);
     # print scalar(localtime($time)), "\n";
     my($s,$m,$h,$D,$M,$Y) = localtime($time);
+    $Y += 1900;

     if ($s == $sec &&
 	$m == $min &&
@@ -50,6 +51,7 @@ for (@time) {
     $time = timegm($sec,$min,$hour,$mday,$mon,$year);
     ($s,$m,$h,$D,$M,$Y) = gmtime($time);

+    $Y += 1900;
     if ($s == $sec &&
 	$m == $min &&
 	$h == $hour &&
END
    Devel::PatchPerl::_patch($patch);
}

sub _patch_darwin_locale_test561 {
    my $patch = <<'END';
--- t/pragma/locale.t
+++ t/pragma/locale.t
@@ -424,6 +424,19 @@ if (-x "/usr/bin/locale" && open(LOCALES

 setlocale(LC_ALL, "C");

+if ($^O eq 'darwin') {
+    # Darwin 8/Mac OS X 10.4 and 10.5 have bad Basque locales: perl bug #35895,
+    # Apple bug ID# 4139653. It also has a problem in Byelorussian.
+    (my $v) = $Config{osvers} =~ /^(\d+)/;
+    if ($v >= 8 and $v < 10) {
+	debug "# Skipping eu_ES, be_BY locales -- buggy in Darwin\n";
+	@Locale = grep ! m/^(eu_ES(?:\..*)?|be_BY\.CP1131)$/, @Locale;
+    } else {
+	debug "# Skipping be_BY locales -- buggy in Darwin\n";
+	@Locale = grep ! m/^be_BY\.CP1131$/, @Locale;
+    }
+}
+
 sub utf8locale { $_[0] =~ /utf-?8/i }

 @Locale = sort @Locale;
END
    Devel::PatchPerl::_patch($patch);
}

sub _patch_darwin_locale_test589 {
    my $patch = <<'END';
--- lib/locale.t
+++ lib/locale.t
@@ -460,6 +460,9 @@ if ($^O eq 'darwin') {
     if ($v >= 8 and $v < 10) {
 	debug "# Skipping eu_ES, be_BY locales -- buggy in Darwin\n";
 	@Locale = grep ! m/^(eu_ES|be_BY.CP1131$)/, @Locale;
+    } else {
+	debug "# Skipping be_BY locales -- buggy in Darwin\n";
+	@Locale = grep ! m/^be_BY\.CP1131$/, @Locale;
     }
 }
END
    Devel::PatchPerl::_patch($patch);
}

sub _patch_darwin_locale_test5111 {
    my $patch = <<'END';
--- lib/locale.t
+++ lib/locale.t
@@ -460,7 +460,7 @@ if ($^O eq 'darwin') {
     if ($v >= 8 and $v < 10) {
 	debug "# Skipping eu_ES, be_BY locales -- buggy in Darwin\n";
 	@Locale = grep ! m/^(eu_ES|be_BY\.CP1131)$/, @Locale;
-    } elsif ($v < 11) {
+    } else {
 	debug "# Skipping be_BY locales -- buggy in Darwin\n";
 	@Locale = grep ! m/^be_BY\.CP1131$/, @Locale;
     }
END
    Devel::PatchPerl::_patch($patch);
}

sub _patch_darwin_locale_test5125 {
    my $patch = <<'END';
--- lib/locale.t
+++ lib/locale.t
@@ -460,7 +460,7 @@ if ($^O eq 'darwin') {
     if ($v >= 8 and $v < 10) {
 	debug "# Skipping eu_ES, be_BY locales -- buggy in Darwin\n";
 	@Locale = grep ! m/^(eu_ES(?:\..*)?|be_BY\.CP1131)$/, @Locale;
-    } elsif ($v < 13) {
+    } else {
 	debug "# Skipping be_BY locales -- buggy in Darwin\n";
 	@Locale = grep ! m/^be_BY\.CP1131$/, @Locale;
     }
END
    Devel::PatchPerl::_patch($patch);
}

sub _patch_darwin_locale_test5131 {
    my $patch = <<'END';
--- lib/locale.t
+++ lib/locale.t
@@ -460,7 +460,7 @@ if ($^O eq 'darwin') {
     if ($v >= 8 and $v < 10) {
 	debug "# Skipping eu_ES, be_BY locales -- buggy in Darwin\n";
 	@Locale = grep ! m/^(eu_ES(?:\..*)?|be_BY\.CP1131)$/, @Locale;
-    } elsif ($v < 11) {
+    } else {
 	debug "# Skipping be_BY locales -- buggy in Darwin\n";
 	@Locale = grep ! m/^be_BY\.CP1131$/, @Locale;
     }
END
    Devel::PatchPerl::_patch($patch);
}

sub _patch_darwin_locale_test5150 {
    my $patch = <<'END';
--- lib/locale.t
+++ lib/locale.t
@@ -460,7 +460,7 @@ if ($^O eq 'darwin') {
     if ($v >= 8 and $v < 10) {
 	debug "# Skipping eu_ES, be_BY locales -- buggy in Darwin\n";
 	@Locale = grep ! m/^(eu_ES(?:\..*)?|be_BY\.CP1131)$/, @Locale;
-    } elsif ($v < 12) {
+    } else {
 	debug "# Skipping be_BY locales -- buggy in Darwin\n";
 	@Locale = grep ! m/^be_BY\.CP1131$/, @Locale;
     }
END
    Devel::PatchPerl::_patch($patch);
}

sub _patch_darwin_locale_test5158 {
    my $patch = <<'END';
--- lib/locale.t
+++ lib/locale.t
@@ -648,7 +648,7 @@ if ($^O eq 'darwin') {
     if ($v >= 8 and $v < 10) {
 	debug "# Skipping eu_ES, be_BY locales -- buggy in Darwin\n";
 	@Locale = grep ! m/^(eu_ES(?:\..*)?|be_BY\.CP1131)$/, @Locale;
-    } elsif ($v < 12) {
+    } else {
 	debug "# Skipping be_BY locales -- buggy in Darwin\n";
 	@Locale = grep ! m/^be_BY\.CP1131$/, @Locale;
     }
END
    Devel::PatchPerl::_patch($patch);
}

sub _patch_darwin_gdbm_fatal_test5180 {
    my $patch = <<'END';
--- ext/GDBM_File/t/fatal.t
+++ ext/GDBM_File/t/fatal.t
@@ -30,16 +30,21 @@ isnt((open $fh, "<&=$fileno"), undef, "d
     or diag("\$! = $!");
 isnt(close $fh, undef,
      "close fileno $fileno, out from underneath the GDBM_File");
-is(eval {
+my $res = eval {
     $h{Perl} = 'Rules';
     untie %h;
-    1;
-}, undef, 'Trapped error when attempting to write to knobbled GDBM_File');
+    99;
+};

-# Observed "File write error" and "lseek error" from two different systems.
-# So there might be more variants. Important part was that we trapped the error
-# via croak.
-like($@, qr/ at .*\bfatal\.t line \d+\.\n\z/,
-     'expected error message from GDBM_File');
+SKIP: {
+    skip "Can't trigger failure", 2 if $res == 99;
+    is $res, undef, "eval should return undef";
+
+    # Observed "File write error" and "lseek error" from two different systems.
+    # So there might be more variants. Important part was that we trapped the error
+    # via croak.
+    like($@, qr/ at .*\bfatal\.t line \d+\.\n\z/,
+	 'expected error message from GDBM_File');
+}

 unlink <Op_dbmx*>;
END
    Devel::PatchPerl::_patch($patch);
}

sub _patch_darwin_libperl_test5230 {
   my $patch = <<'END';
--- t/porting/libperl.t
+++ t/porting/libperl.t
@@ -550,7 +550,7 @@ if (defined $nm_err_tmp) {
         while (<$nm_err_fh>) {
             # OS X has weird error where nm warns about
             # "no name list" but then outputs fine.
-            if (/nm: no name list/ && $^O eq 'darwin') {
+            if ((/nm: no name list/ || /^no symbols$/) && $^O eq 'darwin') {
                 print "# $^O ignoring $nm output: $_";
                 next;
             }
END
    Devel::PatchPerl::_patch($patch);
}

sub _patch_darwin_customized_dat5223 {
    my $patch = <<'END';
--- t/porting/customized.dat
+++ t/porting/customized.dat
@@ -20,7 +20,7 @@ ExtUtils::Command cpan/ExtUtils-Command/
 ExtUtils::MakeMaker cpan/ExtUtils-MakeMaker/bin/instmodsh 5bc04a0173b8b787f465271b6186220326ae8eef
 ExtUtils::MakeMaker cpan/ExtUtils-MakeMaker/lib/ExtUtils/Command/MM.pm 6298f9b41b29e13010b185f64fa952570637fbb4
 ExtUtils::MakeMaker cpan/ExtUtils-MakeMaker/lib/ExtUtils/Liblist.pm 6e16329fb4d4c2f8db4afef4d8e79c1c1c918128
-ExtUtils::MakeMaker cpan/ExtUtils-MakeMaker/lib/ExtUtils/Liblist/Kid.pm fc0483c5c7b92a8e0f63eb1f762172cddce5b948
+ExtUtils::MakeMaker cpan/ExtUtils-MakeMaker/lib/ExtUtils/Liblist/Kid.pm 9239e2140e8d78d2d70802eff7ff07cb147bf0c6
 ExtUtils::MakeMaker cpan/ExtUtils-MakeMaker/lib/ExtUtils/MakeMaker.pm 8d1b35fcd7d3b4f0552ffb151baf75ccb181267b
 ExtUtils::MakeMaker cpan/ExtUtils-MakeMaker/lib/ExtUtils/MakeMaker/Config.pm 676b10e16b2dc68ba21312ed8aa4d409e86005a6
 ExtUtils::MakeMaker cpan/ExtUtils-MakeMaker/lib/ExtUtils/MakeMaker/FAQ.pod 757bffb47857521311f8f3bde43ebe165f8d5191
END
    Devel::PatchPerl::_patch($patch);
}

sub _patch_darwin_customized_dat5241 {
    my $patch = <<'END';
--- t/porting/customized.dat
+++ t/porting/customized.dat
@@ -22,7 +22,7 @@ ExtUtils::MakeMaker cpan/ExtUtils-MakeMa
 ExtUtils::MakeMaker cpan/ExtUtils-MakeMaker/lib/ExtUtils/Command.pm e3a372e07392179711ea9972087c1105a2780fad
 ExtUtils::MakeMaker cpan/ExtUtils-MakeMaker/lib/ExtUtils/Command/MM.pm b72721bd6aa9bf7ec328bda99a8fdb63cac6114d
 ExtUtils::MakeMaker cpan/ExtUtils-MakeMaker/lib/ExtUtils/Liblist.pm 0e1e4c25eddb999fec6c4dc66593f76db34cfd16
-ExtUtils::MakeMaker cpan/ExtUtils-MakeMaker/lib/ExtUtils/Liblist/Kid.pm bfd2aa00ca4ed251f342e1d1ad704abbaf5a615e
+ExtUtils::MakeMaker cpan/ExtUtils-MakeMaker/lib/ExtUtils/Liblist/Kid.pm 47d2fdf890d7913ccd0e32b5f98a98f75745d227
 ExtUtils::MakeMaker cpan/ExtUtils-MakeMaker/lib/ExtUtils/MakeMaker.pm 5529ae3064365eafd99536621305d52f4ab31b45
 ExtUtils::MakeMaker cpan/ExtUtils-MakeMaker/lib/ExtUtils/MakeMaker/Config.pm bc88b275af73b8faac6abd59a9aad3f625925810
 ExtUtils::MakeMaker cpan/ExtUtils-MakeMaker/lib/ExtUtils/MakeMaker/FAQ.pod 062e5d14a803fbbec8d61803086a3d7997e8a473
END
    Devel::PatchPerl::_patch($patch);
}

sub _patch_darwin_libperl_test5250 {
    my $patch = <<'END';
--- t/porting/libperl.t
+++ t/porting/libperl.t
@@ -241,7 +241,8 @@ sub nm_parse_gnu {
 sub nm_parse_darwin {
     my $symbols = shift;
     my $line = $_;
-    if (m{^(?:.+)?libperl\.a\((\w+\.o)\):$}) {
+    if (m{^(?:.+)?libperl\.a\((\w+\.o)\):$} ||
+        m{^(\w+\.o):$}) {
         # object file name
         $symbols->{obj}{$1}++;
         $symbols->{o} = $1;
@@ -574,7 +575,7 @@ if (defined $nm_err_tmp) {
         while (<$nm_err_fh>) {
             # OS X has weird error where nm warns about
             # "no name list" but then outputs fine.
-            if (/nm: no name list/ && $^O eq 'darwin') {
+            if ((/nm: no name list/ || /^no symbols$/) && $^O eq 'darwin') {
                 print "# $^O ignoring $nm output: $_";
                 next;
             }
END
    Devel::PatchPerl::_patch($patch);
}

sub _patch_darwin_libperl_test5300 {
    my $patch = <<'END';
--- t/porting/libperl.t
+++ t/porting/libperl.t
@@ -241,7 +241,8 @@ sub nm_parse_gnu {
 sub nm_parse_darwin {
     my $symbols = shift;
     my $line = $_;
-    if (m{^(?:.+)?libperl\.a\((\w+\.o)\):$}) {
+    if (m{^(?:.+)?libperl\.a\((\w+\.o)\):$} ||
+        m{^(\w+\.o):$}) {
         # object file name
         $symbols->{obj}{$1}++;
         $symbols->{o} = $1;
END
    Devel::PatchPerl::_patch($patch);
}

1;

__END__

=head1 NAME

Devel::PatchPerl::Plugin::Darrwin - patchperl plugin for darwin

=head1 SYNOPSIS

    export PERL5_PATCHPERL_PLUGIN=Darwin
    perlbrew install 5.8.9

=head1 DESCRIPTION

This module is a patchperl plugin for avoiding failure of test on MacOSX(Darwin)

Currently support perl version is bellow.

=over 4

=item * 5.32.1

=item * 5.30.3

=item * 5.28.3

=item * 5.26.3

=item * 5.24.4

=item * 5.22.4

=item * 5.20.3

=item * 5.18.4

=item * 5.16.3

=item * 5.14.4

=item * 5.12.5

=item * 5.10.1

=item * 5.8.9

=item * 5.6.2

=back

=head1 AUTHOR

gucchisk

=head1 REPOSITORY

L<https://github.com/gucchisk/devel-patchperl-plugin-darwin>

=head1 SEE ALSO

L<Devel::PatchPerl::Plugin>
