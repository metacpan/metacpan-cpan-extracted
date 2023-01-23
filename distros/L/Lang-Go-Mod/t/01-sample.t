package main;
use File::Spec;
use Test2::V0;
use Lang::Go::Mod qw(read_go_mod);

my $samples_path = File::Spec->catfile( File::Spec->curdir(), 't',  'samples' );
my $go_mod_path  = File::Spec->catfile( $samples_path, '01', 'go.mod' );
my $m;
ok(
    lives {
        $m = read_go_mod($go_mod_path);
    }
  ) or note($@);

is( ref($m), 'HASH', 'returned ref is hash' );
is( $m->{module}, 'github.com/example/my-project', 'module label' );
is( $m->{go}, '1.16', 'go version label' );

is( $m->{retract}->{'[v1.0.0,v1.2.0]'}, 1, 'retract' );
is( $m->{retract}->{'v1.3.0'}, 1, 'retract' );
is( $m->{retract}->{'v1.4.0'}, 1, 'retract' );
is( $m->{retract}->{'[v1.5.0,v1.6.0]'}, 1, 'retract' );

is( $m->{exclude}->{'example.com/whatmodule'}, ['v1.4.0'], 'exclude' );
is( $m->{exclude}->{'example.com/thismodule'}, ['v1.3.0'], 'exclude' );
is( $m->{exclude}->{'example.com/thatmodule'},
    [ 'v1.2.0', 'v1.1.0' ], 'exclude' );

is( $m->{replace}->{'github.com/example/my-project/pkg/app'},
    './pkg/app', 'replace' );
is( $m->{replace}->{'github.com/example/my-project/pkg/app/client'},
    './pkg/app/client', 'replace' );
is( $m->{replace}->{'github.com/example/my-project/pkg/old'},
    './pkg/new', 'replace' );

is( $m->{'require'}->{'github.com/google/uuid'}, 'v1.2.0', 'require' );
is( $m->{'require'}->{'github.com/dgrijalva/jwt-go'},
    'v3.2.0+incompatible', 'require' );
is( $m->{'require'}->{'golang.org/x/sys'},
    'v0.0.0-20210510120138-977fb7262007', 'require' );
is( $m->{'require'}->{'github.com/example/greatmodule'}, 'v1.1.1', 'require' );

done_testing;

1;
