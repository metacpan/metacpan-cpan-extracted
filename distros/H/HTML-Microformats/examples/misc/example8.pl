#!/usr/bin/perl

use lib "lib";
use HTML::Microformats;
use strict;
use JSON;
use LWP::Simple qw(get);
use Data::Dumper;
use RDF::TrineShortcuts;

my $uri  = 'http://example.com/chips';
my $html = <<HTML;

<ol class='xoxo' id='ds'>
  <li>item 1
    <dl>
      <dt>description</dt>
        <dd>This item represents the main point we're trying to make.</dd>
    </dl>
    <ul>
      <li>subpoint a<ul><li><a title="Hello" href="/">hello world</a></li></ul></li>
      <li>subpoint b</li>
    </ul>
  </li>
</ol>

<div class="hrecipe">
    <h1 class="fn">Pommes Frites</h1>
    <p class="summary">
        Pommes frites originate in outer space. They are served hot.<br />
        This recipe is only an example. Don't try this at home!
    </p>
    <p>
        Contributed by <span class="author">CJ Tom</span> and the
        <span class="author vcard"><a class="url fn" href="http://example.com">Cooky Gang</a></span>.
    </p>
     <p>Published <span class="published"><span class="value-title" title="2008-10-14T10:05:37-01:00"> </span>14. Oct 2008</span></p>
    <img src="/img/pommes.png" class="photo" width="100" height="100" alt="Pommes Frites"/>
    <h2>Ingredients</h2>
    <ul>
        <li class="ingredient">
            500 gramme potatoes, hard cooking.
        </li>
        <li class="ingredient">
            1 spoonful of salt
        </li>
        <li>
            You may want to provide some 
            <span class="ingredient">Ketchup and Mayonnaise</span>
            as well.
        </li>
    </ul>
    <h2>Instructions</h2>
    <ul class="instructions">
        <li>First wash the potatoes.</li>
        <li>Then slice and dice them and put them in boiling fat.</li>
        <li>After a few minutes take them out again.</li>
    </ul>
    <h2>Further details</h2>
    <p>Enough for <span class="yield">12 children</span>.</p>
    <p>Preparation time is approximately 
        <span class="duration"><span class="value-title" title="PT1H30M"> </span>90 min</span>
    </p>
    <p>Add <span  class="duration"><span class="value-title" title="PT30M"></span>half an hour</span> to prepare your homemade Ketchup.</p>
    <p>This recipe is <a href="http://www.example.com/tags/difficulty/easy" rel="tag">easy</a> and <a href="http://www.example.com/tags/tastyness/delicious" rel="tag">delicious</a>.</p>
    <p>
        <span class="nutrition">
        Pommes Frites have more than 
        1000 Joules Energy</span>, 
        while Ketchup and Mayonnaise have 
        <span class="nutrition">0 vitamins</span>.
    </p>
</div>

	<div class="vcard">
                <div class="adr">
                        <span class="type">intl</span>:
                        <span class="fn country-name">France</span>
                        <span class="geo">
                                12.34,   56.78
                        </span>
                </div>
        </div>


HTML
utf8::upgrade($html);

my $doc  = HTML::Microformats->new_document($html, $uri);
$doc->assume_all_profiles;

print $doc->json(pretty=>1, convert_blessed=>1);
print rdf_string($doc->model, 'rdfxml');
