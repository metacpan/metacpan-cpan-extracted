use strict;
use warnings;

use Test::Most;
#use XXX;

use Doc::Simply;
use Doc::Simply::Extractor;
use Doc::Simply::Assembler;
use Doc::Simply::Parser;
use Doc::Simply::Render::HTML;

plan qw/no_plan/;

my $source = <<'_END_';
/* 
 * @head2 Icky nesting
 * Some content
 *
 * @head1 Hello, World.
 *
 * @head2 Yikes. 
 * Some more content
 * With some *markdown* content!
 *
 *      And some more
 *      And some inline code
 *
 */

/* Ignore this...
*/

/* @body 
 * ...but grab **this**!
        */
_END_

my $extractor = Doc::Simply::Extractor::SlashStar->new;
my $comments = $extractor->extract($source);

my $assembler = Doc::Simply::Assembler->new;
my $blocks = $assembler->assemble($comments);

my $parser = Doc::Simply::Parser->new;
my $document = $parser->parse($blocks);

my $formatter = Doc::Simply::Render::HTML->new;
my $render = $formatter->render(document => $document);

like($render, qr/reset-fonts-grids\.css/);
like($render, qr/base\/base-min\.css/);
unlike($render, qr/Ignore this/);
like($render, qr/\.\.\.but grab <strong>this<\/strong>!/);
like($render, qr{<li class="index-head2"><a href="#Icky nesting">Icky nesting</a></li>});
like($render, qr{<h2 class="content-head2 content-head"><a name="Icky nesting"></a>Icky nesting</h2>});
