package Devel::PatchPerl::Plugin::Legacy;
use base 'Devel::PatchPerl';

use strict;
use warnings;

our $VERSION = '0.03';

sub patchperl {
    my $class = shift;
    my %args = @_;
    my ($vers, $source, $patch_exe) = @args{qw(version source patchexe)};
    for my $p ( grep { Devel::PatchPerl::_is( $_->{perl}, $vers ) } @Devel::PatchPerl::patch ) {
        for my $s (@{$p->{subs}}) {
            my ($sub, @args) = @$s;
            push @args, $vers unless scalar @args;
            $sub->(@args);
        }
    }
}

package
  Devel::PatchPerl;

our @patch = (
    {
        perl => [ qr/^5\.8\.8$/ ],
        subs => [ [ \&_legacy_patch_no_debugging ] ],
    },
    {
        perl => [ qr/^5\.8\.[89]$/ ],
        subs => [ [ \&_legacy_patch_hsplit_rehash_58 ] ],
    },
    {
        perl => [
            qr/^5\.10\.1$/,
            qr/^5\.12\.5$/,
        ],
        subs => [ [ \&_legacy_patch_hsplit_rehash_510 ] ],
    },
);

sub _legacy_patch_no_debugging {
    _patch(<<'END');
--- Configure
+++ Configure
@@ -4707,9 +4707,6 @@
 	case "$gccversion" in
 	1*) dflt='-fpcc-struct-return' ;;
 	esac
-	case "$optimize" in
-	*-g*) dflt="$dflt -DDEBUGGING";;
-	esac
 	case "$gccversion" in
 	2*) if test -d /etc/conf/kconfig.d &&
 			$contains _POSIX_VERSION $usrinc/sys/unistd.h >/dev/null 2>&1
END
}

# http://perl5.git.perl.org/perl.git/commit/2674b61957c26a4924831d5110afa454ae7ae5a6
sub _legacy_patch_hsplit_rehash_58
{
  my $perl = shift;
  return if $Devel::PatchPerl::VERSION >= 0.86;

  my $patch = <<'END';
--- hv.c
+++ hv.c
@@ -31,7 +31,8 @@ holds the key and hash value.
 #define PERL_HASH_INTERNAL_ACCESS
 #include "perl.h"
 
-#define HV_MAX_LENGTH_BEFORE_SPLIT 14
+#define HV_MAX_LENGTH_BEFORE_REHASH 14
+#define SHOULD_DO_HSPLIT(xhv) ((xhv)->xhv_keys > (xhv)->xhv_max) /* HvTOTALKEYS(hv) > HvMAX(hv) */
 
 STATIC void
 S_more_he(pTHX)
@@ -705,23 +706,8 @@ Perl_hv_common(pTHX_ HV *hv, SV *keysv, const char *key, STRLEN klen,
 	xhv->xhv_keys++; /* HvTOTALKEYS(hv)++ */
 	if (!counter) {				/* initial entry? */
 	    xhv->xhv_fill++; /* HvFILL(hv)++ */
-	} else if (xhv->xhv_keys > (IV)xhv->xhv_max) {
+	} else if ( SHOULD_DO_HSPLIT(xhv) ) {
 	    hsplit(hv);
-	} else if(!HvREHASH(hv)) {
-	    U32 n_links = 1;
-
-	    while ((counter = HeNEXT(counter)))
-		n_links++;
-
-	    if (n_links > HV_MAX_LENGTH_BEFORE_SPLIT) {
-		/* Use only the old HvKEYS(hv) > HvMAX(hv) condition to limit
-		   bucket splits on a rehashed hash, as we're not going to
-		   split it again, and if someone is lucky (evil) enough to
-		   get all the keys in one list they could exhaust our memory
-		   as we repeatedly double the number of buckets on every
-		   entry. Linear search feels a less worse thing to do.  */
-		hsplit(hv);
-	    }
 	}
     }
 
@@ -1048,7 +1034,7 @@ S_hsplit(pTHX_ HV *hv)
 
 
     /* Pick your policy for "hashing isn't working" here:  */
-    if (longest_chain <= HV_MAX_LENGTH_BEFORE_SPLIT /* split worked?  */
+    if (longest_chain <= HV_MAX_LENGTH_BEFORE_REHASH /* split worked?  */
 	|| HvREHASH(hv)) {
 	return;
     }
@@ -1966,8 +1952,8 @@ S_share_hek_flags(pTHX_ const char *str, I32 len, register U32 hash, int flags)
 	xhv->xhv_keys++; /* HvTOTALKEYS(hv)++ */
 	if (!next) {			/* initial entry? */
 	    xhv->xhv_fill++; /* HvFILL(hv)++ */
-	} else if (xhv->xhv_keys > (IV)xhv->xhv_max /* HvKEYS(hv) > HvMAX(hv) */) {
-		hsplit(PL_strtab);
+	} else if ( SHOULD_DO_HSPLIT(xhv) ) {
+            hsplit(PL_strtab);
 	}
     }
 
--- t/op/hash.t
+++ t/op/hash.t
@@ -39,22 +39,36 @@ use constant THRESHOLD => 14;
 use constant START     => "a";
 
 # some initial hash data
-my %h2 = map {$_ => 1} 'a'..'cc';
+my %h2;
+my $counter= "a";
+$h2{$counter++}++ while $counter ne 'cd';
 
 ok (!Internals::HvREHASH(%h2), 
     "starting with pre-populated non-pathological hash (rehash flag if off)");
 
 my @keys = get_keys(\%h2);
+my $buckets= buckets(\%h2);
 $h2{$_}++ for @keys;
+$h2{$counter++}++ while buckets(\%h2) == $buckets; # force a split
 ok (Internals::HvREHASH(%h2), 
-    scalar(@keys) . " colliding into the same bucket keys are triggering rehash");
+    scalar(@keys) . " colliding into the same bucket keys are triggering rehash after split");
+
+# returns the number of buckets in a hash
+sub buckets {
+    my $hr = shift;
+    my $keys_buckets= scalar(%$hr);
+    if ($keys_buckets=~m!/([0-9]+)\z!) {
+        return 0+$1;
+    } else {
+        return 8;
+    }
+}
 
 sub get_keys {
     my $hr = shift;
 
     # the minimum of bits required to mount the attack on a hash
     my $min_bits = log(THRESHOLD)/log(2);
-
     # if the hash has already been populated with a significant amount
     # of entries the number of mask bits can be higher
     my $keys = scalar keys %$hr;
-- 
1.7.4.1

END

  if ($perl =~ qr/^5\.8\.8$/) {
    $patch =~ s/non-pathological/non-pathalogical/;
    $patch =~ s/triggering/triggerring/;
  }
  _patch($patch);
}

# http://perl5.git.perl.org/perl.git/commit/f14269908e5f8b4cab4b55643d7dd9de577e7918
# http://perl5.git.perl.org/perl.git/commit/9d83adcdf9ab3c1ac7d54d76f3944e57278f0e70
sub _legacy_patch_hsplit_rehash_510 {
  return if $Devel::PatchPerl::VERSION >= 0.86;

  _patch(<<'END');
--- ext/Hash-Util-FieldHash/t/10_hash.t
+++ ext/Hash-Util-FieldHash/t/10_hash.t
@@ -46,15 +46,29 @@ use constant START     => "a";
 
 # some initial hash data
 fieldhash my %h2;
-%h2 = map {$_ => 1} 'a'..'cc';
+my $counter= "a";
+$h2{$counter++}++ while $counter ne 'cd';
 
 ok (!Internals::HvREHASH(%h2), 
     "starting with pre-populated non-pathological hash (rehash flag if off)");
 
 my @keys = get_keys(\%h2);
+my $buckets= buckets(\%h2);
 $h2{$_}++ for @keys;
+$h2{$counter++}++ while buckets(\%h2) == $buckets; # force a split
 ok (Internals::HvREHASH(%h2), 
-    scalar(@keys) . " colliding into the same bucket keys are triggering rehash");
+    scalar(@keys) . " colliding into the same bucket keys are triggering rehash after split");
+
+# returns the number of buckets in a hash
+sub buckets {
+    my $hr = shift;
+    my $keys_buckets= scalar(%$hr);
+    if ($keys_buckets=~m!/([0-9]+)\z!) {
+        return 0+$1;
+    } else {
+        return 8;
+    }
+}
 
 sub get_keys {
     my $hr = shift;
--- hv.c
+++ hv.c
@@ -35,7 +35,8 @@ holds the key and hash value.
 #define PERL_HASH_INTERNAL_ACCESS
 #include "perl.h"
 
-#define HV_MAX_LENGTH_BEFORE_SPLIT 14
+#define HV_MAX_LENGTH_BEFORE_REHASH 14
+#define SHOULD_DO_HSPLIT(xhv) ((xhv)->xhv_keys > (xhv)->xhv_max) /* HvTOTALKEYS(hv) > HvMAX(hv) */
 
 static const char S_strtab_error[]
     = "Cannot modify shared string table in hv_%s";
@@ -818,23 +819,8 @@ Perl_hv_common(pTHX_ HV *hv, SV *keysv, const char *key, STRLEN klen,
 	xhv->xhv_keys++; /* HvTOTALKEYS(hv)++ */
 	if (!counter) {				/* initial entry? */
 	    xhv->xhv_fill++; /* HvFILL(hv)++ */
-	} else if (xhv->xhv_keys > (IV)xhv->xhv_max) {
+	} else if ( SHOULD_DO_HSPLIT(xhv) ) {
 	    hsplit(hv);
-	} else if(!HvREHASH(hv)) {
-	    U32 n_links = 1;
-
-	    while ((counter = HeNEXT(counter)))
-		n_links++;
-
-	    if (n_links > HV_MAX_LENGTH_BEFORE_SPLIT) {
-		/* Use only the old HvKEYS(hv) > HvMAX(hv) condition to limit
-		   bucket splits on a rehashed hash, as we're not going to
-		   split it again, and if someone is lucky (evil) enough to
-		   get all the keys in one list they could exhaust our memory
-		   as we repeatedly double the number of buckets on every
-		   entry. Linear search feels a less worse thing to do.  */
-		hsplit(hv);
-	    }
 	}
     }
 
@@ -1180,7 +1166,7 @@ S_hsplit(pTHX_ HV *hv)
 
 
     /* Pick your policy for "hashing isn't working" here:  */
-    if (longest_chain <= HV_MAX_LENGTH_BEFORE_SPLIT /* split worked?  */
+    if (longest_chain <= HV_MAX_LENGTH_BEFORE_REHASH /* split worked?  */
 	|| HvREHASH(hv)) {
 	return;
     }
@@ -2506,8 +2492,8 @@ S_share_hek_flags(pTHX_ const char *str, I32 len, register U32 hash, int flags)
 	xhv->xhv_keys++; /* HvTOTALKEYS(hv)++ */
 	if (!next) {			/* initial entry? */
 	    xhv->xhv_fill++; /* HvFILL(hv)++ */
-	} else if (xhv->xhv_keys > (IV)xhv->xhv_max /* HvKEYS(hv) > HvMAX(hv) */) {
-		hsplit(PL_strtab);
+	} else if ( SHOULD_DO_HSPLIT(xhv) ) {
+            hsplit(PL_strtab);
 	}
     }
 
diff --git a/t/op/hash.t b/t/op/hash.t
index 9bde518..45eb782 100644
--- t/op/hash.t
+++ t/op/hash.t
@@ -39,22 +39,36 @@ use constant THRESHOLD => 14;
 use constant START     => "a";
 
 # some initial hash data
-my %h2 = map {$_ => 1} 'a'..'cc';
+my %h2;
+my $counter= "a";
+$h2{$counter++}++ while $counter ne 'cd';
 
 ok (!Internals::HvREHASH(%h2), 
     "starting with pre-populated non-pathological hash (rehash flag if off)");
 
 my @keys = get_keys(\%h2);
+my $buckets= buckets(\%h2);
 $h2{$_}++ for @keys;
+$h2{$counter++}++ while buckets(\%h2) == $buckets; # force a split
 ok (Internals::HvREHASH(%h2), 
-    scalar(@keys) . " colliding into the same bucket keys are triggering rehash");
+    scalar(@keys) . " colliding into the same bucket keys are triggering rehash after split");
+
+# returns the number of buckets in a hash
+sub buckets {
+    my $hr = shift;
+    my $keys_buckets= scalar(%$hr);
+    if ($keys_buckets=~m!/([0-9]+)\z!) {
+        return 0+$1;
+    } else {
+        return 8;
+    }
+}
 
 sub get_keys {
     my $hr = shift;
 
     # the minimum of bits required to mount the attack on a hash
     my $min_bits = log(THRESHOLD)/log(2);
-
     # if the hash has already been populated with a significant amount
     # of entries the number of mask bits can be higher
     my $keys = scalar keys %$hr;
-- 
1.7.4.1


END
}

1;

__END__

=head1 NAME

Devel::PatchPerl::Plugin::Legacy - patchperl plugin for EOL Perls

=head1 SYNOPSIS

    export PERL5_PATCHPERL_PLUGIN=Devel::PatchPerl::Plugin::Legacy
    perlbrew install 5.8.8 -Doptimize='-O2 -g'

=head1 DESCRIPTION

Devel::PatchPerl::Plugin::Legacy is a patchperl plugin for EOL Perls.

    5.8.[89]
    5.10.1
    5.12.5
      CVE-2013-1667 prevent hsplit DOS attacks
    5.8.8
      Do not add -DDEBUGGING (which enables internal debugging code) even if "-g" in -Doptimize

=head1 METHODS

=over 4

=item Devel::PatchPerl::Plugin::Asan::patchperl($class, {version,source,patchexe})

Apply patches in Devel::PatchPerl::Plugin::Legacy depending on the
perl version. See L<Devel::PatchPerl::Plugin>.

=back

=head1 AUTHOR

HIROSE Masaaki E<lt>hirose31 _at_ gmail.comE<gt>

=head1 REPOSITORY

L<https://github.com/hirose31/devel-patchperl-plugin-legacy>

  git clone git://github.com/hirose31/devel-patchperl-plugin-legacy.git

patches and collaborators are welcome.

=head1 SEE ALSO

L<Devel::PatchPerl::Plugin>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# for Emacsen
# Local Variables:
# mode: cperl
# cperl-indent-level: 4
# cperl-close-paren-offset: -4
# cperl-indent-parens-as-block: t
# indent-tabs-mode: nil
# coding: utf-8
# End:

# vi: set ts=4 sw=4 sts=0 et ft=perl fenc=utf-8 ff=unix :
