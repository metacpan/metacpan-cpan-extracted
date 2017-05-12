#!perl
use strict;
use warnings;

use Test::More;

use Path::Class qw(dir);
use HTML::Mason::Interp;
use HTML::MasonX::Free::Compiler;
use HTML::MasonX::Free::Component;
use HTML::MasonX::Free::Request;
use HTML::MasonX::Free::Resolver;

my $resolver = HTML::MasonX::Free::Resolver->new({
  comp_class    => 'HTML::MasonX::Free::Component',
  add_next_call => 0,
  resolver_roots => [
    [  subderived => dir('mason/ai-rm/subderived')->absolute->stringify ],
    [  derived    => dir('mason/ai-rm/derived')->absolute->stringify    ],
    [  base       => dir('mason/ai-rm/base')->absolute->stringify       ],
  ],
});

my $interp = HTML::Mason::Interp->new(
  comp_root => '/-',
  resolver  => $resolver,
  request_class => 'HTML::MasonX::Free::Request',
  compiler  => HTML::MasonX::Free::Compiler->new(
    allow_stray_content    => 0,
    default_method_to_call => 'main',
  ),
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

output_is('/d-only', "D-Only");
output_is('/b-only', "B-Only");

output_is('/derived=/person', "=== PERSON ===\nBob\n\nThis is extra.");
output_is('/person', "=== PERSON ===\nThe Honorable Bob\n\nThis is extra.");

output_is('/base=/table', "Favorite drink: milk\nFavorite fruit: apple");
output_is('/table', "Favorite drink: milk\nFavorite fruit: fig");
output_is('/subderived=/table', "Favorite drink: milk\nFavorite fruit: fig");

# If there's nothing there, we end up with only the "next" call, so it's like
# calling the one that DOES exist. -- rjbs, 2012-09-20
output_is('/derived=/table', "Favorite drink: milk\nFavorite fruit: apple");

output_is('/album', "Brutal Youth by Elvis Costello");
output_is('/derived=/album', "Imperial Bedroom by Elvis Costello");

# Weird, but okay.  If you ask for something that doesn't exist at the most
# basic level, it ain't there. -- rjbs, 2012-09-20
output_is('/base=/album', undef);

output_is('/calls-film', "The Blockbuster Movie");

output_is('/base=/film', "Movie");

output_is('/film', "The Blockbuster Movie");

done_testing;
