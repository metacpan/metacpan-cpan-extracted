use lib qw|./lib ./blib/lib|;
use strict;
use warnings;
use Haineko::E;
use Test::More;

my $modulename = 'Haineko::E';
my $pkgmethods = [ 'new', 'p' ];
my $objmethods = [];

can_ok $modulename, @$pkgmethods;
my $errormesgs = [];

eval { require Haineko::Nyaa; }; push @$errormesgs, $@;
eval { keys %$errormesgs; }; push @$errormesgs, $@;
eval { die('Hard'); }; push @$errormesgs, $@;
eval { my $x = 0; my $y = 1 / $x; }; push @$errormesgs, $@;

is $modulename->new, undef;
isa_ok $modulename->new('neko'), $modulename;
isa_ok $modulename->p(), 'ARRAY';

for my $r ( @$errormesgs ) {

    my $e = $modulename->new( $r );
    my $d = $e->message;

    ok( $r, '$@ = '.$r );
    isa_ok( $e, $modulename );
    isa_ok( $e->mesg, 'ARRAY' );
    ok( $e->file, 'file() = '.$e->file );
    ok( $e->line, 'line() = '.$e->line );
    ok( $e->message, 'message() = '.$d );
    ok( $e->text, 'text() = '.$e->text );

    for my $v ( @{ $e->mesg } ) {
        ok( $v, 'mesg() = '.$v );
    }
}

done_testing;
__END__
