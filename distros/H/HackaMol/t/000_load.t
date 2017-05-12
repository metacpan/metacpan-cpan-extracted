#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('HackaMol');
    use_ok('HackaMol::Atom');
    use_ok('HackaMol::AtomGroup');
    use_ok('HackaMol::Bond');
    use_ok('HackaMol::Angle');
    use_ok('HackaMol::Dihedral');
    use_ok('HackaMol::Molecule');
}

done_testing;
