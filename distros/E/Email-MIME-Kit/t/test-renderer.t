#!perl
use strict;
use warnings;

use Test::More tests => 1;
use lib 't/lib';
use Email::MIME::Kit::Renderer::TestRenderer;

my $template =
  'This will say "I love pie": [% actor %] [% m_obj.verb() %] [% z_by("me") %]';

{ package V; sub new { bless {} }; sub verb { 'love' } }

my $output_ref = Email::MIME::Kit::Renderer::TestRenderer->render(
  \$template,
  {
    actor => 'I',
    m_obj => V->new,
    z_by  => sub { return 'pie' if $_[0] eq 'me'; return 'cake' },
  },
);

like(
  $$output_ref,
  qr{\Q"I love pie": I love pie\E\Z},
  "our test renderer is good enough for our tests",
);

