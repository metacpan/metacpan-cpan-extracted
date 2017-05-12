# $Id: error.t,v 1.1 2005/12/14 04:22:16 ben Exp $
use Test;
use strict;

BEGIN { plan tests => 16 }

use GD::Graph::Error;
ok(1);
# Can't/Shouldn't instantiate a GD::Graph::Error object. Will use
# GD::Graph::Data instead
use GD::Graph::Data;
ok(1);

print "# Check inheritance\n";
my $error = GD::Graph::Data->new();
ok($error);
ok($error->isa("GD::Graph::Error"));
ok($error->isa("GD::Graph::Data"));

print "# Check error and warning level\n";
ok(! $error->has_error);
ok(! $error->has_warning);

print "# Set some warnings and errors\n";
$error->_set_error([2, "One warning"], 
                   [0, "Two warning"], 
                   [1, "Three warning"]);
ok($error->has_warning, 3);
ok($error->has_error, 0);

print "# Set more errors\n";
$error->_set_error([9, "One error"]);
ok($error->has_warning, 3);
ok($error->has_error, 1);

print "# Clear errors\n";
$error->clear_errors;
ok(! $error->has_warning);
ok(! $error->has_error);

print "# Set critical error\n";
eval { $error->_set_error([11, "Critical error"]) };
ok($@, qr/^Critical error/);
ok(! $error->has_warning);
ok($error->has_error, 1);

