{ sub _safe_eval { eval "$_[0]" } }

use strict;
use warnings;

use Test::More;

compile_ok('script/demerge');
compile_ok('lib/Gentoo/App/Demerge.pm');

sub compile_ok {
  my ( $filename ) = @_;
  open my $fh, '<', $filename or die "Cannot open $filename, $!";
  my $magic_number = scalar time();
  my $magic_phrase = qq[Compile OK:$magic_number];
  my $code = qq[UNITCHECK { die "$magic_phrase"; }\n];
  $code .=   qq[#line 1 "$filename"\n];
  $code .= do { local $/ = undef; scalar <$fh> };
  close $fh or warn "Error closing $filename, $!";
  local $@;
  if( _safe_eval( $code ) ) {
    diag("Internal die() for compile_ok($filename) was not called");
    return fail("compile_ok($filename) - internal die called");
  }
  if ( $@ !~ /\Q$magic_phrase\E/ ) {
    diag("die() reason for compile_ok($filename) was not the magic phrase >$magic_phrase");
    diag("die reason:");
    diag("$@");
    return fail("compile_ok($filename) - internal die has magic phrase");
  }
  return pass("compile_ok($filename)");
}


done_testing;


