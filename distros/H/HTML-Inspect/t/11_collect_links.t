use strict;
use warnings;
use utf8;

use Test::More;
use File::Slurper qw(read_text);
use HTML::Inspect ();

# Testing collectLinks() thoroughly here
my $html      = read_text "t/data/links.html";
my $inspector = HTML::Inspect->new(location => 'https://html.spec.whatwg.org/multipage/dom.html', html_ref => \$html);

###
### collectReferences
###

my $refs = $inspector->collectReferences;

# See all deduplicated links from the parsed document.
# Are all links absolute(and canonical) URI instance?
note explain $refs;
is_deeply(
    $refs =>
        {
        'a_href' => [
            'https://whatwg.org/',
            'https://html.spec.whatwg.org/multipage/structured-data.html',
            'https://html.spec.whatwg.org/multipage/',
            'https://html.spec.whatwg.org/multipage/semantics.html',
            'https://html.spec.whatwg.org/multipage/dom.html',
            'https://html.spec.whatwg.org/multipage/references.html',
            'https://dom.spec.whatwg.org/'
        ],
        'area_href' => [
            'https://mozilla.org/',
            'https://developer.mozilla.org/',
            'https://developer.mozilla.org/docs/Web/Guide/Graphics',
            'https://developer.mozilla.org/docs/Web/CSS'
        ],
        'base_href' => [
            'https://html.spec.whatwg.org/multipage/'
        ],
        'embed_src' => [
            'https://html.spec.whatwg.org/media/cc0-videos/flower.mp4'
        ],
        'form_action' => [
            'https://html.spec.whatwg.org/multipage/'
        ],
        'iframe_src' => [
            'https://www.openstreetmap.org/export/embed.html?bbox=-0.004017949104309083,51.47612752641776,0.00030577182769775396,51.478569861898606&layer=mapnik'
        ],
        'img_src' => [
            'https://resources.whatwg.org/logo.svg',
            'https://html.spec.whatwg.org/media/examples/mdn-info.png'
        ],
        'link_href' => [
            'https://resources.whatwg.org/spec.css',
            'https://resources.whatwg.org/standard.css',
            'https://resources.whatwg.org/standard-shared-with-dev.css',
            'https://resources.whatwg.org/logo.svg',
            'https://html.spec.whatwg.org/styles.css'
        ],
        'script_src' => [
            'https://html.spec.whatwg.org/link-fixup.js',
            'https://html.spec.whatwg.org/html-dfn.js',
            'https://resources.whatwg.org/file-issue.js'
        ]
        },
    'all references are collected'
);

###
### collectLinks
###

my $links = $inspector->collectLinks;
#note explain $links;

is_deeply $links,
  {
    'icon' => [
        {'crossorigin' => 'use-credentials', 'href' => 'https://resources.whatwg.org/logo.svg'},
        {'href'        => 'https://resources.whatwg.org/logo.svg'}
    ],
    'stylesheet' => [
        {'crossorigin' => 'anonymous', 'href' => 'https://resources.whatwg.org/spec.css'},
        {'crossorigin' => '',          'href' => 'https://resources.whatwg.org/standard.css'},
        {'href'        => 'https://resources.whatwg.org/standard-shared-with-dev.css'},
        {'href'        => 'https://resources.whatwg.org/standard-shared-with-dev.css'},
        {'crossorigin' => '', 'href' => 'https://html.spec.whatwg.org/styles.css'}
    ]
  },
  'all link elements are collected';

done_testing;
