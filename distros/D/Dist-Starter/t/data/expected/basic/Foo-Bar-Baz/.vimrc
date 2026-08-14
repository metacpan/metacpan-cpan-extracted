let $PERL5LIB = join( filter( map ( [ 't/lib', 'lib', 'local/lib/perl5' ], { idx, val -> getcwd() . '/' . val } ), { idx, val -> isdirectory( val ) } ), ':' )  . ':' . $PERL5LIB
let $PATH = join( filter( map ( [ 'local/bin' ], { idx, val -> getcwd() . '/' . val } ), { idx, val -> isdirectory( val ) } ), ':' )  . ':' . $PATH
let &rtp = fnamemodify( getcwd(), ':p' ) . '.vim,' . &rtp
