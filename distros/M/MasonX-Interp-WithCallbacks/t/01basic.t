#!perl -w

use strict;
use FindBin qw($Bin);
use File::Spec::Functions qw(catdir catfile);
use Test::More tests => 49;
use HTML::Mason::Interp;

BEGIN { use_ok('MasonX::Interp::WithCallbacks') }

my $key = 'myCallbackTester';
my $cbs = [];

##############################################################################
# Set up callback functions.
##############################################################################
# Simple callback.
sub simple {
    my $cb = shift;
    isa_ok( $cb, 'Params::Callback' );
    isa_ok( $cb->cb_request, 'Params::CallbackRequest' );
    my $params = $cb->params;
    $params->{result} = 'Success';
}

push @$cbs, { pkg_key => $key,
              cb_key  => 'simple',
              cb      => \&simple
            };

##############################################################################
# Priorty order checking.
sub priority {
    my $cb = shift;
    my $params = $cb->params;
    my $val = $cb->value;
    $val = '5' if $val eq 'def';
    $params->{result} .= " $val";
}

push @$cbs, { pkg_key => $key,
              cb_key  => 'priority',
              cb      => \&priority
            };

##############################################################################
# Hash value callback.
sub hash_check {
    my $cb = shift;
    isa_ok( $cb, 'Params::Callback');
    my $params = $cb->params;
    my $val = $cb->value;
    # For some reason, if I don't eval this, then the code in the rest of
    # the function doesn't run!
    eval { isa_ok( $val, 'HASH' ) };
    $params->{result} = "$val"
}

push @$cbs, { pkg_key => $key,
              cb_key  => 'hash_check',
              cb      => \&hash_check
            };

##############################################################################
# Code value callback.
sub code_check {
    my $cb = shift;
    isa_ok( $cb, 'Params::Callback');
    my $params = $cb->params;
    my $val = $cb->value;
    # For some reason, if I don't eval this, then the code in the rest of
    # the function doesn't run!
    eval { isa_ok( $val, 'CODE' ) };
    $params->{result} = $val->();
}

push @$cbs, { pkg_key => $key,
              cb_key  => 'code_check',
              cb      => \&code_check
            };

##############################################################################
# Count the number of times the callback executes.
sub count {
    my $cb = shift;
    isa_ok( $cb, 'Params::Callback');
    my $params = $cb->params;
    $params->{result}++;
}

push @$cbs, { pkg_key => $key,
              cb_key  => 'count',
              cb      => \&count
            };

##############################################################################
# Abort callbacks.
sub test_abort {
    my $cb = shift;
    isa_ok( $cb, 'Params::Callback');
    my $params = $cb->params;
    $cb->abort(1);
}

push @$cbs, { pkg_key => $key,
              cb_key  => 'test_abort',
              cb      => \&test_abort
            };

##############################################################################
# Check the aborted value.
sub test_aborted {
    my $cb = shift;
    isa_ok( $cb, 'Params::Callback');
    my $params = $cb->params;
    my $val = $cb->value;
    eval { $cb->abort(1) } if $val;
    $params->{result} = $cb->aborted($@) ? 'yes' : 'no';
}

push @$cbs, { pkg_key => $key,
              cb_key  => 'test_aborted',
              cb      => \&test_aborted
            };

##############################################################################
# We'll use this callback just to grab the value of the "submit" parameter.
sub submit {
    my $cb = shift;
    isa_ok( $cb, 'Params::Callback');
    my $params = $cb->params;
    $params->{result} = $params->{submit};
}

push @$cbs, { pkg_key => $key,
              cb_key  => 'submit',
              cb      => \&submit
            };

##############################################################################
# We'll use this callback to throw exceptions.
sub exception {
    my $cb = shift;
    my $params = $cb->params;
    if ($cb->value) {
        # Throw an exception object.
        HTML::Mason::Exception->throw( error => "He's dead, Jim" );
    } else {
        # Just die.
        die "He's dead, Jim";
    }
}

push @$cbs, { pkg_key => $key,
              cb_key  => 'exception',
              cb      => \&exception
            };

##############################################################################
# We'll use these callbacks to test notes().
sub add_note {
    my $cb = shift;
    $cb->notes($cb->value, $cb->params->{note});
}

sub get_note {
    my $cb = shift;
    $cb->params->{result} = $cb->notes($cb->value);
}

sub list_notes {
    my $cb = shift;
    my $params = $cb->params;
    my $notes = $cb->notes;
    for my $k (sort keys %$notes) {
        $params->{result} .= "$k => $notes->{$k}\n";
    }
}

sub clear {
    my $cb = shift;
    $cb->cb_request->clear_notes;
}

push @$cbs, { pkg_key => $key,
              cb_key  => 'add_note',
              cb      => \&add_note
            },
            { pkg_key => $key,
              cb_key  => 'get_note',
              cb      => \&get_note
            },
            { pkg_key => $key,
              cb_key  => 'list_notes',
              cb      => \&list_notes
            },
            { pkg_key => $key,
              cb_key  => 'clear',
              cb      => \&clear
            };

##############################################################################
# We'll use this callback to change the result to uppercase.
sub upper {
    my $cb = shift;
    my $params = $cb->params;
    if ($params->{do_upper}) {
        isa_ok( $cb, 'Params::Callback');
        $params->{result} = uc $params->{result};
    }
}

##############################################################################
# We'll use this callback to flip the characters of the "submit" parameter.
# The value of the "submit" parameter won't be "racecar!"
sub flip {
    my $cb = shift;
    my $params = $cb->params;
    if ($params->{do_flip}) {
        isa_ok( $cb, 'Params::Callback');
        $params->{submit} = reverse $params->{submit};
    }
}

##############################################################################
# Set up Mason objects.
##############################################################################
my $outbuf;
ok( my $interp = MasonX::Interp::WithCallbacks->new
    ( comp_root  => catdir($Bin, qw(htdocs)),
      callbacks  => $cbs,
      post_callbacks => [\&upper],
      pre_callbacks  => [\&flip],
      out_method => \$outbuf ),
    "Construct interp object" );
isa_ok($interp, 'MasonX::Interp::WithCallbacks');
isa_ok($interp, 'HTML::Mason::Interp');
isa_ok($interp->cb_request, 'Params::CallbackRequest');

my $comp = '/dhandler';

##############################################################################
# Try a simple callback.
$interp->exec($comp, "$key|simple_cb" => 1);
is( $outbuf, 'Success', "Check simple result" );
$outbuf = '';

##############################################################################
# Check that prioritized callbacks execute in the proper order.
$interp->exec($comp,
              "$key|priority_cb0" => 0,
              "$key|priority_cb2" => 2,
              "$key|priority_cb9" => 9,
              "$key|priority_cb7" => 7,
              "$key|priority_cb1" => 1,
              "$key|priority_cb4" => 4,
              "$key|priority_cb"  => 'def' );
is($outbuf, " 0 1 2 4 5 7 9", "Check priority order" );
$outbuf = '';

##############################################################################
# Emmulate the sumission of an <input type="image" /> button.
$interp->exec($comp,
              "$key|simple_cb.x" => 18,
              "$key|simple_cb.y" => 24 );
is( $outbuf, 'Success', "Check simple image result" );
$outbuf = '';

##############################################################################
# Make sure that an image submit doesn't cause the callback to be called
# twice.
$interp->exec($comp,
              "$key|count_cb.x" => 18,
              "$key|count_cb.y" => 24 );
is( $outbuf, '1', "Check image count result" );
$outbuf = '';

##############################################################################
# Just like the above, but make sure that different priorities execute
# at different times.
$interp->exec($comp,
              "$key|count_cb1.x" => 18,
              "$key|count_cb1.y" => 24,
              "$key|count_cb2.x" => 18,
              "$key|count_cb2.y" => 24 );
is( $outbuf, '2', "Check second image count result" );
$outbuf = '';

##############################################################################
# Test the abort functionality. The abort callback's higher priority should
# cause it to prevent simple from being called.
eval { $interp->exec($comp,
                     "$key|simple_cb" => 1,
                     "$key|test_abort_cb0" => 1 ) };
ok( my $err = $@, "Catch exception" );
isa_ok( $err, 'HTML::Mason::Exception::Abort' );
is( $err->aborted_value, 1, "Check aborted value" );
is( $outbuf, '', "Check abort result" );
$outbuf = '';

##############################################################################
# Test the aborted method.
$interp->exec($comp, "$key|test_aborted_cb" => 1 );
is( $outbuf, 'yes', "Check aborted result" );
$outbuf = '';

##############################################################################
# Test notes.
my $note_key = 'myNote';
my $note = 'Test note';
$interp->exec($comp,
              "$key|add_note_cb1" => $note_key, # Executes first.
              note                => $note,
              "$key|get_note_cb"  => $note_key);
is( $outbuf, $note, "Check note result" );
$outbuf = '';

# Make sure the note isn't available on the next request.
$interp->exec($comp, "$key|get_note_cb"  => $note_key );
is( $outbuf, '', "Check no note result" );

# Add multiple notes.
$interp->exec($comp,
              "$key|add_note_cb1"   => $note_key, # Executes first.
              "$key|add_note_cb2"   => $note_key . 1, # Executes second.
              note                  => $note,
              "$key|list_notes_cb"  => 1);
is( $outbuf, "$note_key => $note\n${note_key}1 => $note\n",
    "Check multiple note result" );
$outbuf = '';

# Make sure that notes percolate back to Mason.
$interp->exec($comp,
              "$key|add_note_cb"   => $note_key,
              note                 => $note,
              result               => sub { shift->notes($note_key) } );
is( $outbuf, $note, "Check mason note result" );
$outbuf = '';

# Make sure that we can still get at the notes via the callback request object
# in Mason components.
$interp->exec($comp,
              "$key|add_note_cb"   => $note_key,
              note                 => $note,
              result               => sub {
                  shift->interp->cb_request->notes($note_key)
              } );
is( $outbuf, $note, "Check cb_request note result" );
$outbuf = '';

# Finally, make sure that if we clear it in callbacks, that no one gets it.
$interp->exec($comp,
              "$key|add_note_cb1"  => $note_key, # Executes first.
              note                 => $note,
              "$key|clear_cb"      => 1,
              result               => sub { shift->notes($note_key) } );
is( $outbuf, '', "Check Mason cleared note result" );

$interp->exec($comp,
              "$key|add_note_cb1"  => $note_key, # Executes first.
              note                 => $note,
              "$key|clear_cb"      => 1,
              result               => sub {
                  shift->interp->cb_request->notes($note_key)
              } );
is( $outbuf, '', "Check cb_request cleared note result" );

##############################################################################
# Test the pre-execution callbacks.
my $string = 'yowza';
$interp->exec($comp,
              "$key|submit_cb" => 1,
              submit           => $string,
              do_flip         => 1 );
is( $outbuf, reverse($string), "Check pre result" );
$outbuf = '';

##############################################################################
# Test the post-execution callbacks.
$interp->exec($comp,
              "$key|simple_cb" => 1,
              do_upper => 1 );
is( $outbuf, 'SUCCESS', "Check post result" );
$outbuf = '';

ok( $interp = MasonX::Interp::WithCallbacks->new
    ( comp_root    => catdir($Bin, qw(htdocs)),
      callbacks    => $cbs,
      ignore_nulls => 1,
      out_method   => \$outbuf ),
    "Construct interp object that ignores nulls" );

$interp->exec($comp, "$key|simple_cb" => 1);
is( $outbuf, 'Success', "Check simple result" );
$outbuf = '';

# And try it with a null value.
$interp->exec($comp, "$key|simple_cb" => '');
is( $outbuf, '', "Check null result" );
$outbuf = '';

# And with undef.
$interp->exec($comp, "$key|simple_cb" => undef);
is( $outbuf, '', "Check undef result" );
$outbuf = '';

# But 0 should succeed.
$interp->exec($comp, "$key|simple_cb" => 0);
is( $outbuf, 'Success', "Check 0 result" );
$outbuf = '';

##############################################################################
# Test the exception handler.
ok( $interp = MasonX::Interp::WithCallbacks->new
    ( comp_root    => catdir($Bin, qw(htdocs)),
      callbacks    => $cbs,
      cb_exception_handler => sub {
          like( $_[0], qr/^He's dead, Jim at/,
                "Check our die message" );
      },
      out_method   => \$outbuf ),
    "Construct interp object that handles exceptions" );
$interp->exec($comp, "$key|exception_cb" => 0);
$outbuf = '';

__END__
