#!/usr/bin/env perl
use Test2::V0;
use Pod::Checker;
use Path::Tiny;

local $ENV{GIT_CONFIG_GLOBAL} = '/dev/null';
local $ENV{GIT_CONFIG_SYSTEM} = '/dev/null';

# The modules are written with the house POD shortcuts (=func, =method,
# =synopsis, ...) that Dist::Zilla turns into standard POD at build time.
# podchecker does not know them, so map them the same way the build does and
# check the result: syntax, internal links, and the =encoding every file with
# non-ASCII text needs.

my %heading = (
  synopsis    => 'SYNOPSIS',
  description => 'DESCRIPTION',
  seealso     => 'SEE ALSO',
);

sub as_standard_pod {
  my ($source) = @_;
  $source =~ s/^=(synopsis|description|seealso)[ \t]*$/=head1 $heading{$1}/mg;
  $source =~ s/^=(?:func|method|attr|opt|env|hook|example)[ \t]+/=head2 /mg;
  return $source;
}

my $tmp = Path::Tiny->tempdir;

for my $file (qw( lib/Git/Libgit2.pm lib/Git/Libgit2/FFI.pm lib/Git/Libgit2/Error.pm )) {
  my $source = path($file)->slurp_utf8;

  ok( $source =~ /^=encoding[ \t]+utf-?8\b/mi, "$file declares =encoding utf8" );

  my $in  = $tmp->child( path($file)->basename );
  my $out = $tmp->child( path($file)->basename . '.log' );
  $in->spew_utf8( as_standard_pod($source) );

  my $checker = Pod::Checker->new( -warnings => 0 );
  $checker->parse_from_file( "$in", "$out" );

  is( $checker->num_errors, 0, "$file passes podchecker" )
    or diag( $out->slurp_utf8 );
}

done_testing;
