package Kite::MyModule1;

use lib qw( ./lib ../lib );

use Kite::Base;
use base qw( Kite::Base );    
use vars qw( $ERROR $PARAMS );

$PARAMS = {
    TITLE  => 'Default Title',
    AUTHOR => undef,		# no default
    _COUNT => 1,		# private variable
};	


#------------------------------------------------------------------------
package Kite::MyModule2;

use lib qw( ./lib ../lib );

use Kite::Base;
use base qw( Kite::Base );    
use vars qw( $ERROR $PARAMS );

$PARAMS = {
    TITLE  => 'Default Title',
    AUTHOR => undef,		# no default
    _COUNT => 1,		# private variable
};	

sub init {
    my ($self, $config) = @_;
    $self->SUPER::init($config) 
	|| return undef;
    $self->{ _NEWCOUNT } = $self->{ _COUNT } + 10;
};


#------------------------------------------------------------------------
package main;

print "1..15\n";
my $n = 0;

sub ok {
    shift or print "not ";
    print "ok ", ++$n, "\n";
}

my $mod1 = Kite::MyModule1->new(title => 'The Title')
    || die $Kite::MyModule1::ERROR, "\n";

ok(1);
ok( $mod1->{ TITLE } eq 'The Title' );
ok( $mod1->title() eq 'The Title' );
ok( exists $mod1->{ AUTHOR } );
ok( ! defined $mod1->{ AUTHOR } );
ok( $mod1->{ _COUNT } == 1 );
eval {
    $mod1->_count();
};
ok( $@ );
ok( $@ =~ /^attempt to access private member _count at/ );

my $mod2 = Kite::MyModule2->new(TITLE => 'The New Title', author => 'abw')
    || die "mod2 error: ", $Kite::MyModule2::ERROR, "\n";

ok(1);
ok( $mod2->{ TITLE } eq 'The New Title' );
ok( $mod2->{ AUTHOR } eq 'abw' );
ok( $mod2->{ _COUNT } == 1 );
ok( $mod2->{ _NEWCOUNT } == 11 );

ok( $mod2->title('Changed Title') );
ok( $mod2->title() eq 'Changed Title' );


