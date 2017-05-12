
use strict;
use warnings;
use Test::NoWarnings;
use Test::More tests => 37;

# load your module...
use lib './lib';
use File::Util qw( atomize_path );

# automated empty subclass test
my $atomized = {
   'C:\foo\bar\baz.txt'   => { root => 'C:\\', path => 'foo\bar',       file => 'baz.txt'     },
   '/foo/bar/baz.txt'     => { root => '/',    path => 'foo/bar',       file => 'baz.txt'     },
   ':a:b:c:d:e:f:g.txt'   => { root => ':',    path => 'a:b:c:d:e:f',   file => 'g.txt'       },
   './a/b/c/d/e/f/g.txt'  => { root => '',     path => './a/b/c/d/e/f', file => 'g.txt'       },
   '../wibble/wombat.ini' => { root => '',     path => '../wibble',     file => 'wombat.ini'  },
   '..\woot\noot.doc'     => { root => '',     path => '..\woot',       file => 'noot.doc'    },
   '../../zoot.conf'      => { root => '',     path => '../..',         file => 'zoot.conf'   },
   '/root'                => { root => '/',    path => '',              file => 'root'        },
   '/etc/sudoers'         => { root => '/',    path => 'etc',           file => 'sudoers'     },
   '/'                    => { root => '/',    path => '',              file => '',           },
   'D:\\'                 => { root => 'D:\\', path => '',              file => '',           },
   'D:\autorun.inf'       => { root => 'D:\\', path => '',              file => 'autorun.inf' },
};

for my $path ( keys %$atomized ) {

   my @atoms = atomize_path( $path );

   is shift @atoms,
      $atomized->{ $path }{root},
      qq(atomized root matches "$atomized->{ $path }{root}") ;

   is shift @atoms,
      $atomized->{ $path }{path},
      qq(atomized path matches "$atomized->{ $path }{path}") ;

   is shift @atoms,
      $atomized->{ $path }{file},
      qq(atomized filename matches "$atomized->{ $path }{file}") ;
}

exit;

__END__

Expected (correct) output from atomize_path()

-------------------------------------------------------------------------------
INPUT                     ROOT       PATH-COMPONENT            FILE/DIR
-------------------------------------------------------------------------------
C:\foo\bar\baz.txt        C:\        foo\bar                   baz.txt
/foo/bar/baz.txt          /          foo/bar                   baz.txt
:a:b:c:d:e:f:g.txt        :          a:b:c:d:e:f               g.txt
./a/b/c/d/e/f/g.txt                  ./a/b/c/d/e/f             g.txt
../wibble/wombat.ini                 ../wibble                 wombat.ini
..\woot\noot.doc                     ..\woot                   noot.doc
../../zoot.conf                      ../..                     zoot.conf
/root                     /                                    root
/etc/sudoers              /          etc                       sudoers
/                         /
D:\                       D:\
D:\autorun.inf            D:\                                  autorun.inf
