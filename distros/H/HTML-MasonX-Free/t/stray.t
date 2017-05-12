#!perl
use strict;
use warnings;

use Test::Fatal;
use Test::More;

use Path::Class qw(dir);
use HTML::Mason::Interp;
use HTML::MasonX::Free::Compiler;

my $interp = HTML::Mason::Interp->new(
  comp_root => dir('mason/stray')->absolute->stringify,
  # This works, too. -- rjbs, 2012-09-20
  # compiler_class => 'HTML::MasonX::Free::Compiler',
  # allow_stray_content => 0,
  compiler  => HTML::MasonX::Free::Compiler->new(allow_stray_content => 0),
);

sub output_for {
  my ($path) = @_;

  return unless my $comp = $interp->load( $path );

  my $output;

  $interp->make_request(
    comp => $comp,
    args => [
      mood => 'grumpy',
      mood => 'bored',
      tea  => 'weak',
    ],
    out_method => \$output,
  )->exec;

  1 while defined $output and chomp $output;
  $output;
}

sub output_is {
  my ($path, $output) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  is( output_for($path), $output, $path);
}

is(exception{output_for('/well-behaved')},   undef, "only a method? ok");
is(exception{output_for('/doc-section')},    undef, "only docs? ok");
is(exception{output_for('/commented-perl')}, undef, "only comments? ok");
is(exception{output_for('/extra-blanks')},   undef, "only blanks? ok");

{
  my $error = exception { output_for('/extra-text') };
  like($error, qr/text outside of block/, "we fatalized stray text");
}

{
  my $error = exception { output_for('/extra-perl') };
  like($error, qr/perl outside of block/, "we fatalized stray perl");
}

done_testing;
