#!perl -w

use strict;
use FindBin qw($Bin);
use File::Spec::Functions qw(catdir catfile);
use Test::More;
use HTML::Mason::Interp;
my $base_key = 'OOTester';
my $err_msg = "He's dead, Jim";
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

    plan tests => 136;
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

sub complete : Callback(priority => 3) {
    my $self = shift;
    main::isa_ok($self, 'Params::Callback');
    main::isa_ok($self, __PACKAGE__);
    main::is($self->priority, 3, "Check priority is '3'" );
    my $params = $self->params;
    $params->{result} = 'Complete Success';
}

sub inherit : Callback {
    my $self = shift;
    my $params = $self->params;
    $params->{result} = UNIVERSAL::isa($self, 'Params::Callback')
      ? 'Yes' : 'No';
}

sub highest : Callback(priority => 0) {
    my $self = shift;
    main::is( $self->priority, 0, "Check priority is '0'" );
}

sub upperit : PreCallback {
    my $self = shift;
    my $params = $self->params;
    $params->{result} = uc $params->{result} if $params->{do_upper};
}

sub pre_post : Callback {
    my $self = shift;
    my $params = $self->params;
    $params->{chk_post} = 1;
}

sub lowerit : PostCallback {
    my $self = shift;
    my $params = $self->params;
    $params->{result} = lc $params->{result} if $params->{do_lower};
}

sub class : Callback {
    my $self = shift;
    main::isa_ok( $self, __PACKAGE__);
    main::isa_ok( $self, $self->value);
}

sub chk_priority : Callback {
    my $self = shift;
    my $priority = $self->priority;
    my $val = $self->value;
    $val = 5 if $val eq 'def';
    main::is($priority, $val, "Check for priority '$val'" );
    my $params = $self->params;
    $params->{result} .= " " . $priority;
}

sub test_abort : Callback {
    my $self = shift;
    $self->abort(1);
}

sub test_aborted : Callback {
    my $self = shift;
    my $params = $self->params;
    my $val = $self->value;
    eval { $self->abort(1) } if $val;
    $params->{result} = $self->aborted($@) ? 'yes' : 'no';
}

sub exception : Callback {
    my $self = shift;
    if ($self->value) {
        # Throw an exception object.
        throw_cb_exec $err_msg;
    } else {
        # Just die.
        die $err_msg;
    }
}

sub same_object : Callback {
    my $self = shift;
    my $params = $self->params;
    if ($self->value) {
        main::is($self, $params->{obj}, "Check for same object" );
    } else {
        $params->{obj} = $self;
    }
}

sub isa_interp : Callback {
    my $self      = shift;
    main::isa_ok $self->requester, 'MasonX::Interp::WithCallbacks',
        'the requester object';
}

sub change_comp : Callback {
    my $self = shift;
    $self->requester->comp_path($self->value);
}

1;

##############################################################################
# Now set up an emtpy callback subclass.
##############################################################################
package Params::Callback::TestObjects::Empty;
use strict;
use base 'Params::Callback::TestObjects';
__PACKAGE__->register_subclass( class_key => $base_key . 'Empty');
1;

##############################################################################
# Now set up an a subclass that overrides a parent method.
##############################################################################
package Params::Callback::TestObjects::Sub;
use strict;
use base 'Params::Callback::TestObjects';
__PACKAGE__->register_subclass( class_key => $base_key . 'Sub');

# Try a method with the same name as one in the parent, and which
# calls the super method.
sub inherit : Callback {
    my $self = shift;
    $self->SUPER::inherit;
    my $params = $self->params;
    $params->{result} .= ' and ';
    $params->{result} .= UNIVERSAL::isa($self, 'Params::Callback::TestObjects')
      ? 'Yes' : 'No';
}

# Try a totally new method.
sub subsimple : Callback {
    my $self = shift;
    my $params = $self->params;
    $params->{result} = 'Subsimple Success';
}

# Try a totally new method.
sub simple : Callback {
    my $self = shift;
    my $params = $self->params;
    $params->{result} = 'Oversimple Success';
}

1;

##############################################################################
# Meanwhile, back at the ranch...
##############################################################################
package main;

# Keep track of who's who.
my %classes = ( $base_key           => 'Params::Callback::TestObjects',
                $base_key . 'Sub'   => 'Params::Callback::TestObjects::Sub',
                $base_key . 'Empty' => 'Params::Callback::TestObjects::Empty');

my $outbuf;
my %mason_params = (comp_root  => catdir($Bin, qw(htdocs)),
                    out_method => \$outbuf);

use_ok('MasonX::Interp::WithCallbacks');

my $all = 'ALL';
for my $key ($base_key, $base_key . "Empty", $all) {
    # Create the Interp object.
    my $interp;
    if ($key eq 'ALL') {
        # Load all of the callback classes.
        ok( $interp = MasonX::Interp::WithCallbacks->new( %mason_params,
                                                          cb_classes => $key ),
            "Construct $key Interp object" );
        $key = $base_key;
    } else {
        # Load the base class and the subclass.
        ok( $interp = MasonX::Interp::WithCallbacks->new
            ( %mason_params,
              cb_classes => [$key, $base_key . 'Sub']),
            "Construct $key Interp object" );
    }

    ##########################################################################
    # Now make sure that the simple callback executes.
    $interp->exec($comp, "$key|simple_cb" => 1);
    is( $outbuf, 'Simple Success', "Check simple result" );
    $outbuf = '';

    ##########################################################################
    # And the "complete" callback.
    $interp->exec($comp, "$key|complete_cb" => 1);
    is( $outbuf, 'Complete Success', "Check complete result" );
    $outbuf = '';

    ##########################################################################
    # Check the class name.
    $interp->exec($comp, "$key|inherit_cb" => 1);
    is( $outbuf, 'Yes', "Check inherit result" );
    $outbuf = '';

    ##########################################################################
    # Check class inheritance and SUPER method calls.
    $interp->exec($comp, $base_key . "Sub|inherit_cb" => 1);
    is( $outbuf, 'Yes and Yes', "Check SUPER inherit result" );
    $outbuf = '';

    ##########################################################################
    # Try pre-execution callbacks.
    $interp->exec($comp,
                      do_upper => 1,
                      result   => 'upPer_mE');
    is( $outbuf, 'UPPER_ME', "Check pre result" );
    $outbuf = '';

    ##########################################################################
    # Try post-execution callbacks.
    $interp->exec($comp,
                      "$key|simple_cb" => 1,
                      do_lower => 1);
    is( $outbuf, 'simple success', "Check post result" );
    $outbuf = '';

    ##########################################################################
    # Try a method defined only in a subclass.
    $interp->exec($comp, $base_key . "Sub|subsimple_cb" => 1);
    is( $outbuf, 'Subsimple Success', "Check subsimple result" );
    $outbuf = '';

    ##########################################################################
    # Try a method that overrides its parent but doesn't call its parent.
    $interp->exec($comp, $base_key . "Sub|simple_cb" => 1);
    is( $outbuf, 'Oversimple Success', "Check oversimple result" );
    $outbuf = '';

    ##########################################################################
    # Try a method that overrides its parent but doesn't call its parent.
    $interp->exec($comp, $base_key . "Sub|simple_cb" => 1);
    is( $outbuf, 'Oversimple Success', "Check oversimple result" );
    $outbuf = '';

    ##########################################################################
    # Check that the proper class ojbect is constructed.
    $interp->exec($comp, "$key|class_cb" => $classes{$key});
    $outbuf = '';

    ##########################################################################
    # Check priority execution order for multiple callbacks.
    $interp->exec($comp,
                  "$key|chk_priority_cb0"  => 0,
                  "$key|chk_priority_cb2"  => 2,
                  "$key|chk_priority_cb9"  => 9,
                  "$key|chk_priority_cb7"  => 7,
                  "$key|chk_priority_cb1"  => 1,
                  "$key|chk_priority_cb4"  => 4,
                  "$key|chk_priority_cb"   => 'def');
    is($outbuf, " 0 1 2 4 5 7 9", "Check priority order result" );
    $outbuf = '';

    ##########################################################################
    # Emulate the sumission of an <input type="image" /> button.
    $interp->exec($comp,
                  "$key|simple_cb.x" => 18,
                  "$key|simple_cb.y" => 22 );
    is( $outbuf, 'Simple Success', "Check single simple result" );
    $outbuf = '';

    ##########################################################################
    # Make sure that if we abort, no more callbacks execute.
    eval { $interp->exec($comp,
                         "$key|test_abort_cb0" => 1,
                         "$key|simple_cb" => 1,
                         result => 'still here') };
    is( $outbuf, '', "Check abort result" );
    $outbuf = '';

    ##########################################################################
    # Test aborted for a false value.
    $interp->exec($comp, "$key|test_aborted_cb" => 0);
    is( $outbuf, 'no', "Check false aborted result" );
    $outbuf = '';

    ##########################################################################
    # Test aborted for a true value.
    $interp->exec($comp, "$key|test_aborted_cb" => 1);
    is( $outbuf, 'yes', "Check true aborted result" );
    $outbuf = '';

    ##########################################################################
    # Try throwing an execption.
    eval { $interp->exec($comp, "$key|exception_cb" => 1) };
    ok( my $err = $@, "Catch $key exception" );
    isa_ok($err, 'Params::Callback::Exception');
    isa_ok($err, 'Params::Callback::Exception::Execution');
    is( $err->error, $err_msg, "Check error message" );
    $outbuf = '';

    ##########################################################################
    # Try die'ing.
    eval { $interp->exec($comp, "$key|exception_cb" => 0) };
    ok( $err = $@, "Catch $key die" );
    isa_ok($err, 'Params::Callback::Exception');
    isa_ok($err, 'Params::Callback::Exception::Execution');
    like( $err->error, qr/^Error thrown by callback: $err_msg/,
        "Check die error message" );
    $outbuf = '';

    ##########################################################################
    # Make sure that the same object is called for multiple callbacks in the
    # same class.
    $interp->exec($comp,
                  "$key|same_object_cb1" => 0,
                  "$key|same_object_cb" => 1);
    $outbuf = '';

    ##########################################################################
    # Check priority 0 sticks.
    $interp->exec($comp, "$key|highest_cb" => undef);
    $outbuf = '';

    ##########################################################################
    # Requester should be WithCallbacks object.
    $interp->exec($comp, "$key|isa_interp_cb" => 1);
    $outbuf = '';

    ##########################################################################
    # Changing the comp path should change the executed component.
    $interp->exec($comp, "$key|change_comp_cb" => '/alt.mc');
    is $outbuf, 'This is the alt component.',
        'The alt component should have executed';
    $outbuf = '';
}

__END__
