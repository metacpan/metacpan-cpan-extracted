#!perl -w

use strict;
use FindBin qw($Bin);
use File::Spec::Functions qw(catdir catfile);
use Test::More tests => 10;
use HTML::Mason::Interp;

BEGIN { use_ok('MasonX::Interp::WithCallbacks') }

my $key = 'myCallbackTester';
my $cbs = [];

##############################################################################
# Set up callback functions.
##############################################################################
# Callback to test the value of the package key attribute.
sub test_pkg_key {
    my $cb = shift;
    my $params = $cb->params;
    $params->{result} .= $cb->pkg_key;
}

push @$cbs, { pkg_key => $key,
              cb_key  => 'test_pkg_key',
              cb      => \&test_pkg_key
            },
            { pkg_key => $key . '_more',
              cb_key  => 'test_pkg_key',
              cb      => \&test_pkg_key
            };

##############################################################################
# Callback to test the value returned by the class_key method.
sub test_class_key {
    my $cb = shift;
    my $params = $cb->params;
    $params->{result} .= $cb->class_key;
}
push @$cbs, { pkg_key => $key,
              cb_key  => 'test_class_key',
              cb      => \&test_class_key
            },
            { pkg_key => $key. '_more',
              cb_key  => 'test_class_key',
              cb      => \&test_class_key
            };

##############################################################################
# Callback to test the value of the trigger key attribute.
sub test_trigger_key {
    my $cb = shift;
    my $params = $cb->params;
    $params->{result} .= $cb->trigger_key;
}

push @$cbs, { pkg_key => $key,
              cb_key  => 'test_trigger_key',
              cb      => \&test_trigger_key
            },
            { pkg_key => $key . '_more',
              cb_key  => 'test_trigger_key',
              cb      => \&test_trigger_key
            };

##############################################################################
# Set up the Interp object.
##############################################################################
my $outbuf;
ok( my $interp = MasonX::Interp::WithCallbacks->new
    ( comp_root  => catdir($Bin, qw(htdocs)),
      callbacks  => $cbs,
      out_method => \$outbuf ),
    "Construct interp object" );
isa_ok($interp, 'MasonX::Interp::WithCallbacks');
isa_ok($interp, 'HTML::Mason::Interp');

my $comp = '/dhandler';

##############################################################################
# Test the callbacks themselves.
##############################################################################
# Test the package key.
$interp->exec($comp, "$key|test_pkg_key_cb" => 1 );
is( $outbuf, $key, "Check pkg key" );
$outbuf = '';

# And multiple package keys.
$interp->exec($comp,
              "$key|test_pkg_key_cb1" => 1,
              "$key\_more|test_pkg_key_cb2" => 1,
              "$key|test_pkg_key_cb3" => 1,
             );

is( $outbuf, "$key$key\_more$key", "Check pkg key again" );
$outbuf = '';

##############################################################################
# Test the class key.
$interp->exec($comp, "$key|test_class_key_cb" => 1 );
is( $outbuf, $key, "Check class key" );
$outbuf = '';

# And multiple class keys.
$interp->exec($comp, "$key|test_class_key_cb1" => 1,
            "$key\_more|test_class_key_cb2" => 1,
            "$key|test_class_key_cb3" => 1,
          );
is( $outbuf, "$key$key\_more$key", "Check class key again" );
$outbuf = '';

##############################################################################
# Test the trigger key.
$interp->exec($comp, "$key|test_trigger_key_cb" => 1 );
is( $outbuf, "$key|test_trigger_key_cb", "Check trigger key" );
$outbuf = '';

# And multiple trigger keys.
$interp->exec($comp, "$key|test_trigger_key_cb1" => 1,
            "$key\_more|test_trigger_key_cb2" => 1,
            "$key|test_trigger_key_cb3" => 1,);

is( $outbuf, "$key|test_trigger_key_cb1$key\_more|" .
    "test_trigger_key_cb2$key|test_trigger_key_cb3",
    "Check trigger key again" );
$outbuf = '';

1;
__END__
