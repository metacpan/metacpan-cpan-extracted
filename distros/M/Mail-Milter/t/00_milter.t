#   $Header: /cvsroot/pmilter/Mail-Milter/t/00_milter.t,v 1.1 2004/02/26 11:26:53 rob_au Exp $

#   Copyright (c) 2002-2004 Todd Vierling <tv@duh.org> <tv@pobox.com>
#   Copyright (c) 2004 Robert Casey <rob.casey@bluebottle.com>
#
#   This file is covered by the terms in the file COPYRIGHT supplied with this
#   software distribution.


BEGIN {

    use Test::More 'tests' => 2;

    use_ok('Mail::Milter');
}


#   Perform some basic tests of the available methods for the Mail::Milter 
#   module.

can_ok(
        'Mail::Milter',
                'resolve_callback'
);


1;


__END__
