use strict;
use warnings;

use Test::More tests => 6;

use File::Spec;
use JSAN::ServerSide;


my %paths
    = map { $_ => File::Spec->catfile( '', 'files', $_ . '.js' ) } qw( A B C D E F G );

my %dependencies =
    ( $paths{A} => [ qw( B C ) ],
      $paths{B} => [ 'C' ],
      $paths{C} => [],
      $paths{D} => [ qw( E F G ) ],
      $paths{E} => [ 'D' ],
      $paths{F} => [],
      $paths{G} => [],
    );

{
    no warnings 'redefine';
    *JSAN::Parse::FileDeps::library_deps =
        sub { shift;
              return @{ $dependencies{+shift} } };

    *JSAN::ServerSide::_last_mod = sub { 1 };

}

{
    my $js = JSAN::ServerSide->new( js_dir => '/files', uri_prefix => '/uris' );
    $js->add('A');

    is_deeply( [ $js->uris() ],
               [ '/uris/C.js', '/uris/B.js', '/uris/A.js' ],
               'uris for A' );
    is_deeply( [ $js->files() ],
               [ $paths{C}, $paths{B}, $paths{A} ],
               'files for A' );
}

{
    my $js = JSAN::ServerSide->new( js_dir => '/files', uri_prefix => '/uris' );

    $js->add('D');

    is_deeply( [ $js->uris() ],
               [ '/uris/E.js', '/uris/F.js', '/uris/G.js', '/uris/D.js' ],
               'uris for D' );
    is_deeply( [ $js->files() ],
               [ $paths{E}, $paths{F}, $paths{G}, $paths{D} ],
               'files for D' );
}

{
    my $js = JSAN::ServerSide->new( js_dir => '/files', uri_prefix => '/uris' );

    $js->add('E');

    is_deeply( [ $js->uris() ],
               ['/uris/F.js', '/uris/G.js', '/uris/D.js', '/uris/E.js' ],
               'uris for E' );
    is_deeply( [ $js->files() ],
               [$paths{F}, $paths{G}, $paths{D}, $paths{E} ],
               'files for E' );
}
