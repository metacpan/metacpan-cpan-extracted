#!perl -w

use strict;
use FindBin qw($Bin);
use File::Spec::Functions qw(catdir catfile);
use Test::More;
use HTML::Mason::Interp;
my $base_key = 'OOTester';
my $comp = '/dhandler';

##############################################################################
# Figure out if the current configuration can handle OO callbacks.
BEGIN {
    plan skip_all => 'Object-oriented callbacks require Perl 5.6.0 or later'
      if $] < 5.006;

    plan skip_all => 'Attribute::Handlers and Class::ISA required for' .
      ' object-oriented callbacks'
      unless eval { require Attribute::Handlers }
      and eval { require Class::ISA };

    plan tests => 16;
}

##############################################################################
# Set up the callback class.
##############################################################################
package Params::Callback::TestObjects;

use strict;
use base 'Params::Callback';
__PACKAGE__->register_subclass( class_key => $base_key);
use Params::CallbackRequest::Exceptions abbr => [qw(throw_cb_exec)];

sub simple : Callback {
    my $self = shift;
    main::isa_ok($self, 'Params::Callback');
    main::isa_ok($self, __PACKAGE__);
    my $params = $self->params;
    $params->{result} = 'Simple Success';
}

sub lowerit : PostCallback {
    my $self = shift;
    my $params = $self->params;
    if ($params->{do_lower}) {
        main::isa_ok($self, 'Params::Callback');
        main::isa_ok($self, __PACKAGE__);
        $params->{result} = lc $params->{result};
    }
}

1;
##############################################################################
# Set up another callback class to test the default class key.
package Params::Callback::TestKey;
use strict;
use base 'Params::Callback';
__PACKAGE__->register_subclass;

sub my_key : Callback {
    my $self = shift;
    main::is($self->pkg_key, __PACKAGE__, "Check package key" );
    main::is($self->class_key, __PACKAGE__, "Check class key" );
}

##############################################################################
# Back in the real world...
##############################################################################
package main;
use strict;
use_ok('MasonX::Interp::WithCallbacks');

##############################################################################
# Set up a functional callback we can use.
sub another {
    my $cb = shift;
    main::isa_ok($cb, 'Params::Callback');
    my $params = $cb->params;
    $params->{result} = 'Another Success';
}

##############################################################################
# And a functional request callback.
sub presto {
    my $cb = shift;
    main::isa_ok($cb, 'Params::Callback');
    my $params = $cb->params;
    $params->{result} = 'PRESTO' if $params->{do_presto};
}

##############################################################################
# Construct the combined callback exec object.
my $outbuf;
ok( my $interp = MasonX::Interp::WithCallbacks->new
    (comp_root  => catdir($Bin, qw(htdocs)),
     out_method => \$outbuf,
     callbacks => [{ pkg_key => 'foo',
                      cb_key => 'another',
                      cb => \&another}],
      cb_classes => 'ALL',
      pre_callbacks => [\&presto] ),
    "Construct combined CBExec object" );

##############################################################################
# Make sure the functional callback works.
$interp->exec($comp, 'foo|another_cb' => 1);
is( $outbuf, 'Another Success', "Check functional result" );
$outbuf = '';

##############################################################################
# Make sure OO callback works.
$interp->exec($comp, "$base_key|simple_cb" => 1);
is( $outbuf, 'Simple Success', "Check OO result" );
$outbuf = '';

##############################################################################
# Make sure that functional and OO request callbacks execute, too.
$interp->exec($comp,
              do_lower => 1,
              do_presto => 1);
is( $outbuf, 'presto', "Check request result" );
$outbuf = '';

##############################################################################
# Make sure that the default class key is the class name.
$interp->exec($comp, "Params::Callback::TestKey|my_key_cb" => 1);
$outbuf = '';

1;
__END__
