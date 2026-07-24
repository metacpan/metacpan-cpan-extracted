#!perl
#
# File::Unpack2 ships no external mime helpers of its own; support for extra
# formats is an optional extension. This test exercises that extension mechanism
# with a minimal example helper, both ways it can be registered:
#
#   1. programmatically, with mime_helper()      (the primary, documented way)
#   2. as an executable script in a directory,   (via mime_helper_dir / helper_dir)
#
# It is fully self-contained: the "format" is a plain text file, and the helper
# is a two-line shell script we write in the test.

use strict;
use warnings;
use Test::More;
use FindBin;
BEGIN { unshift @INC, "$1/../blib/lib" if $FindBin::Bin =~ m{(.*)} };
use File::Unpack2;
use File::Temp ();

# Fail fast if a regression makes a helper hang, instead of hanging CI forever.
$SIG{ALRM} = sub { die "TIMEOUT: possible helper hang in " . __FILE__ . "\n" }; alarm 120;

# By default, with nothing configured, no external helper directory is scanned:
# File::Unpack2 ships no external helpers, so only the built-ins are present.
{
  local $ENV{FILE_UNPACK2_HELPER_DIR};
  delete $ENV{FILE_UNPACK2_HELPER_DIR};
  my $u   = File::Unpack2->new(logfile => '/dev/null', verbose => 0);
  my @ext = grep { ($_->{a} || '') ne '' } @{$u->mime_helper()};   # {a} is set only for dir-scanned scripts
  is(File::Unpack2::_default_helper_dir(), undef, 'no helper directory configured by default');
  is(scalar(@ext), 0, 'no external helpers registered by default');
}

# A distinctive input we can route to our example helper. A file with a shell
# shebang is detected as text/x-shellscript (not the special-cased text/plain,
# which unpack treats as a final leaf), and File::Unpack2 has no built-in helper
# for it - so our registered helper is the sole handler.
my $fixture = mkfixture("#!/bin/sh\necho MARKER-CONTENTS-42\n");

subtest 'register a helper programmatically with mime_helper()' => sub {
  my $dest = File::Temp::tempdir("FU_12_prog_XXXXX", TMPDIR => 1, CLEANUP => 1);
  my $u = File::Unpack2->new(logfile => '/dev/null', verbose => 0, destdir => $dest, one_shot => 1);

  # Our example helper: copy the source to a fixed name, proving it ran and that
  # the %(src)s argument substitution works. mime_helper(name, suffix_re, [cmd...]).
  $u->mime_helper('text=x-shellscript', qr{sh}, [qw(/bin/cp %(src)s handled-by-example-helper)]);

  my ($h) = $u->find_mime_helper($u->mime($fixture));
  like($h->{fmt_p}, qr{/bin/cp .*handled-by-example-helper}, 'the mime type now routes to our helper');

  $u->unpack($fixture);
  is_deeply($u->{error}, undef, 'no unpack error') or diag "error: @{$u->{error} || []}";

  my @out = find_files($dest, qr{handled-by-example-helper$});
  ok(@out == 1, 'the example helper produced its output file') or diag "tree:\n" . tree($dest);
  SKIP: {
    skip 'helper output missing', 1 unless @out;
    like(slurp($out[0]), qr{MARKER-CONTENTS-42}, 'helper received the real source via %(src)s');
  }
};

subtest 'register helpers from a directory with mime_helper_dir()' => sub {
  # Build a directory of executable helper scripts, named after the mime type
  # (with "/" written as "="), exactly as a site would ship its own helpers.
  my $hdir = File::Temp::tempdir("FU_12_hdir_XXXXX", TMPDIR => 1, CLEANUP => 1);
  my $helper = "$hdir/text=x-shellscript";
  spew($helper, <<'SH');
#!/bin/sh
# Example File::Unpack2 mime helper.
# Args: source_path destfile destdir mimetype description config_dir
# cwd is a fresh, empty output directory; write results here with relative paths.
cp "$1" extracted-by-dir-helper
SH
  chmod 0755, $helper or die "chmod($helper): $!";

  my $dest = File::Temp::tempdir("FU_12_dirout_XXXXX", TMPDIR => 1, CLEANUP => 1);

  # Two equivalent ways to point at the directory; exercise the constructor param.
  my $u = File::Unpack2->new(
    logfile    => '/dev/null',
    verbose    => 0,
    destdir    => $dest,
    one_shot   => 1,
    helper_dir => $hdir,
  );

  my ($h) = $u->find_mime_helper($u->mime($fixture));
  like($h->{fmt_p}, qr{\Q$helper\E}, 'helper_dir script is registered and selected');

  $u->unpack($fixture);
  is_deeply($u->{error}, undef, 'no unpack error') or diag "error: @{$u->{error} || []}";

  my @out = find_files($dest, qr{extracted-by-dir-helper$});
  ok(@out == 1, 'the directory helper ran and produced output') or diag "tree:\n" . tree($dest);
  SKIP: {
    skip 'helper output missing', 1 unless @out;
    like(slurp($out[0]), qr{MARKER-CONTENTS-42}, 'directory helper received the real source');
  }
};

done_testing;

# --- helpers ---------------------------------------------------------------

sub mkfixture {
  my ($content) = @_;
  my $dir = File::Temp::tempdir("FU_12_in_XXXXX", TMPDIR => 1, CLEANUP => 1);
  my $f = "$dir/example.sh";
  spew($f, $content);
  return $f;
}

sub spew { my ($p, $c) = @_; open my $f, '>', $p or die "open($p): $!"; print $f $c; close $f }
sub slurp { my ($p) = @_; open my $f, '<', $p or die "open($p): $!"; local $/; <$f> }

sub find_files {
  my ($root, $re) = @_;
  my @out;
  my @stack = ($root);
  while (my $d = shift @stack) {
    opendir my $dh, $d or next;
    for my $e (readdir $dh) {
      next if $e eq '.' or $e eq '..';
      my $p = "$d/$e";
      if    (-d $p) { push @stack, $p }
      elsif (-f $p) { push @out, $p if $p =~ $re }
    }
    closedir $dh;
  }
  return @out;
}

sub tree { my ($root) = @_; join '', map { "  $_\n" } sort(find_files($root, qr{.})) }
