#
# This file is part of Devel-PatchPerl-Plugin-BenchmarkVirtualError
#
# This software is Copyright (c) 2015 by DreamHost, Inc.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Devel::PatchPerl::Plugin::BenchmarkVirtualError;
our $AUTHORITY = 'cpan:RSRCHBOY';
# git description: bfb5e4a
$Devel::PatchPerl::Plugin::BenchmarkVirtualError::VERSION = '0.001';

# ABSTRACT: Avoid failures on Benchmark.t when building under certain virtual machines

use base 'Devel::PatchPerl';

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

use vars '@patch';

@patch = (
    {
        perl => [ qr/^5\.(1|20)/ ],
        subs => [ [\&_patch_benchmarkvirtualerror] ],
    },
);

sub _patch_benchmarkvirtualerror {

    _patch(<<'EOP');
diff --git lib/Benchmark.pm lib/Benchmark.pm
index 9a43a2b..73b3211 100644
--- lib/Benchmark.pm
+++ lib/Benchmark.pm
@@ -700,8 +700,18 @@ sub runloop {
     # getting a too low initial $n in the initial, 'find the minimum' loop
     # in &countit.  This, in turn, can reduce the number of calls to
     # &runloop a lot, and thus reduce additive errors.
+    #
+    # Note that its possible for the act of reading the system clock to
+    # burn lots of system CPU while we burn very little user clock in the
+    # busy loop, which can cause the loop to run for a very long wall time.
+    # So gradually ramp up the duration of the loop. See RT #122003
+    #
     my $tbase = Benchmark->new(0)->[1];
-    while ( ( $t0 = Benchmark->new(0) )->[1] == $tbase ) {} ;
+    my $limit = 1;
+    while ( ( $t0 = Benchmark->new(0) )->[1] == $tbase ) {
+        for (my $i=0; $i < $limit; $i++) { my $x = $i / 1.5 } # burn user CPU
+        $limit *= 1.1;
+    }
     $subref->();
     $t1 = Benchmark->new($n);
     $td = &timediff($t1, $t0);
EOP
}

!!42;

__END__

=pod

=encoding UTF-8

=for :stopwords Chris Weyl DreamHost, Inc

=for :stopwords Wishlist flattr flattr'ed gittip gittip'ed

=head1 NAME

Devel::PatchPerl::Plugin::BenchmarkVirtualError - Avoid failures on Benchmark.t when building under certain virtual machines

=head1 VERSION

This document describes version 0.001 of Devel::PatchPerl::Plugin::BenchmarkVirtualError - released December 10, 2015 as part of Devel-PatchPerl-Plugin-BenchmarkVirtualError.

=head1 SYNOPSIS

    $ export PERL5_PATCHPERL_PLUGIN=BenchmarkVirtualError
    $ perl-build ...

=head1 DESCRIPTION

See L<RT #122003|https://rt.perl.org/Public/Bug/Display.html?id=122003>

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<https://rt.perl.org/Public/Bug/Display.html?id=122003|https://rt.perl.org/Public/Bug/Display.html?id=122003>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/RsrchBoy/devel-patchperl-plugin-benchmarkvirtualerror/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <chris.weyl@dreamhost.com>

=head2 I'm a material boy in a material world

=begin html

<a href="https://gratipay.com/RsrchBoy/"><img src="http://img.shields.io/gratipay/RsrchBoy.svg" /></a>
<a href="http://bit.ly/rsrchboys-wishlist"><img src="http://wps.io/wp-content/uploads/2014/05/amazon_wishlist.resized.png" /></a>
<a href="https://flattr.com/submit/auto?user_id=RsrchBoy&url=https%3A%2F%2Fgithub.com%2FRsrchBoy%2Fdevel-patchperl-plugin-benchmarkvirtualerror&title=RsrchBoy's%20CPAN%20Devel-PatchPerl-Plugin-BenchmarkVirtualError&tags=%22RsrchBoy's%20Devel-PatchPerl-Plugin-BenchmarkVirtualError%20in%20the%20CPAN%22"><img src="http://api.flattr.com/button/flattr-badge-large.png" /></a>

=end html

Please note B<I do not expect to be gittip'ed or flattr'ed for this work>,
rather B<it is simply a very pleasant surprise>. I largely create and release
works like this because I need them or I find it enjoyable; however, don't let
that stop you if you feel like it ;)

L<Flattr|https://flattr.com/submit/auto?user_id=RsrchBoy&url=https%3A%2F%2Fgithub.com%2FRsrchBoy%2Fdevel-patchperl-plugin-benchmarkvirtualerror&title=RsrchBoy's%20CPAN%20Devel-PatchPerl-Plugin-BenchmarkVirtualError&tags=%22RsrchBoy's%20Devel-PatchPerl-Plugin-BenchmarkVirtualError%20in%20the%20CPAN%22>,
L<Gratipay|https://gratipay.com/RsrchBoy/>, or indulge my
L<Amazon Wishlist|http://bit.ly/rsrchboys-wishlist>...  If and *only* if you so desire.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by DreamHost, Inc.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
