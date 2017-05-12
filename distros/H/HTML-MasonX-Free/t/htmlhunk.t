#!perl
use strict;
use warnings;

use Test::Fatal;
use Test::More;

use Path::Class qw(dir);
use HTML::Mason::Interp;
use HTML::MasonX::Free::Compiler;
use HTML::MasonX::Free::Component;
use HTML::MasonX::Free::Escape qw(html_escape);
use HTML::MasonX::Free::Request;
use HTML::MasonX::Free::Resolver;

my $interp = HTML::Mason::Interp->new(
  comp_root => '/-',
  compiler  => HTML::MasonX::Free::Compiler->new(
    default_escape_flags => 'html',
    default_method_to_call => 'main'
  ),
  request_class => 'HTML::MasonX::Free::Request',
  resolver  => HTML::MasonX::Free::Resolver->new({
    comp_class => 'HTML::MasonX::Free::Component',
    resolver_roots  => [
      [ comp_root => dir('mason/htmlhunk')->absolute->stringify ],
    ],
  }),
);

{
  package HTML::Mason::Commands;
  use HTML::MasonX::Free::Escape 'html_hunk';
}

$interp->set_escape('h' => \&html_escape);
$interp->set_escape('html' => \&html_escape);

sub output_for {
  my ($path, $arg) = @_;

  return unless my $comp = $interp->load( $path );

  my $output;

  $interp->make_request(
    comp => $comp,
    args => $arg,
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

my $out = output_for('/generic', [ foo => 'D&D' ]);
like($out, qr/(?m:^PFOO: D&amp;D)/, "by default, we HTML escape");
like($out, qr/(?m:^HFOO: D&D)/,     "but we can use html_hunk to override");

done_testing;
