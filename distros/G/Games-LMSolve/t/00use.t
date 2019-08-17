#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 12;

# TEST*12
BEGIN
{
    use_ok("Games::LMSolve::Numbers");
    use_ok("Games::LMSolve::Base");
    use_ok("Games::LMSolve::Plank::Base");
    use_ok("Games::LMSolve::Plank::Hex");
    use_ok("Games::LMSolve::Alice");
    use_ok("Games::LMSolve::Tilt::Base");
    use_ok("Games::LMSolve::Tilt::Single");
    use_ok("Games::LMSolve::Tilt::Multi");
    use_ok("Games::LMSolve::Tilt::RedBlue");
    use_ok("Games::LMSolve::Input");
    use_ok("Games::LMSolve::Registry");
    use_ok("Games::LMSolve");
}
