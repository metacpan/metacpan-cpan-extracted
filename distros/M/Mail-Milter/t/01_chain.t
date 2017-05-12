#   $Header: /cvsroot/pmilter/Mail-Milter/t/01_chain.t,v 1.2 2004/03/06 11:46:51 rob_au Exp $

#   Copyright (c) 2002-2004 Todd Vierling <tv@duh.org> <tv@pobox.com>
#   Copyright (c) 2004 Robert Casey <rob.casey@bluebottle.com>
#
#   This file is covered by the terms in the file COPYRIGHT supplied with this
#   software distribution.


BEGIN {

    use Test::More 'tests' => 9;

    use_ok('Mail::Milter::Chain');
}


#   Perform some basic tests of the module constructor and available methods.

can_ok(
        'Mail::Milter::Chain',
                'accept_break',
                'create_callback',
                'dispatch',
                'new',
                'register'
);

ok( my $chain = Mail::Milter::Chain->new );
isa_ok( $chain, 'Mail::Milter::Chain' );


#   The testing of the accept_break method is fashioned around the described 
#   behaviour in the module POD.

eval { $chain->accept_break() };
ok( defined $@ );

is( $chain->accept_break(1), $chain );
is( $chain->accept_break(0), $chain );


#   Test the register function for the registration of new milter interfaces 
#   within the Mail::Milter::Chain object.

eval { $chain->register };
ok( defined $@ );
eval { $chain->register( '' ) };
ok( defined $@ );


1;


__END__
