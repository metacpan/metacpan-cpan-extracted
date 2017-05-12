package Getopt::Chain::Context;

use strict;
use warnings;

use Moose;
use MooseX::AttributeHelpers;
use Getopt::Chain::Carp;

use Getopt::Chain;

use Getopt::Long qw/GetOptionsFromArray/;
use Hash::Param;

use constant DEBUG => Getopt::Chain->DEBUG;
our $DEBUG = DEBUG;

=head1 NAME

Getopt::Chain::Context - Per-command context

=head1 WARNING

This documentation is out of date and needs an update. For the real documentation:

    perldoc -m Getopt::Chain::Context 

=head1 DESCRIPTION

A context encapsulates the current state of execution, including:

    The name of the current command (or undef if at the "root")
    Every option parsed so far
    Options local to the current command
    The arguments as they were BEFORE parsing options for this command
    The arguments remaining AFTER parsing options for this command

=head1 METHODS

=head2 $context->command

Returns the name of the current command (or undef in a special case)

    ./script --verbose edit --file xyzzy.c 
    # The command name is "edit" in the edit subroutine

    ./script --help
    # The command name is undef in the root subroutine

=head2 $context->option( <name> )

Returns the value of the option for <name> 

<name> should be primary name of the option (see L<Getopt::Long> for more information
on primary/alias naming)

If called in list context and the value of option is an ARRAY reference,
then this method returns a list:

    ./script --exclude apple --exclude banana --exclude --cherry
    ...
    my @exclude = $context->option( exclude )

See L<Hash::Param> for more usage information

=head2 $context->options( <name>, <name>, ... )

Similar to ->option( <name> ) except for many-at-once

Returns a list in list context, and an ARRAY reference otherwise (you could
end up with a LoL situation in that case)

See L<Hash::Param> for more usage information

=head2 $context->options

Returns the keys of the option hash in list context

Returns the option HASH reference in scalar context

    ./script --verbose
    ...
    if ( $context->options->{verbose} ) { ... }

See L<Hash::Param> for more usage information

=head2 $context->local_option

=head2 $context->local_options

Behave similarly to ->option and ->options, except only cover options local to the current command

    ./script --verbose edit --file xyzzy.c
    $context->local_option( file ) # Returns 'xyzzy.c'
    $context->local_option( verbose ) # Doesn't return anything
    $context->option( verbose ) # Returns 1

=head2 $context->stash

An initially empty  HASH reference that can be used for sharing inter-command information

Similar to the stash in L<Catalyst>

=head2 $context->arguments

Returns a copy of the arguments (@ARGV) for the current command BEFORE option parsing

Returns an ARRAY reference (still a copy) when called in scalar context

    ./script --verbose edit --file xyzzy.c

    # At the very beginning: 
    $context->arguments # Returns ( --verbose edit --file xyzzy.c )

    # In the "edit" subroutine:
    $context->arguments # Returns ( edit --file xyzzy.c )

=head2 $context->remaining_arguments

Returns a copy of the remaining arguments (@ARGV) for the current command AFTER option parsing

Returns an ARRAY reference (still a copy) when called in scalar context

    ./script --verbose edit --file xyzzy.c

    # At the very beginning: 
    $context->remaining_arguments # Returns ( edit --file xyzzy.c )

    # In the "edit" subroutine:
    $context->remaining_arguments # Returns ( )

=cut

# Should probably move these into Getopt::Chain
# ...or even... Getopt::Longer :)
sub is_option_like($) {
    return $_[0] =~ m/^-/;
}

sub consume_arguments($$) { # Will modify arguments, reflecting consumption
    my $argument_schema = shift;
    my $arguments = shift;

    my %options;
    eval {
        if ($argument_schema && @$argument_schema) {
            Getopt::Long::Configure(qw/pass_through/);
            GetOptionsFromArray($arguments, \%options, @$argument_schema);
        }
    };
    croak "There was an error option-processing arguments: $@" if $@;

    return ( \%options );
}

has dispatcher => qw/is ro required 1/;

has _options => qw/is ro isa Hash::Param lazy_build 1/, handles => {qw/option param options params/};
sub _build__options {
    my $self = shift;
    return Hash::Param->new(params => {});
}

has _stash => qw/is ro isa HashRef/, default => sub { {} };
sub stash {
    my $self = shift;
    return $self->_stash unless @_;
    my $stash = $self->_stash;
    while ( @_ ) { my ($k, $v) = (shift @_, shift @_); $stash->{$k} = $v }
    return $stash;
}

# The original arguments from the commandline (or wherever)... read only!
has starting_arguments => qw/metaclass Collection::Array reader _arguments init_arg arguments required 1 lazy 1 isa ArrayRef/, default => sub { [] }, provides => {qw/
    elements    starting_arguments
/};

# The arguments remaining after each step does argument consuming... written by the step!
has parsing_arguments => qw/metaclass Collection::Array accessor _parsing_arguments isa ArrayRef/, provides => {qw/
    elements    parsing_arguments
    shift       shift_parsing_argument
    first       first_parsing_argument
/};

has steps => qw/metaclass Collection::Array reader _steps required 1 lazy 1 isa ArrayRef/, default => sub { [] }, provides => {qw/
    elements    steps   
    first       first_step
    last        last_step
    push        push_step
    pop         pop_step
/};

has _path => qw/metaclass Collection::Array is ro required 1 lazy 1 isa ArrayRef/, default => sub { [] }, provides => {qw/
    elements    path
    push        push_path
/};

sub initialize_run {
    my $self = shift;
    $self->_parsing_arguments( [ $self->starting_arguments ] );
}

sub run {
    my $self = shift;

    $self->initialize_run;
    1 while $self->next;
}

sub next {
    my $self = shift;

    unless (defined $self->_parsing_arguments) { # Haven't been run yet
        $self->initialize_run;
    }

    my $run_path = join ' ', $self->path;
    warn "Context::next ", $self->path_as_string, " ($run_path)\n"  if $DEBUG;

    {
        # $self->dispatcher->run( $run_path, $self ); # This will (indirectly) call ->run_step( ... ) below
        my $dispatch = $self->dispatcher->dispatch( $run_path );
        if ( my @matches = $dispatch->matches ) {
            for my $match ($dispatch->matches) {
                my $result = $match->positional_captures;
                last if $match->run( $self ); # ->run_step returned true
            }
        }
    }

    my $next;
    $self->push_path( $next ) if $next = $self->next_path_part;
    return $next;
}

sub next_path_part {
    my $self = shift;

    return unless defined (my $argument = $self->first_parsing_argument);
    croak "Have option-like element at head of parsing arguments: ", $argument, " @ ", $self->path_as_string, " [", join ' ', $self->parsing_arguments, "]" if is_option_like $argument;
    return $self->shift_parsing_argument; # Same as $argument, really
}

sub last {
    my $self = shift;
    return ! defined $self->first_parsing_argument;
}

sub path_as_string {
    my $self = shift;
    return join '/', '^START', $self->path, ($self->last ? '$' : ());
}

sub run_step { # Called from within the Path::Dispatcher rule
    my $self = shift;
    my $argument_schema = shift;
    my $run = shift;
    my $control = shift;

    $argument_schema = [] unless defined $argument_schema;
    
    my $step = $self->add_step( argument_schema => $argument_schema, run => $run, @_ ); 
    return 1 if $step->run( $control ); # We consumed and ran, so we don't need to rollback
    $self->pop_step; # Rollback, since we didn't actually run
    return 0;
}

sub add_step {
    my $self = shift;
    my %given = @_; # Should be: argument_schema, run

    my $parent = $self->last_step; # Could be undef
    my $step = Getopt::Chain::Context::Step->new( context => $self, parent => $parent, path => [ $self->path ], arguments => [ $self->parsing_arguments ], %given );
    $self->push_step( $step );
    return $step;
}

sub command {
    my $self = shift;
    return $self->last_step->last_path_part;
}

sub local_option {
    my $self = shift;
    return $self->last_step->option( @_ );
}

sub local_options {
    my $self = shift;
    return $self->last_step->options( @_ );
}

sub local_path {
    my $self = shift;
    return $self->last_step->path;
}

package Getopt::Chain::Context::Step;

use Moose;
use Getopt::Chain::Carp;

use Hash::Param;

use constant DEBUG => Getopt::Chain->DEBUG;
our $DEBUG = DEBUG;

has context => qw/is ro required 1 isa Getopt::Chain::Context/;

has _options => qw/is ro isa Hash::Param lazy_build 1/, handles => {qw/option param options params/};
sub _build__options {
    my $self = shift;
    return Hash::Param->new( params => {} );
}

has starting_arguments => qw/metaclass Collection::Array init_arg arguments accessor _starting_arguments required 1 isa ArrayRef/, provides => {qw/
    elements starting_arguments
/};

has remaining_arguments => qw/metaclass Collection::Array accessor _remaining_arguments isa ArrayRef lazy 1/, provides => {qw/
    elements remaining_arguments
    elements arguments
/}, default => sub { [] };

has argument_schema => qw/metaclass Collection::Array accessor _argument_schema required 1 isa ArrayRef/, provides => {qw/
    elements argument_schema
/};

has run => qw/is ro reader _run isa Maybe[CodeRef]/;

has _path => qw/metaclass Collection::Array is ro required 1 lazy 1 isa ArrayRef init_arg path/, default => sub { [] }, provides => {qw/
    elements    path
    last        last_path_part
    push        push_path
/};

has parent => qw/is ro isa Maybe[Getopt::Chain::Context::Step]/;

has dollar1 => qw/is ro/;

sub run {
    my $self = shift;
    my $control = shift;

    my $options = {};
    my $arguments = [ $self->starting_arguments ];
    my $argument_schema = [ $self->argument_schema ];
    my ( $last );

    warn "Context::Step::run ", $self->context->path_as_string, " [@$arguments] {@$argument_schema}\n" if $DEBUG;

    eval {
        $options = Getopt::Chain::Context::consume_arguments $argument_schema, $arguments;
        unless ( $control->{terminator} ) {
            if ( @$arguments && Getopt::Chain::Context::is_option_like $arguments->[0] ) {
                die "Unknown option-like argument: $arguments->[0]", "\n";
            }
        }
    };
    die "Exception at \"", join( '/', $self->path ), "\" with arguments [ @$arguments ]: $@" if $@;

    while (my ($key, $value) = each %$options) {
        $self->option( $key => $value );
        $self->context->option( $key => $value ); # TODO Better way to do this...
    }

    $self->_remaining_arguments( $arguments );
    if ( $control->{terminator} ) {
        $self->context->_parsing_arguments( [] );
        $last = 1;
    }
    else {
        $self->context->_parsing_arguments( [ @$arguments ] );
        $last = @$arguments ? 0 : 1; # Same as $ctx->last, really
    }
    
    unless ( $last || $control->{always_run} ) {
        warn "Context::Step::run ", $self->context->path_as_string, " SKIP\n" if DEBUG;
        return;
    }

    {
        # on 'A *'

        # A b -x c (Although this is an error condition)
        # A b -x c      $1 = ''     [ b -x c ]
        # A/b -x c      $1 = 'b'    [ -x c ] # Error, -x wasn't parsed!
        # A/b/c         $1 = 'b c'  [ ]

        # A b c d
        # A b c d       $1 = ''         [ b c d ]
        # A/b c d       $1 = 'b'        [ c d ]
        # A/b/c d       $1 = 'b c'      [ d ]
        # A/b/c/d       $1 = 'b c d'    [ ]

        my @arguments;
        push @arguments, grep { length } split m/\s+/, $self->dollar1 if defined $self->dollar1;
        push @arguments, @$arguments;
        my $run = $self->_run;
        $run->( $self->context, @arguments ) if $run;
    }

    return 1;
}

1;

