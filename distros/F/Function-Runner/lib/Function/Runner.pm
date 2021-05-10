package Function::Runner;

use strict; use warnings; use utf8; use 5.10.0;
use Data::Dumper;
our $VERSION = '0.003';


my $PEEK_LEVEL = 5;     # Disallow peeks below this level
sub peek {      # ( $level, $res ) --> $res
    my ($level, $res) = @_;

    # Comment out logging in PROD
    _log_save($res);

    # Guard: Do nothing if $level is lower than PEEK_LEVEL
    return $res if $level < $PEEK_LEVEL;

    # Print content of $res
    my $file = (caller(0))[1];
    my $line = (caller(0))[2];

    say "$file line $line: ". Dumper $res;
    return $res;
}

my $LOG   = [];         # Container for logs from peek()
sub _log_save {   # ($res)
    my $res = shift;
    # Add to log regardless of PEEK_LEVEL
    my $pkg  = (caller(1))[0];
    my $file = (caller(1))[1];
    my $line = (caller(1))[2];
    push @$LOG, ["file:$file - pkg:$pkg - line:$line: ",$res];
    #push @$LOG, "file:$file - pkg:$pkg - line:$line: ".$res;
    return $res;
}
sub _log_fetch { return $LOG }
sub _log_clear { $LOG = [] }


## CONSTRUCTORS
sub new {
    # Clear the LOG
    $LOG = [];

    my $fn_map  = {};                   # initial function map
    my $defn    = $_[1];                # user-provided function definition
    my $pkg = (caller)[0];              # calling package
    _die("missing defn or pkg") unless defined $defn && defined $pkg;

    # See: https://perldoc.perl.org/perlmod#Symbol-Tables
    my $tab = eval '\%'.$pkg.'::';      # symbol table of calling package
    peek 3, ['Symbol Table: ','\%'.$pkg.'::',"has ref: \"".ref($tab).'"'];

    _mk_fn_map($fn_map,$defn,$tab,$pkg);# build fn_map from $defn and $tab
    peek 3, ['Completed fn_map: ',$fn_map];

    bless { defn=>$defn,
            fn=>$fn_map,
            log=>{ step => [],      # Store steps and results
                   func => [] }     # Store funcs and results
          },
          $_[0];
}


## METHODS
my $LEVEL = 0;          # Tracks recursion levels
sub _mk_fn_map {
    my ($fn_map, $defn, $tab, $pkg) = @_;

    # Walk the defn, get all coderefs
    foreach my $step (keys %$defn) {
        my $res = $defn->{$step};
        my $ref = ref $res;
        peek 3, ["Processing StepDef: $step",$res, " has res: \"$ref\""];

        if ($ref eq '') {                       # Coderef. e.g. '&bye' or '/greet'
            # Guard: Skip if Step not Func
            #   Step Example: '/greet'
            #   Func Example: '&bye'
            if ($res =~ /^\/(.*)/) {
                peek 3, "Ignored StepDef when building fn_map: $res";
                next;
            }

            my ($sym) = ($res =~ /^&(.*)/);
            peek 3, "Processing Func: $res";
            _die("Bad res: $res") unless defined $sym;

            # Guard: Skip if already in $fn_map
            if (exists $fn_map->{$sym}) {
                peek 3, "Func already mapped: $res";
                next;
            }

            # Guard: The given symbol e.g. 'hello' must be defined as a
            #        function in the calling package
            my $is_code = eval 'defined &'.$pkg.'::'.$sym ? 1 : 0;
            peek 3, "Func: $res is code: \"$is_code\"";
            _die("\n\n"."\"$sym\" not a coderef in \"$pkg\"")
                unless $is_code;

            # Add mapping of symbol to coderef
            $fn_map->{$sym} = $tab->{$sym};
            peek 3, "Add to fn_map: $res";

        } elsif ($ref eq 'HASH') {              # Defn e.g. { ':ok' => ... }
            $LEVEL++;
            peek 3, ["Descending into: $step to ---- Level ".$LEVEL.' ----'];
            _mk_fn_map($fn_map, $res, $tab, $pkg);
            $LEVEL--;
            peek 3, ["Ascending from: $step to ---- Level ".$LEVEL.' ----'];

        } else {
            _die("Unexpected ref type: $ref");

        }
    }
}
sub call {
    my ($o,$func,@args) = @_;

    #Guard: Func must exist
    _die("Func does not exist: $func") unless exists $o->{fn}{$func};

    #peek 3, "call $func() with args: ". join ', ',@args;

    my ($fn_res,@new_args) = $o->{fn}{$func}->(@args);

    # Log the func that was called
    push @{$o->{log}{func}}, {"&$func" => ":$fn_res"};

    return ($fn_res,@new_args);
}
sub run {   # ($step) -> $result
    my ($o,$step,@args) = @_;
    my @run_result;

    #Guard: Step must exist
    _die("Step does not exist: $step") unless exists $o->{defn}{$step};

    # Clear the logs if at LEVEL 0
    if ($LEVEL == 0) {
        $o->{log} = { step=>[], func => [] };
    }

    peek 3, "------- $LEVEL -------";


    my $def = $o->{defn}{$step};
    my $ref = ref $def;
    if ($ref eq '') {           # e.g. '&bye'
        # Get the function to run
        my ($fn) = ($def =~ /^&(.*)/);
        _die("Defn is not a function: $def") unless defined ($fn);
        peek 3, "Step $step calls function $fn()";

        # Call the function, return the result
        peek 3, "Call $fn() and return the result";
        @run_result = $o->call($fn,@args);

    } elsif ($ref eq 'HASH') {  # e.g. { 'run' => '&checkSwitch', ... }
        $LEVEL++;
        peek 1, ["Descending non-terminal step: ".$LEVEL, $def];

        # Guard: The 'run' attribute must exist in the definition
        _die("Defn of $step missing 'run' attribute") unless defined $def->{run};

        # Get the function to run
        my ($fn) = ($def->{run} =~ /^&(.*)/);
        _die("Defn of $step is not a function: $def") unless defined ($fn);
        peek 3, "Step $step calls function $fn()";

        # Call the function, save the result
        peek 3, "Call $fn() and save the result";
        my ($fn_res,@new_args) = $o->call($fn,@args);
        peek 3, "  Result of calling $fn() is $fn_res";

        # Log step that was ran
        push @{$o->{log}{step}}, [$step, "&$fn",":$fn_res"];

        # Get the next step pointed to by the result
        my $next_step = $def->{':'.$fn_res};

        # Guard: The next step must exist for non-terminal (HASHREF) steps
        _die("Next step of $step:$fn_res undefined") unless defined $next_step;

        peek 1, ["The next step and args:", $next_step, [@new_args]];


        # If next step is a Func, call it
        # If next step is a Step, run it
        # Else error
        if ($next_step =~ /^&.+/) {
            my ($next_func) = $next_step =~ /^&(.+)/;
            peek 3, "  Next step is a Func, calling it..";
            @run_result = $o->call($next_func,@new_args);
        } elsif ($next_step =~ /^\/.+/) {
            peek 3, "  Next step is a Step, running it..";
            @run_result = $o->run($next_step,@new_args);
        }

        $LEVEL--;
        peek 1, ["Ended non-terminal step: ".$LEVEL, $def];

        return @run_result;
    } else {
        _die("Unexpected Step type: $ref");
    }
}
sub steps { return shift->{log}{step} }
sub funcs { return shift->{log}{func} }


# PRIVATE HELPERS
sub _die {
    # Private method to display all errors and then die
    my ($o,$msg) = @_;

    my ($pkg,$file,$line) = caller;

    # Case called as a function, message is the first arg
    if (ref $o eq '') { $msg = $o }

    die Dumper($LOG)
        ."\n  $msg\n    (pkg: $pkg - file: $file - line: $line)\n     ";
}


1;

=encoding utf-8
=cut
=head1 NAME

Function::Runner - Define functions at a higher level and run them

=cut
=head1 SYNOPSIS

  use Function::Runner;

  # Hello World
  sub greet {
      print "Hello ". ($_[0] || 'World') ."\n";
      return ('ok',$_[0]);
  }

  my $defn = {                              # Definition is just a hashref
    '/hello' => '&greet'                    #   The /hello step,
  };                                        #     calls the &greet function

  my $fn = Function::Runner->new($defn);    # Create a greeter
  $fn->run('/hello','Flash');               # Hello Flash


  my $switch = {                            # Define a switch
    '/checkSwitch' => {
        'run'  => '&checkSwitch',           # Check the switch
        ':on'  => '&bye',                   #   If it's on, leave
        ':off' => '/turnOn',                #   If it's off, turn it on
    },
    '/turnOn'  => {                         # Turn on the switch
        'run'  => '&greet',                 #   Greet the caller
        ':ok' => '/turnOff',                #   Then turn off the switch
    },
    '/turnOff' => '&bye',                   # Turn off the switch and leave
  };
  sub bye {
    print "Bye ". ($_[0] || 'World') ."\n";
    return ('ok',$_[0]);
  }
  sub checkSwitch { return @_ }

  $fn = Function::Runner->new($switch);     # Create a switch
  $fn->run('/checkSwitch', 'on', 'Flash');  # Bye Flash

  $fn->run('/checkSwitch', 'off', 'Hulk');  # Hello Hulk
                                            # Bye Hulk

  say join ' ', @$_ for @{$fn->steps};      # List steps, function and result
                                            #   /checkSwitch &checkSwitch :off
                                            #   /turnOn &greet :ok

=cut
=head1 DESCRIPTION

Function::Runner provides a way to define the steps of a function and
the logical flow between the steps using just hashrefs. The user then
implements the steps that need to be called. The function runner will
then run the function.

This module is handy for functions that are naturally composed of many
hierarchical steps and flows differently depending on the results of
those steps. The function definition helps to clarify the steps and flow
at a higher level.

A function definition (B<funcdef>) is composed of three (3) constructs:
I<steps>, I<functions> and I<results>. Each construct is a string with a
different character prefix to indicate the kind of construct:

    /a_step         # Steps are prefixed with /, like directories

    &a_function     # Functions prefixed with &, like Perl

    :some_result    # Results prefixed with :

The keys of the funcdef hashref is always a I<step>. The value of the
funcdef hashref is the step definition (B<stepdef>) defines how that step
is to be executed.

A I<stepdef> can be just a I<function> if no further steps follow. For
example:

    { '/hello' => '&greet' }

A I<stepdef> can also be a hashref that defines the I<function> to run
and the I<next step> to take depending on the I<results> of that
function run.  For example:

    '/checkSwitch' => {
        'run'  => '&checkSwitch',           # Check the switch
        ':on'  => '&bye',                   #   If it's on, leave
        ':off' => '/turnOn',                #   If it's off, turn it on
    },

The next step can either be a function:

    ':on'  => '&bye'            # On "on" result, call the &bye function

or it can be another step:

    ':off' => '/turnOn'         # On "off" result, run the /turnOn step

=cut
=head1 METHODS
=cut
=head2 run($step,@args)

The run() method runs the given $step, checks the results, looks up the
function definition to determine the next step to run an calls that
until there is nothing left to be done at which point it will return the
result of the last function that was called.

Along the way it tracks how deep it is within the function definition.
Each step that was ran and the corresponding result is stored in an
array.

=cut
=head2 steps()

The steps() method returns the steps that ran for that function.

=cut
=head1 NAMING CONVENTIONS

I<Steps> and I<Functions> with the form B<Verb + Object> is rather
pleasing to read. For example:

    &findStalledWorkers

    /find_stalled_workers

I<Results> with the form B<Object + State> or B<Object + Adjective> is
also rather pleasing to read. For example:

    :queueEmpty

    :not_found

Taken together, the step and it's results end up reading like this:

    /find_stalled_workers :not_found

=cut
=head1 NOTES

Defining a function in terms of I<steps>, I<functions> and I<results>
has several nice properties.

The valid return values from each I<function> is clearly spelled out.

Having a I<funcdef> makes it easier rearrange the flow of steps within
that function or add an additional step in the function's processing.

It is possible to directly call the steps in a function definition.

It is possible to analyze the I<funcdef> hashref to create a reverse
dependency graph so that when a I<function> is about to be changed, find
all it's dependents.

All in all, it is a rather nice way to design these kinds of
hierarchical, multi-step functions where the flow depends on the results
of prior steps.

=cut
=head1 AUTHOR

Hoe Kit CHEW E<lt>hoekit@gmail.comE<gt>

=cut
=head1 COPYRIGHT

Copyright 2021- Hoe Kit CHEW

=cut
=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

