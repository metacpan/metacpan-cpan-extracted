#!perl -w

use strict;
use FindBin qw($Bin);
use File::Spec::Functions qw(catdir catfile);
use Test::More tests => 28;
use HTML::Mason::Interp;

BEGIN { use_ok('MasonX::Interp::WithCallbacks') }

my $key = 'myCallbackTester';
my $cbs = [];

##############################################################################
# Set up callback functions.
##############################################################################
# Priority callback.
sub priority {
    my $cb = shift;
    isa_ok( $cb, 'Params::Callback');
    my $params = $cb->params;
    my $val = $cb->value;
    $val = $cb->priority if $val eq 'def';
    $params->{result} .= " $val";
}

sub chk_priority {
    my $cb = shift;
    isa_ok( $cb, 'Params::Callback');
    my $val = $cb->value;
    is( $cb->priority, $val, "Check priority value '$val'" );
}

sub def_priority {
    my $cb = shift;
    isa_ok( $cb, 'Params::Callback');
    is( $cb->priority, 5, "Check default priority" );
}

push @$cbs, { pkg_key => $key,
              cb_key  => 'priority',
              cb      => \&priority,
              priority => 6
            },
            { pkg_key => $key,
              cb_key  => 'chk_priority',
              cb      => \&chk_priority,
              priority => 2
            },
            { pkg_key => $key,
              cb_key  => 'def_priority',
              cb      => \&def_priority,
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
# Test the priority ordering.
$interp->exec($comp,
              "$key|priority_cb0" => 0,
              "$key|priority_cb2" => 2,
              "$key|priority_cb9" => 9,
              "$key|priority_cb7" => 7,
              "$key|priority_cb1" => 1,
              "$key|priority_cb4" => 4,
              "$key|priority_cb"  => 'def' );
is( $outbuf, " 0 1 2 4 6 7 9", "Check simple result" );
$outbuf = '';


##############################################################################
# Test the default priority.
$interp->exec($comp, "$key|def_priority_cb" => 1);

##############################################################################
# Check various priority values.
$interp->exec($comp,  "$key|chk_priority_cb0" => 0,
                "$key|chk_priority_cb2" => 2,
                "$key|chk_priority_cb9" => 9,
                "$key|chk_priority_cb7" => 7,
                "$key|chk_priority_cb1" => 1,
                "$key|chk_priority_cb4" => 4,
                "$key|chk_priority_cb"  => 2 );

1;
__END__
