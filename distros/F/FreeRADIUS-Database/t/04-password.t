#!/usr/bin/perl

use warnings;
use strict;

$ENV{ FREERADIUS_DATABASE_CONFIG } = 't/freeradius_database.conf-dist';

use Test::More qw( no_plan );

BEGIN { use_ok('FreeRADIUS::Database') };

can_ok ( 'FreeRADIUS::Database', 'password' );

{ #getter

    my $rad     = FreeRADIUS::Database->new();
    my $pass    = $rad->password({ username => 'test1' });

    ok ( $pass eq 'test1', "password returns the correct password" );
}

{ #setter

    my $rad     = FreeRADIUS::Database->new();
    my $orig_pw = $rad->password({ username => 'test2' });

    my $new_pw  = 'testing';

    $rad->password({ username => 'test2', password => $new_pw });

    my $cur_pw = $rad->password({ username => 'test2' });

    ok ( $cur_pw ne $orig_pw, "The updated password does not match the original" );
    ok ( $cur_pw eq $new_pw,  "The updated password matches the new password" );

    my $last_pw = $rad->password({ username => 'test2', password => $orig_pw });
    ok ( $orig_pw eq $last_pw, "We can reset the password back to the original" );
}

{ # bad username

    my $rad     = FreeRADIUS::Database->new();
    
    my $pw      = $rad->password({ username => 'abaduser' });

    is( $pw, undef, "supplying a faulty username returns undef" );

}
