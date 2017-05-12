# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;
use vars
  qw($READONLY_GLOBAL $DIE_ON_WRITE_GLOBAL $READWRITE_GLOBAL $WG_GLOBAL $WG_GLOBAL2);

use Test;

sub warning_ok ( &@ );

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; plan tests => 26 }
use Devel::WarnGlobal
  '$WG_GLOBAL'  => \&get_wg_global,
  '$WG_GLOBAL2' => [ \&get_wg_global2, \&set_wg_global2 ];
use Devel::WarnGlobal::Scalar;
ok(1);

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
my $ro = tie $READONLY_GLOBAL, 'Devel::WarnGlobal::Scalar',
  { get => \&get_readonly, name => '$READONLY_GLOBAL' };
tie $DIE_ON_WRITE_GLOBAL, 'Devel::WarnGlobal::Scalar',
  { get => \&get_readonly, die_on_write => 1 };
tie $READWRITE_GLOBAL, 'Devel::WarnGlobal::Scalar',
  { get => \&get_readwrite, set => \&set_readwrite };

warning_ok {
    my $foo = $READONLY_GLOBAL;
    ok( $foo, 5 );
}
"Global '\$READONLY_GLOBAL' was read-accessed at $0 line 37.\n";

sub get_readonly {
    return 5;
}

warning_ok {
    $READONLY_GLOBAL = 37;
}
"Global '\$READONLY_GLOBAL' was write-accessed at $0 line 47.\n";

warning_ok {
    my $bar = $READONLY_GLOBAL;
    $ro->warn(0);
    my $bar2 = $READONLY_GLOBAL;
    $ro->warn(1);
    my $bar3 = $READONLY_GLOBAL;
}
"Global '\$READONLY_GLOBAL' was read-accessed at $0 line 52.\n",
  "Global '\$READONLY_GLOBAL' was read-accessed at $0 line 56.\n";

eval { $DIE_ON_WRITE_GLOBAL = 33; };
ok( $@, "Attempt to write-access a global(read-only) at $0 line 61.\n" );

warning_ok {
    my $foo = $READWRITE_GLOBAL;
    ok( $foo, 27 );
    $READWRITE_GLOBAL = 33;
    $foo              = $READWRITE_GLOBAL;
    ok( $foo, 33 );
}
"A global was read-accessed at $0 line 65.\n",
  "A global was write-accessed at $0 line 67.\n",
  "A global was read-accessed at $0 line 68.\n";

warning_ok {
    my $foo = $WG_GLOBAL;
    ok( $foo, 'Sqweenookle!' );
}
"Global '\$WG_GLOBAL' was read-accessed at $0 line 76.\n";

warning_ok {
    eval {
        my $dh = tied $DIE_ON_WRITE_GLOBAL;
        $dh->die_on_write(0);
        $DIE_ON_WRITE_GLOBAL = 99;
    };
    ok( length($@) == 0 );
}
"A global was write-accessed at $0 line 85.\n";
eval {
    my $dh = tied $DIE_ON_WRITE_GLOBAL;
    $dh->die_on_write(1);
    $DIE_ON_WRITE_GLOBAL = "That's a mean bunny!";
};
ok( $@, "Attempt to write-access a global(read-only) at $0 line 93.\n" );

warning_ok {
    my $bar = $WG_GLOBAL2;
    ok( $bar, 'Tom Servo' );
    $WG_GLOBAL2 = 'Crow';
    my $bar2 = $WG_GLOBAL2;
    ok( $bar2, 'Crow' );

}
"Global '\$WG_GLOBAL2' was read-accessed at $0 line 98.\n",
  "Global '\$WG_GLOBAL2' was write-accessed at $0 line 100.\n",
  "Global '\$WG_GLOBAL2' was read-accessed at $0 line 101.\n";

TEST: {
    my $tied = tied $READONLY_GLOBAL;
    $tied->warn(0);
    ok( $tied->warn(), 0 );
    $tied->warn(1);
    ok( $tied->warn(), 1 );
    $tied->die_on_write(1);
    ok( $tied->die_on_write(), 1 );
    $tied->die_on_write(0);
    ok( $tied->die_on_write(), 0 );
}

############################# Subroutines #########################

sub warning_ok ( &@ ) {
    my ( $test_sub, @warnings ) = @_;

    my @warn_messages = ();
    local $SIG{'__WARN__'} = sub { push( @warn_messages, $_[0] ) };
    &$test_sub;
    foreach ( 0 .. $#warnings ) {
        ok( $warn_messages[$_], $warnings[$_] );
    }
}

BEGIN {
    my $get_thingy = 27;

    sub get_readwrite {
        return uc($get_thingy);
    }

    sub set_readwrite {
        $get_thingy = $_[0];
    }

}

sub get_wg_global {
    return "Sqweenookle!";
}

BEGIN {
    my $wg2_var = "Tom Servo";

    sub get_wg_global2 {
        return $wg2_var;
    }

    sub set_wg_global2 {
        $wg2_var = $_[0];
    }

}

