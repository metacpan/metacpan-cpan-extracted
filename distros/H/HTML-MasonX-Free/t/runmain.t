#!perl
use strict;
use warnings;

use Test::Fatal;
use Test::More;

use Path::Class qw(dir);
use HTML::Mason::Interp;
use HTML::MasonX::Free::Compiler;
use HTML::MasonX::Free::Request;
use HTML::MasonX::Free::Resolver;
use HTML::MasonX::Free::Component;

my $interp = HTML::Mason::Interp->new(
  comp_root => '/-',
  compiler  => HTML::MasonX::Free::Compiler->new(
    default_method_to_call => 'main'
  ),
  request_class => 'HTML::MasonX::Free::Request',
  resolver  => HTML::MasonX::Free::Resolver->new({
    comp_class => 'HTML::MasonX::Free::Component',
    resolver_roots  => [
      [ comp_root => dir('mason/runmain')->absolute->stringify ],
    ],
  }),
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

  1 while chomp $output;
  $output;
}

sub output_is {
  my ($path, $output) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  is( output_for($path), $output, $path);
}

output_is('/well-behaved',   "This is the main method.");
output_is('/doc-section',    "This is the main method.");
output_is('/commented-perl', "This is the main method.");
output_is('/extra-blanks',   "This is the main method.");
output_is('/extra-text',     "This is the main method.");
output_is('/extra-perl',     "This is the main method.");

output_is('/calls-wb',       "This is the main method.");

output_is('/revrev-method',  "This is the main method.");
output_is('/revrev',         "This is the main method.");

done_testing;
