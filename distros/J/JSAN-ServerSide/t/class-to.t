use strict;
use warnings;

use Test::More tests => 6;


use JSAN::ServerSide;

my $js = JSAN::ServerSide->new( js_dir => '/usr/local/js',
                                uri_prefix => '/site/js',
                              );

is( $js->_class_to_uri('JSAN'), '/site/js/JSAN.js',
    'class to uri: JSAN' );

is( $js->_class_to_uri('DOM.Ready'), '/site/js/DOM/Ready.js',
    'class to uri: DOM.Ready' );

is( $js->_class_to_uri('With.Many.Levels.Of.Namespace'), '/site/js/With/Many/Levels/Of/Namespace.js',
    'class to uri: With.Many.Levels.Of.Namespace' );


like( $js->_class_to_file('JSAN'),
      qr{[\\/]usr[\\/]local[\\/]js[\\/]JSAN\.js},
      'class to file: JSAN' );

like( $js->_class_to_file('DOM.Ready'),
      qr{[\\/]usr[\\/]local[\\/]js[\\/]DOM[\\/]Ready\.js},
      'class to file: DOM.Ready' );

like( $js->_class_to_file('With.Many.Levels.Of.Namespace'),
      qr{[\\/]usr[\\/]local[\\/]js[\\/]With[\\/]Many[\\/]Levels[\\/]Of[\\/]Namespace\.js},
      'class to File: With.Many.Levels.Of.Namespace' );
