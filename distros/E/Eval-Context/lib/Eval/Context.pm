
package Eval::Context ;

use strict;
use warnings ;

BEGIN 
{
use vars qw ($VERSION);
$VERSION = '0.09' ;
}

#-------------------------------------------------------------------------------

use English qw( -no_match_vars ) ;

use Readonly ;
Readonly my $EMPTY_STRING => q{} ;

Readonly our $SHARED => 0 ;
Readonly our $PERSISTENT => 1 ;

my $flag ;
Readonly our $USE => bless \$flag, 'USE_PERSISTENT' ;

use Carp qw(carp croak confess) ;
use File::Slurp ;
use Sub::Install qw(install_sub reinstall_sub) ;
use Symbol qw(delete_package);
use Safe ;
use Data::Dumper ;

#-------------------------------------------------------------------------------

=head1 NAME

 Eval::Context - Evalute perl code in context wraper

=head1 SYNOPSIS

	use Eval::Context ;
	
	my $context = new Eval::Context(PRE_CODE => "use strict;\nuse warnings;\n") ;
	
	# code will be evaluated with strict and warnings loaded in the context.
	
	$context->eval(CODE => 'print "evaluated in an Eval::Context!" ;') ;
	$context->eval(CODE_FROM_FILE => 'file.pl') ;

=head1 DESCRIPTION

This module define a subroutine that let you evaluate Perl code in a specific context. The code can be passed directly as 
a string or as a file name to read from. It also provides some subroutines to let you define and optionally share
variables and subroutines between your code and the code you wish to evaluate. Finally there is some support for running
your code in a safe compartment.

=head1 Don't play with fire!

Don't start using this module, or any other module, thinking it will let you take code from anywhere and be
safe. Read perlsec, Safe, Opcode, Taint and other security related documents. Control your input.

=head1 SUBROUTINES/METHODS

Subroutines that are not part of the public interface are marked with [p].

=cut

#-------------------------------------------------------------------------------

Readonly my $NEW_ARGUMENTS => 
		[qw(
			NAME           PACKAGE    SAFE      PERL_EVAL_CONTEXT
			PRE_CODE       POST_CODE            REMOVE_PACKAGE_AFTER_EVAL
			INSTALL_SUBS   INSTALL_VARIABLES    EVAL_SIDE_PERSISTENT_VARIABLES
			INTERACTION    FILE       LINE      DISPLAY_SOURCE_IN_CONTEXT  
		)] ;

sub new
{

=head2 new(@named_arguments)

Create an Eval::Context object.  The object is used as a repository of "default" values for your code evaluations.
The context can be used many times. The values can be temporarily overridden during the C<eval> call.

  my $context = new Eval::Context() ; # default context
  
  my $context = new Eval::Context
		(
		NAME              => 'libraries evaluation context',
		PACKAGE           => 'libraries',
		SAFE              => {...} ;
		
		PRE_CODE          => "use strict ;\n"
		POST_CODE         => sub{},
		PERL_EVAL_CONTEXT => undef,
		
		INSTALL_SUBS      => {...},
		INSTALL_VARIABLES => [...],
		EVAL_SIDE_PERSISTENT_VARIABLES => {...},
		
		INTERACTION => {...},
		DISPLAY_SOURCE_IN_CONTEXT => 1, #useful when debuging
		) ;

I<ARGUMENTS>

=over 2

=item * @named_arguments - setup data for the object

All the arguments optional. The argument passed to C<new> can also be passed to C<eval>. All arguments are named.

=over 4

=item * NAME - use when displaying information about the object.

Set automatically to 'Anonymous' if not set. The name will also be reported
by perl if an error occurs during your code evaluation.

=item * PACKAGE - the package the code passed to C<eval> will evaluated be in.

If not set, a unique package name is generated and used for every C<eval> call. 

=item * REMOVE_PACKAGE_AFTER_EVAL - When set the content of the package after evaluation will be erase

The default behavior is to remove all data from after the call to C<eval>.

=item * PRE_CODE - code prepended to the code passed to I<eval>

=item * POST_CODE - code appended to the code passed to I<eval>

=item * PERL_EVAL_CONTEXT - the context to eval code in (void, scalar, list). 

This option Works as  L<perlfunc/wantarray>. It will override the context in which C<eval> is called.

=item * INSTALL_SUBS - subs that will be available in the eval. 

A hash where the keys are a function names and the values a code references.

=item * SAFE

This argument must be a hash reference. if the hash is empty, a default safe compartment will be used.
Read L<Safe> documentation for more information.

	SAFE => {} # default safe environment

You can have a finer control over the safe compartment B<Eval::Context> that will be used.

	my $compartment = new Safe('ABC') ;
	
	my $context = new Eval::Context
		(
		SAFE => # controlling the safe environment
			{
			PACKAGE     => 'ABC', 
			PRE_CODE    => "use my module ;\n" # code we consider safe
			USE_STRICT  => 0,                # set to 1 by default
			COMPARTMENT => $compartment ,   # use default if not passed
			} ,
		}
	
	$context->eval(CODE => .....) ;

=over 4

=item * COMPARTMENT - a Safe object, you create, that will be used by B<Eval::Context>

=item * USE_STRICT - Controls if L<strict> is used in the Safe compartment

The default is to use strict. Note that L<perldoc/Safe> default is to NOT use strict (undocumented).

=item * PRE_CODE - safe code you want to evaluate in the same context as the unsafe code

This let you, for example, use certain modules which provide subroutines to be used
in the evaluated code. The default compartment is quite restrictive and you can't even use 
L<strict> in it without tuning the safe compartment.

=back

A few remarks:

- See L<http://rt.cpan.org/Ticket/Display.html?id=31090> on RT

- Pass the same package name to your safe compartment and to B<Eval::Context>.

- If you really want to be on the safe side, control your input. When you use a module, are you
sure the module hasn't been fiddle with?

- Leave strict on. Even for trivial code.

=item * INSTALL_VARIABLES - "Give me sugar baby" Ash.

B<Eval::Context> has mechanisms you can use to set and share variables with the 
code you will evaluate. There are two sides in an B<Eval::Context>. The I<caller-side>, 
the side where the calls to C<eval> are made and the I<eval-side>, the side where the code to 
be evaluated is run.

=over 4

=item * How should you get values back from the eval-side

Although you can use the mechanisms below to get values from the I<eval-side>, the cleanest
way is to get the results directly from the C<eval> call.

	my $context = new Eval::Context() ;
	
	my ($scalr_new_value, $a_string) =
		$context->eval
			(
			INSTALL_VARIABLES =>[[ '$scalar'  => 42]] ,
			CODE => "\$scalar++ ;\n (\$scalar, 'a string') ;",
			) ;

=item * initializing variables on the I<eval side>

You can pass B<INSTALL_VARIABLES> to C<new> or C<eval>. You can initialize different variables
for each run of C<eval>.

	my $context = new Eval::Context
		(
		INSTALL_VARIABLES =>
			[
			# variables on eval-side    #initialization source
			[ '$data'                => 42],
			[ '$scalar'              => $scalar_caller_side ],
			[ '%hash'                => \%hash_caller_side ]
			[ '$hash'                => \%hash_caller_side ],
			[ '$object'              => $object ],
			] ,
		) ;

The variables will be B<my> variables on the eval-side.

You can declare variables of any of the base types supported by perl. The initialization
data , on the caller-side, is serialized and deserialized to make the values available
on the eval-side. Modifying the variables on the eval-side does not modify the variables
on the caller-side. The initialization data can be scalars or references and even B<my>
variables. 

=item * Persistent variables

When evaluating code many times in the same context, you may wish to have variables persist
between evaluations. B<Eval::Context> allows you to declare, define and control such
I<state> variables.

This mechanism lets you control which variables are persistent. Access to the persistent 
variables is controlled per C<eval> run. Persistent variables are B<my> variables on
the I<eval-side>. Modifying the variables on the eval-side does not modify the variables
on the I<caller-side>.

Define persistent variables:

	# note: creating persistent variables in 'new' makes little sense as
	# it will force those values in the persistent variables for every run.
	# This may or may not be what you want.
	
	my $context = new Eval::Context() ;
	
	$context->eval
		(
		INSTALL_VARIABLES =>
			[
			[ '$scalar'  => 42                 => $Eval::Context::PERSISTENT ] ,
			
			# make %hash and $hash available on the eval-side. both are
			# initialized from the same caller-side hash
			[ '%hash'    => \%hash_caller_side => $Eval::Context::PERSISTENT ] ,
			[ '$hash'    => \%hash_caller_side => $Eval::Context::PERSISTENT ] ,
			],
		CODE => '$scalar++',
		) ;

Later, use the persistent value:

	$context->eval
		(
		INSTALL_VARIABLES =>
			[
			[ '$scalar'  => $Eval::Context::USE => $Eval::Context::PERSISTENT ] ,
			# here you decided %hash and $hash shouldn't be available on the eval-side
			],
			
		CODE => '$scalar',
		) ;

B<$Eval::Context::USE> means I<"make the persistent variable and it's value available on the eval-side">.
Any other value will reinitialize the persistent variable. See also B<REMOVE_PERSISTENT> in C<eval>.

=item * Manually synchronizing caller-side data with persistent eval-side data

Although the first intent of persistent variables is to be used as state variables on
the eval-side, you can get persistent variables values on the caller-side. To change the
value of an I<eval-side> persistent variable, simply reinitialize it with B<INSTALL_VARIABLES>
next time you call C<eval>.

	my $context = new Eval::Context
			(
			INSTALL_VARIABLES =>
				[ 
				['%hash' => \%hash_caller_side => $Eval::Context::PERSISTENT] 
				] ,
			) ;
			
	$context->Eval(CODE => '$hash{A}++ ;') ;
	
	# throws exception if you request a non existing variable
	my %hash_after_eval = $context->GetPersistantVariables('%hash') ;
	

=item * Getting the list of all the PERSISTENT variables

	my @persistent_variable_names = $context->GetPersistantVariablesNames() ;

=item * Creating persistent variables on the eval-side

The mechanism above gave you fine control over persistent variables on the I<eval-side>. 
The negative side is that B<only> the variables you made persistent exist on the I<eval-side>.
B<Eval::Context> has another mechanism that allows the I<eval-side> to store variables 
between evaluations without the I<caller-side> declaration of the variables.

To allow the I<eval-side> to store any variable, add this to you C<new> call.

	my $context = new Eval::Context
		(
		PACKAGE => 'my_package',
		
		EVAL_SIDE_PERSISTENT_VARIABLES =>
			{
			SAVE => { NAME => 'SavePersistent', VALIDATOR => sub{} },
			GET  => { NAME => 'GetPersistent',  VALIDATOR => sub{} },
			},
		) ;

The I<eval-side> can now store variables between calls to C<eval>

	SavePersistent('name', $value) ;

later in another call to C<eval>:

	my $variable = GetPersistent('name') ;

By fine tuning B<EVAL_SIDE_PERSISTENT_VARIABLES> you can control what variables are stored
by the I<eval-side>. This should seldom be used and only to help those storing data from
the I<eval-side>.

You may have notices in the code above that a package name was passed as argument to C<new>. This
is very important as the package names that are automatically generated differ for each 
C<eval> call. If you want to run all you I<eval-side> code in different packages (B<Eval::Context> 
default behavior), you must tell B<Eval::Context> where to store the I<eval-side> values. This is
done by setting B<CATEGORY>

The validator sub can verify if the value to be stored are valid, E.G.: variable name, variable 
value is within range, ...

Here is an example of code run in different packages but can share variables. Only variables
which names start with I<A> are valid.

	new Eval::Context
		(
		EVAL_SIDE_PERSISTENT_VARIABLES =>
			{
			CATEGORY => 'TEST',
			SAVE => 
				{
				NAME => 'SavePersistent',
				VALIDATOR => sub 
					{
					my ($self, $name, $value, $package) = @_ ;
					$self->{INTERACTION}{DIE}->
						(
						$self,
						"SavePersistent: name '$name' doesn't start with A!"
						)  unless $name =~ /^A/ ;
					},
				},
				
			GET => {NAME => 'GetPersistent',VALIDATOR => sub {}},
			},
		) ;
	
	$context->eval(CODE => 'SavePersistent('A_variable', 123) ;') ;

later:

	$context->eval(CODE => 'GetPersistent('A_variable') ;') ;

=item * Shared variables

You can also share references between the I<caller-side> and the I<eval-side>.

	my $context = 
		new Eval::Context
			(
			INSTALL_VARIABLES =>
				[ 
				# reference to reference only
				[ '$scalar' => \$scalar           => $Eval::Context::SHARED ],
				[ '$hash'   => \%hash_caller_side => $Eval::Context::SHARED ],
				[ '$object' => $object            => $Eval::Context::SHARED ],
				] ,
			) ;

Modification of the variables on the I<eval-side> will modify the variable on the I<caller-side>.
There are but a few reasons to share references. Note that you can share references to B<my> variables.

=back

=item * INTERACTION

Lets you define subs used to interact with the user.

	INTERACTION      =>
		{
		INFO     => \&sub,
		WARN     => \&sub,
		DIE      => \&sub,
		EVAL_DIE => \&sub,
		}

=over 6

=item INFO - defaults to CORE::print

This sub will be used when displaying information.

=item WARN - defaults to Carp::carp

This sub will be used when a warning is displayed. 

=item DIE - defaults to Carp::confess

Used when an error occurs.

=item EVAL_DIE - defaults to Carp::confess, with a dump of the code to be evaluated

Used when an error occurs during code evaluation.

=back

=item * FILE - the file where the object has been created. 

This is practical if you want to wrap the object.

B<FILE> and B<LINE> will be set automatically if not set.

=item * LINE - the line where the object has been created. Set automatically if not set.

=item * DISPLAY_SOURCE_IN_CONTEXT - if set, the code to evaluated will be displayed before evaluation

=back

=back

I<Return>

=over 2

=item * an B<Eval::Context> object.

=back

=cut

my ($invocant, @setup_data) = @_ ;

my $class = ref($invocant) || $invocant ;
confess 'Invalid constructor call!' unless defined $class ;

my $object = {} ;

my ($package, $file_name, $line) = caller() ;
bless $object, $class ;

$object->Setup($package, $file_name, $line, @setup_data) ;

return($object) ;
}

#-------------------------------------------------------------------------------

sub Setup
{

=head2 [p] Setup

Helper sub called by new.

=cut

my ($self, $package, $file_name, $line, @setup_data) = @_ ;

my $inital_option_checking_context = { NAME => 'Anonymous eval context', FILE => $file_name, LINE => $line,} ;
SetInteractionDefault($inital_option_checking_context) ;

CheckOptionNames
	(
	$inital_option_checking_context,
	$NEW_ARGUMENTS,
	@setup_data
	) ;

%{$self} = 
	(
	NAME => 'Anonymous',
	FILE => $file_name,
	LINE => $line,
	REMOVE_PACKAGE_AFTER_EVAL => 1,
	
	@setup_data,
	) ;

if((! defined $self->{NAME}) || $self->{NAME} eq $EMPTY_STRING)
	{
	$self->{NAME} = 'Anonymous eval context' ;
	}

SetInteractionDefault($self) ;

return(1) ;
}

#-------------------------------------------------------------------------------

sub CheckOptionNames
{

=head2 [p] CheckOptionNames

Verifies the named options passed as arguments with a list of valid options. Calls B<{INTERACTION}{DIE}> in case
of error. 

=cut

my ($self, $valid_options, @options) = @_ ;

if (@options % 2)
	{
	$self->{INTERACTION}{DIE}->($self, "Invalid number of argument at '$self->{FILE}:$self->{LINE}'!") ;
	}

if('HASH' eq ref $valid_options)
	{
	# OK
	}
elsif('ARRAY' eq ref $valid_options)
	{
	$valid_options = {map{$_ => 1} @{$valid_options}} ;
	}
else
	{
	$self->{INTERACTION}{DIE}->($self, q{Invalid 'valid_options' definition! Should be an array or hash reference.}) ;
	}

my %options = @options ;

for my $option_name (keys %options)
	{
	unless(exists $valid_options->{$option_name})
		{
		$self->{INTERACTION}{DIE}->($self, "$self->{NAME}: Invalid Option '$option_name' at '$self->{FILE}:$self->{LINE}'!")  ;
		}
	}

if
	(
	   (defined $options{FILE} && ! defined $options{LINE})
	|| (!defined $options{FILE} && defined $options{LINE})
	)
	{
	$self->{INTERACTION}{DIE}->($self, "$self->{NAME}: Incomplete option FILE::LINE!") ;
	}

return(1) ;
}

#-------------------------------------------------------------------------------

sub SetInteractionDefault
{
	
=head2 [p] SetInteractionDefault

Sets {INTERACTION} fields that are not set by the user.

=cut

my ($interaction_container) = @_ ;

$interaction_container->{INTERACTION}{INFO} ||= sub {my (@information) = @_ ; print  @information} ; ## no critic (InputOutput::RequireCheckedSyscalls)
$interaction_container->{INTERACTION}{WARN} ||= \&Carp::carp ;
$interaction_container->{INTERACTION}{DIE}  ||= sub { my($self, @error) = @_ ; Carp::confess(@error)} ;

$interaction_container->{INTERACTION}{EVAL_DIE}  ||= 
	sub {
		my($self, $error) = @_ ;
		Carp::confess
			(
			"*** Eval::Context code ***\n"
			. $self->{LATEST_CODE}
			. "\n*** Error below ***\n"
			. $error
			) ;
		}  ;

return ;
}

#-------------------------------------------------------------------------------

sub CanonizeName 
{
	
=head2 [p] CanonizeName

Transform a string into a a string with can be used as a package name or file name usable
within perl code.

=cut

my ($name) = @_ ;

croak 'CanonizeName called with undefined argument!' unless defined $name ;

$name =~ s/[^a-zA-Z0-9_:\.]/_/xsmg ;

return($name) ;
}

#-------------------------------------------------------------------------------

Readonly my $EVAL_ARGUMENTS => [@{$NEW_ARGUMENTS}, qw(CODE CODE_FROM_FILE REMOVE_PERSISTENT)] ;

sub eval ## no critic (Subroutines::ProhibitBuiltinHomonyms ErrorHandling::RequireCheckingReturnValueOfEval)
{

=head2 eval(@named_arguments)

Evaluates Perl code, passed as a string or read from a file, in the context.

	my $context = new Eval::Context(PRE_CODE => "use strict;\nuse warnings;\n") ;
	
	$context->eval(CODE => 'print "evaluated in an Eval::Context!";') ;
	$context->eval(CODE_FROM_FILE => 'file.pl') ;

I<Call context>

Evaluation context of the code (void, scalar, list) is the same as the context this subroutine was called in
or in the context defined by B<PERL_EVAL_CONTEXT> if that option is present.

I<Arguments>

B<NOTE: You can override any argument passed to >C<new>B<. The override is temporary during
the duration of this call.>

=over 2

=item * @named_arguments - Any of C<new> options plus the following.

=over 4

=item * CODE - a string containing perl code (valid code or an exception is raised)

=item * CODE_FROM_FILE - a file containing  perl code

=item * REMOVE_PERSISTENT 

A list of regex used to match the persistent variable names to be removed, persistent variable removal
is done before any variable installation is done

=item * FILE and LINE - will be used in the evaluated code 'file_name' set to the caller's file and line by default

=back

NOTE: B<CODE> or B<CODE_FROM_FILE> is B<mandatory>.

=back

I<Return>

=over 2

=item * What the code to be evaluated returns

=back

=cut

my ($self, @options) = @_  ;

my $options = $self->VerifyAndCompleteOptions($EVAL_ARGUMENTS, @options) ;

$options->{PERL_EVAL_CONTEXT} = wantarray unless exists $options->{PERL_EVAL_CONTEXT} ;

my ($package, $variables_setup, $variables_teardown) = $self->EvalSetup($options) ;

my ($code_start, $code_end, $return) = $self->GetCallContextWrapper($variables_setup, $options) ;

my ($package_setup, $compartment, $compartment_use_strict, $pre_code_commented_out) 
	= $self->SetupSafeCompartment($package, $options) ;

$self->VerifyCodeInput($options) ;

$self->{LATEST_CODE} = "#line 0 '$options->{EVAL_FILE_NAME}'\n" ;

for
	(
	$package_setup,
	$pre_code_commented_out,
	'# PRE_CODE',
	$options->{PRE_CODE},
	$variables_setup,
	$code_start,
	"#line 0 '$options->{EVAL_FILE_NAME}'",
	'# CODE',
	$options->{CODE},
	'# POST_CODE',
	$options->{POST_CODE},
	$code_end,
	$variables_teardown,
	$return,
	"#end of context '$options->{EVAL_FILE_NAME}'",
	)
	{
	$self->{LATEST_CODE} .= "$_\n" if defined $_ ;
	}

if($options->{DISPLAY_SOURCE_IN_CONTEXT})
	{
	$options->{INTERACTION}{INFO}
		->("Eval::Context called at '$options->{FILE}:$options->{LINE}' to evaluate:\n" . $self->{LATEST_CODE}) ;
	}
	
if(defined $options->{PERL_EVAL_CONTEXT})
	{
	if($options->{PERL_EVAL_CONTEXT})
		{
		my  @results = 
			$compartment
				? $compartment->reval($self->{LATEST_CODE}, $compartment_use_strict)
				: eval $self->{LATEST_CODE} ; ## no critic (BuiltinFunctions::ProhibitStringyEval)
		
		$options->{INTERACTION}{EVAL_DIE}->($self, $EVAL_ERROR) if($EVAL_ERROR) ;
		$self->EvalCleanup($options) ;
		
		return @results ;
		}
	else
		{
		my $result = 
			$compartment
				? $compartment->reval($self->{LATEST_CODE}, $compartment_use_strict)
				: eval $self->{LATEST_CODE} ; ## no critic (BuiltinFunctions::ProhibitStringyEval)
		
		$options->{INTERACTION}{EVAL_DIE}->($self, $EVAL_ERROR) if($EVAL_ERROR) ;
		$self->EvalCleanup($options) ;
		
		return $result ;
		}
	}
else
	{
	defined $compartment
		? $compartment->reval($self->{LATEST_CODE}, $compartment_use_strict)
		: eval $self->{LATEST_CODE} ; ## no critic (BuiltinFunctions::ProhibitStringyEval)
	
	$options->{INTERACTION}{EVAL_DIE}->($self, $EVAL_ERROR) if($EVAL_ERROR) ;
	$self->EvalCleanup($options) ;
		
	return ;
	}
}

#-------------------------------------------------------------------------------

sub VerifyAndCompleteOptions
{

=head2 [p] VerifyAndCompleteOptions

Helper sub for C<eval>.

=cut

my ($self, $allowed_arguments, @options) = @_ ;

$self->CheckOptionNames($allowed_arguments, @options) ;

my %options = @options ;

unless(defined $options{FILE})
	{
	my ($package, $file_name, $line) = caller(1) ;
	push @options, FILE => $file_name, LINE => $line
	}
	
%options = (%{$self}, @options) ;

$options{NAME} = CanonizeName($options{NAME} . " called at $options{FILE}:$options{LINE}") ;

SetInteractionDefault(\%options) ;

return(\%options) ;
}

#-------------------------------------------------------------------------------

sub EvalCleanup
{

=head2 [p] EvalCleanup

Handles the package cleanup or persistent variables cleanup after a call to C<eval>.

=cut

my ($self, $options) = @_ ;

if($options->{REMOVE_PACKAGE_AFTER_EVAL})
	{
	delete_package($self->{CURRENT_RUNNING_PACKAGE})
	}
else
	{
	if(defined $options->{EVAL_SIDE_PERSISTENT_VARIABLES})
		{
		$self->RemoveEvalSidePersistenceHandlers($options) ;
		}
	}

return(1) ;
}

#-------------------------------------------------------------------------------

my $eval_run = 0 ;

sub GetPackageName
{

=head2 [p] GetPackageName

Returns a canonized package name. the name is either passed as argument from the caller
or a temporary package name.

=cut

my ($options) = @_ ;

my $package = exists $options->{PACKAGE} && defined $options->{PACKAGE}
		? CanonizeName($options->{PACKAGE})
		: "Eval::Context::Run_$eval_run" ;

$package = $package eq $EMPTY_STRING ? "Eval::Context::Run_$eval_run" : $package ;

$eval_run++ ;

return($package) ;
}

#-------------------------------------------------------------------------------

sub EvalSetup
{

=head2 [p] EvalSetup

Handles the setup of the context before I<eval-side> code is evaluated. Sets
the variables and the shared subroutines.

=cut

my ($self, $options) = @_ ;

my $package = $self->{CURRENT_RUNNING_PACKAGE} = GetPackageName($options) ;

$self->RemovePersistent($options) ;

my ($variables_setup, $variables_teardown) = (undef, undef) ;

if(defined $options->{INSTALL_VARIABLES})
	{
	($variables_setup, $variables_teardown) = $self->GetInstalledVariablesCode($options) ;
	}

for my $sub_name (keys %{$options->{INSTALL_SUBS}})
	{
	if('CODE' ne ref $options->{INSTALL_SUBS}{$sub_name} )
		{
		$options->{INTERACTION}{DIE}->($self, "$self->{NAME}: '$sub_name' from 'INSTALL_SUBS' isn't a code reference at '$options->{FILE}:$options->{LINE}'!")  ;
		}
		
	reinstall_sub({ code => $options->{INSTALL_SUBS}{$sub_name}, into => $package, as => $sub_name }) ;
	}
	
if(defined $options->{EVAL_SIDE_PERSISTENT_VARIABLES})
	{
	$self->SetEvalSidePersistenceHandlers($options) ;
	}

return ($package, $variables_setup, $variables_teardown) ;
}

#-------------------------------------------------------------------------------

sub VerifyCodeInput
{

=head2 [p] VerifyCodeInput

Verify that B<CODE> or B<CODE_FROM_FILE> are properly set.

=cut

my ($self, $options) = @_ ;

$options->{EVAL_FILE_NAME} = $options->{NAME} || 'Anonymous' ;

$options->{PRE_CODE} = defined $options->{PRE_CODE} ? $options->{PRE_CODE} : $EMPTY_STRING ;

if(exists $options->{CODE_FROM_FILE} && exists $options->{CODE} )
	{
	$options->{INTERACTION}{DIE}->($self, "$self->{NAME}: Option 'CODE' and 'CODE_FROM_FILE' can't coexist at '$options->{FILE}:$options->{LINE}'!")  ;
	}

if(exists $options->{CODE_FROM_FILE} && defined $options->{CODE_FROM_FILE})
	{
	$options->{CODE} = read_file($options->{CODE_FROM_FILE}) ;
	$options->{NAME} = CanonizeName($options->{CODE_FROM_FILE}) ;
	$options->{EVAL_FILE_NAME} = $options->{CODE_FROM_FILE} ;
	}

unless(exists $options->{CODE} && defined $options->{CODE})
	{
	$options->{INTERACTION}{DIE}->($self, "$self->{NAME}: Invalid Option 'CODE' at '$options->{FILE}:$options->{LINE}'!")  ;
	}

$options->{POST_CODE} = defined $options->{POST_CODE} ? $options->{POST_CODE} : $EMPTY_STRING ;

return(1) ;
}

#-------------------------------------------------------------------------------

sub RemovePersistent
{

=head2 [p] RemovePersistent

Handles the removal of persistent variables.

=cut

my ($self, $options) = @_ ;

if(exists $options->{REMOVE_PERSISTENT})
	{
	if('ARRAY' ne ref $options->{REMOVE_PERSISTENT})
		{
		$options->{INTERACTION}{DIE}->
			(
			$self,
			"$self->{NAME}: 'REMOVE_PERSISTENT' must be an array reference containing regexes at '$options->{FILE}:$options->{LINE}'!"
			)  ;
		}
		
	for my $regex (@{ $options->{REMOVE_PERSISTENT} })
		{
		for my $name ( keys %{ $self->{PERSISTENT_VARIABLES} })
			{
			delete $self->{PERSISTENT_VARIABLES}{$name} if($name =~ $regex) ;
			}
		}
	}
	
return(1) ;
}

#-------------------------------------------------------------------------------

sub GetCallContextWrapper
{

=head2 [p] GetCallContextWrapper

Generates perl code to wrap the code to be evaluated in the right calling context.

=cut

my ($self, $variables_setup, $options) = @_ ;

my ($code_start, $code_end, $return) = (undef, undef, undef) ; # defaults for void context

if(defined $variables_setup)
	{
	if(defined $options->{PERL_EVAL_CONTEXT})
		{
		if($options->{PERL_EVAL_CONTEXT})
			{
			# array context
			($code_start, $code_end, $return) = 
				(
				"my \@eval_context_result = do {\n",
				"} ;\n",
				"\@eval_context_result ;\n",
				) ;
			}
		else
			{
			# scalar context
			($code_start, $code_end, $return) = 
				(
				"my \$eval_context_result = do {\n",
				"} ;\n",
				"\$eval_context_result ;\n",
				) ;
			}
		}
	else
		{
		# void context
		($code_start, $code_end, $return) = ($EMPTY_STRING, $EMPTY_STRING, $EMPTY_STRING) ;
		}
	}

return($code_start, $code_end, $return) ;
}

#-------------------------------------------------------------------------------
	
sub SetupSafeCompartment
{

=head2 [p] SetupSafeCompartment

If running in safe mode, setup a safe compartment from the argument, otherwise defines the evaluation package.

=cut

my ($self, $package, $options) = @_ ;

my ($package_setup, $compartment, $compartment_use_strict, $pre_code_commented_out) = (undef, undef, 1, undef) ;

if(exists $options->{SAFE})
	{
	if('HASH' eq ref $options->{SAFE})
		{
		if(exists $options->{SAFE}{PRE_CODE})
			{
			# must be done before creating the safe compartment
			my $pre_code = "\npackage " . $package . " ;\n" . $options->{SAFE}{PRE_CODE} ;
			
			eval $pre_code ; ## no critic (BuiltinFunctions::ProhibitStringyEval)
			
			if($EVAL_ERROR) 
				{
				$self->{LATEST_CODE} = $pre_code ;
				$options->{INTERACTION}{EVAL_DIE}->($self, $EVAL_ERROR) ;
				}
			
			$pre_code_commented_out = 
				"#  Note: evaluated PRE_CODE before running SAFE code\n" 
				. "=comment\n\n"
				. $pre_code
				. "\n\n=cut\n" ;
			}
			
		if(exists $options->{SAFE}{COMPARTMENT})
			{
			$compartment = $options->{SAFE}{COMPARTMENT} ;
			}
		else
			{
			$compartment = new Safe($package) ;
			}
		
		$compartment_use_strict = $options->{SAFE}{USE_STRICT} if exists $options->{SAFE}{USE_STRICT} ;
		}
	else
		{
		$options->{INTERACTION}{DIE}->($self, "$self->{NAME}: Invalid Option 'SAFE' definition at '$options->{FILE}:$options->{LINE}'!")  ;
		}

	}
else
	{
	$package_setup = "package $package ;" 
	}
	
return($package_setup, $compartment, $compartment_use_strict, $pre_code_commented_out)	;
}

#-------------------------------------------------------------------------------

Readonly my $SET_FROM_CALLER => 2 ;
Readonly my $SET_FROM_CALLER_WITH_TYPE => 3 ;

Readonly my $NAME_INDEX => 0 ;
Readonly my $VALUE_INDEX => 1 ;
Readonly my $TYPE_INDEX => 2 ;

sub GetInstalledVariablesCode
{

=head2 [p] GetInstalledVariablesCode

Generates variables on the eval-side from the INSTALL_VARIABLES definitions.
Dispatches the generation to specialize subroutines.

=cut

my ($self, $options) = @_ ;

my ($setup_code, $teardown_code) = ($EMPTY_STRING, $EMPTY_STRING) ;

for my $variable_definition (@{ $options->{INSTALL_VARIABLES} })
	{
	my $definition_type = scalar(@{$variable_definition}) ;
	
	my $variable_name   = $variable_definition->[$NAME_INDEX] ;
	my $variable_value  = $variable_definition->[$VALUE_INDEX] ;
	my $variable_type   = ref $variable_value ;
	
	if($SET_FROM_CALLER == $definition_type)
		{
		my ($setup, $teardown) = $self->GetVariablesSetFromCaller($options, $variable_name, $variable_value, $variable_type) ;
		
		$setup_code .= $setup ;
		$teardown_code .= $teardown ;
		}
	elsif($SET_FROM_CALLER_WITH_TYPE == $definition_type)
		{
		if($variable_definition->[$TYPE_INDEX] == $PERSISTENT)
			{
			my ($setup, $teardown) = $self->GetPersistentVariablesSetFromCaller
							(
							$options,
							$variable_name,
							$variable_value,
							$variable_type,
							) ;
							
			$setup_code .= $setup ;
			$teardown_code .= $teardown ;
			}
		elsif($variable_definition->[$TYPE_INDEX] == $SHARED)
			{
			my ($setup, $teardown) = $self->GetSharedVariablesSetFromCaller
							(
							$options,
							$variable_name,
							$variable_value,
							$variable_type,
							) ;
							
			$setup_code .= $setup ;
			$teardown_code .= $teardown ;
			}
		else
			{
			$self->{INTERACTION}{DIE}->($self, "Variable '$variable_name' type must be SHARED or PERSISTENT at '$options->{FILE}:$options->{LINE}'!") ;
			}
		}
	else
		{
		$self->{INTERACTION}{DIE}->($self, "Invalid variable definition at '$options->{FILE}:$options->{LINE}'!") ;
		}
	}

return($setup_code, $teardown_code) ;
}

#-------------------------------------------------------------------------------

my $temporary_name_index = 0 ;

sub GetPersistentVariablesSetFromCaller
{
	
=head2 [p] GetPersistentVariablesSetFromCaller

Generates code to make persistent variables, defined on the I<caller-side> available on the I<eval-side>.

=cut

my ($self, $options, $variable_name, $variable_value, $variable_type) = @_ ;

my $persistance_handler_name = 'EvalContextSavePersistentVariable' ;

my ($setup_code, $teardown_code) = ($EMPTY_STRING, $EMPTY_STRING) ;

if(exists $self->{SHARED_VARIABLES}{$variable_name})
	{
	$self->{INTERACTION}{DIE}->($self, "'$variable_name' can't be PERSISTENT, already SHARED, at '$options->{FILE}:$options->{LINE}'!") ;
	}

if(! exists $self->{PERSISTENT_VARIABLES}{$variable_name})
	{
	($setup_code, undef) = $self->GetVariablesSetFromCaller($options, $variable_name, $variable_value, $variable_type) ;
	$setup_code = "# PERSISTENT, did not exist '$variable_name'\n" . $setup_code ;
	}
else
	{
	if(ref $variable_value eq 'USE_PERSISTENT')
		{
		$setup_code = "# PERSISTENT, existed '$variable_name'\n"
				. "my $self->{PERSISTENT_VARIABLES}{$variable_name}\n" ;
		}
	else
		{
		($setup_code, undef) = $self->GetVariablesSetFromCaller($options, $variable_name, $variable_value, $variable_type) ;
		$setup_code = "# PERSISTENT, existed '$variable_name', overridden \n" . $setup_code ;
		}
	}
	
# save the persistent variables after the user code is run
$teardown_code = "$persistance_handler_name('$variable_name', \\$variable_name) ;\n" ;

# install the subroutines needed to save the persistent variables
reinstall_sub
	({
	code => sub 
		{
		my ($variable_name, $variable_ref) = @_ ;
		
		my $dump_name = $variable_name ;
		substr($dump_name, 0, 1, $EMPTY_STRING) ;
		
		if('SCALAR' eq ref $variable_ref)
			{
			if(defined ${$variable_ref})
				{
				$self->{PERSISTENT_VARIABLES}{$variable_name} = "$variable_name = '${$variable_ref}' ;" ;
				}
			else
				{
				$self->{PERSISTENT_VARIABLES}{$variable_name} = "$variable_name = undef ;" ;
				}
			}
		elsif('REF' eq ref $variable_ref)
			{
			$self->{PERSISTENT_VARIABLES}{$variable_name} = Data::Dumper->Dump([${$variable_ref}], [$dump_name]) ;
			}
		else
			{
			# convert and serialize at once
			my ($sigil, $name) = $variable_name =~ /(.)(.*)/sxm ;
			
			$self->{PERSISTENT_VARIABLES}{$variable_name} = Data::Dumper->Dump([$variable_ref], [$name]) ;
			$self->{PERSISTENT_VARIABLES}{$variable_name} =~ s/\$$name\ =\ ./$variable_name = (/xsm ;
			$self->{PERSISTENT_VARIABLES}{$variable_name} =~ s/.;\Z/) ;/xsm ;
			}
		},
		
	into => $self->{CURRENT_RUNNING_PACKAGE},
	as => $persistance_handler_name,
	}) ;
	
return($setup_code, $teardown_code) ;
}

#-------------------------------------------------------------------------------

our %shared_variables ; ## no critic (Variables::ProhibitPackageVars)

sub GetSharedVariablesSetFromCaller
{

=head2 [p] GetSharedVariablesSetFromCaller

Handles the mechanism used to share variables (references) between the I<caller-side> 
and the I<eval-side>.

Shared variables must be defined and references. If the shared variable is B<undef>, the variable
that was previously shared, under the passed name, is used if it exists or an exception is raised.

Also check that variables are not B<PERSISTENT> and B<SHARED>.

=cut

my ($self, $options, $variable_name, $variable_value, $variable_type) = @_ ;

my ($setup_code, $teardown_code) = ($EMPTY_STRING, $EMPTY_STRING) ;

if(exists $self->{PERSISTENT_VARIABLES}{$variable_name})
	{
	$self->{INTERACTION}{DIE}->($self, "'$variable_name' can't be SHARED, already PERSISTENT, at '$options->{FILE}:$options->{LINE}'!") ;
	}

if(defined $variable_value)
	{
	if($EMPTY_STRING eq ref $variable_value)
		{
		$self->{INTERACTION}{DIE}->($self, "Need a reference to share from for '$variable_name' at '$options->{FILE}:$options->{LINE}'!") ;
		}

	my $variable_share_name = "${variable_name}_$self->{FILE}_$self->{LINE}_$temporary_name_index" ;
	$variable_share_name =~ s/[^a-zA-Z0-9_]+/_/xsmg ;
	$temporary_name_index++ ;
	
	$shared_variables{$variable_share_name} = $variable_value ;
	
	if(exists $options->{SAFE})
		{
		$self->{SHARED_VARIABLES}{$variable_name} =  $variable_share_name ;
		}
	else
		{
		# faster method
		$self->{SHARED_VARIABLES}{$variable_name} =  q{$} . __PACKAGE__ . "::shared_variables{$variable_share_name}" ;
		}
	}
	
if(exists $self->{SHARED_VARIABLES}{$variable_name})
	{
	if(exists $options->{SAFE})
		{
		$setup_code = "my $variable_name = EvalContextSharedVariable('$self->{SHARED_VARIABLES}{$variable_name}') ;\n" ;
		
		reinstall_sub({
			code => sub {my ($variable_name) = @_ ; return($shared_variables{$variable_name}) ;},
			into => $self->{CURRENT_RUNNING_PACKAGE},
			as => 'EvalContextSharedVariable', 
			}) ;
		}
	else
		{
		$setup_code = "my $variable_name = $self->{SHARED_VARIABLES}{$variable_name} ;\n" ; # not in Safe, we can access other packages
		}
	}
else
	{
	$self->{INTERACTION}{DIE}->($self, "Nothing previously shared to '$variable_name' at '$options->{FILE}:$options->{LINE}'!") ;
	}
	
return($setup_code, $teardown_code) ;
}

#-------------------------------------------------------------------------------

my %valid_sigil = map {$_ => 1} qw($ @ %) ;

sub GetVariablesSetFromCaller
{
	
=head2 [p] GetVariablesSetFromCaller

Generates code that creates local variables on the I<eval-side>

=cut

my ($self, $options, $variable_name, $variable_value, $variable_type) = @_ ;

my $DIE = $self->{INTERACTION}{DIE} ;
my $code_to_evaluate  = $EMPTY_STRING ;

my ($sigil, $name) = $variable_name =~ /(.)(.*)/sxm ;
$DIE->($self, "Invalid variable type for '$variable_name' at '$options->{FILE}:$options->{LINE}'!") unless $valid_sigil{$sigil} ;

if(! defined $variable_value)
	{
	$code_to_evaluate .= "my $variable_name = undef ;\n" ;
	}
else
	{
	if($EMPTY_STRING eq $variable_type)
		{
		$code_to_evaluate .= "my $variable_name = '$variable_value';\n" ;
		}
	else
		{
		# set from reference
		my $conversion = $EMPTY_STRING ;
		
		if($sigil eq q{$})
			{
			# reference to reference, no conversion needed
			$conversion = Data::Dumper->Dump([$variable_value], [$variable_name] ) ;
			}
		else
			{
			$conversion = Data::Dumper->Dump([$variable_value], [$name]) ;
			$conversion =~ s/\A\$$name\ =\ ./$variable_name = (/xsm ;
			$conversion =~ s/.;\Z/) ;/xsm ;
			}
			
		$code_to_evaluate .= "my $conversion" ;
		}
	}
	
return($code_to_evaluate, $EMPTY_STRING)  ;
}

#-------------------------------------------------------------------------------

sub GetPersistentVariableNames
{

=head2 GetPersistentVariableNames()

I<Arguments> - none

I<Returns> - the list of existing persistent variables names

	my @persistent_variable_names = $context->GetPersistantVariablesNames() ;

=cut

my ($self) = @_ ;

return(keys %{ $self->{PERSISTENT_VARIABLES} }) ;
}

#-------------------------------------------------------------------------------

sub GetPersistantVariables
{

=head2 GetPersistantVariables(@variable_names)

I<Arguments>

=over 2

=item * @variable_names - list of variable names to retrieve

=back

I<Returns> - list of values corresponding to the input names

This subroutine will return whatever the I<caller-site> set or the I<eval-side> modified. Thus if
you created a I<%hash> persistent variable, a hash (not a hash reference) will be returned.

If you request multiple values, list flattening will be in effect. Be careful.

	my $context = new Eval::Context
			(
			INSTALL_VARIABLES =>
				[ 
				['%hash' => \%hash_caller_side => $Eval::Context::PERSISTENT] 
				] ,
			) ;
			
	$context->Eval(CODE => '$hash{A}++ ;') ;
	
	# may throw exception
	my %hash_after_eval = $context->GetPersistantVariables('%hash') ;

=cut

my ($self, @variable_names) = @_ ;

my ($package, $file_name, $line) = caller() ;
my @values ;

for my $variable_name (@variable_names)
	{
	if(exists $self->{PERSISTENT_VARIABLES}{$variable_name})
		{
		my @variable_values = eval 'my ' . $self->{PERSISTENT_VARIABLES}{$variable_name} ; ## no critic (BuiltinFunctions::ProhibitStringyEval)
		push @values, @variable_values ;
		}
	else
		{
		$self->{INTERACTION}{DIE}->
			(
			$self,
			"PERSISTENT variable '$variable_name' doesn't exist, can't be fetched at '$file_name:$line'!"
			) ;
		}
	}

if(defined wantarray)
	{
	if(wantarray)
		{
		return(@values) ;
		}
	else
		{
		return $values[0] ;
		}
	}
else
	{
	return #PBP
		(
		$self->{INTERACTION}{DIE}->
			(
			$self,
			"GetPersistantVariables called in void context at '$file_name:$line'!"
			) 
		)
	}
}

#-------------------------------------------------------------------------------

sub SetEvalSidePersistenceHandlers
{

=head2 [p] SetEvalSidePersistenceHandlers

Set the code needed to handle I<eval-side> persistent variables.

=cut

my ($self, $options) = @_ ;

if('HASH' eq ref $options->{EVAL_SIDE_PERSISTENT_VARIABLES})
	{
	my $category = defined $options->{EVAL_SIDE_PERSISTENT_VARIABLES}{CATEGORY}
			? $options->{EVAL_SIDE_PERSISTENT_VARIABLES}{CATEGORY}
			: $self->{CURRENT_RUNNING_PACKAGE} ;
	
	my %handler_sub_validators ;
	my %handler_subs =
		(
		SAVE => sub
			{
			my (@name_values) = @_ ;
			
			if(scalar(@_) % 2)
				{
				my ($package, $file_name, $line) = caller() ;
				
				$self->{INTERACTION}{DIE}->
					(
					$self,
					"$self->{NAME}: eval-side persistence handler got unexpected number of arguments "
					. "at '$file_name:$line'!"
					)   ;
				}
				
			while(my ($variable_name, $value) = splice(@name_values, 0, 2))
				{
				$handler_sub_validators{SAVE}->($self, $variable_name, $value) ;
				
				$self->{PERSISTENT_VARIABLES_FOR_EVAL_SIDE}{$category}{$variable_name} = $value ;
				}
			},
			
		GET  => sub
			{
			my @values ;
			
			for my $variable_name (@_)
				{
				$handler_sub_validators{GET}->($self, $variable_name) ;
				
				push @values, $self->{PERSISTENT_VARIABLES_FOR_EVAL_SIDE}{$category}{$variable_name} ;
				}
			
			return wantarray ? @values : $values[0] ;
			},
			
		) ;
	
	for my $handler_type ('SAVE', 'GET')
		{
		if(exists $options->{EVAL_SIDE_PERSISTENT_VARIABLES}{$handler_type})
			{
			if
				(
				   exists $options->{EVAL_SIDE_PERSISTENT_VARIABLES}{$handler_type}{VALIDATOR}
				&& 'CODE' eq ref $options->{EVAL_SIDE_PERSISTENT_VARIABLES}{$handler_type}{VALIDATOR}
				&& $EMPTY_STRING eq ref $options->{EVAL_SIDE_PERSISTENT_VARIABLES}{$handler_type}{NAME}
				&& $EMPTY_STRING ne $options->{EVAL_SIDE_PERSISTENT_VARIABLES}{$handler_type}{NAME}
				)
				{
				$handler_sub_validators{$handler_type} = $options->{EVAL_SIDE_PERSISTENT_VARIABLES}{$handler_type}{VALIDATOR} ;
				
				reinstall_sub({
					code => $handler_subs{$handler_type},
					into => $self->{CURRENT_RUNNING_PACKAGE},
					as => $options->{EVAL_SIDE_PERSISTENT_VARIABLES}{$handler_type}{NAME}
					}) ;
				}
			else
				{
				$options->{INTERACTION}{DIE}->
					(
					$self,
					"$self->{NAME}: 'EVAL_SIDE_PERSISTENT_VARIABLES' invalid definition "
					. "at '$options->{FILE}:$options->{LINE}'!"
					)  ;
				}
			}
		else
			{
			$options->{INTERACTION}{DIE}->
				(
				$self,
				"$self->{NAME}: 'EVAL_SIDE_PERSISTENT_VARIABLES' missing handler definition "
				. "at '$options->{FILE}:$options->{LINE}'!"
				)  ;
			}
		}
		
	if($options->{EVAL_SIDE_PERSISTENT_VARIABLES}{SAVE}{NAME} eq $options->{EVAL_SIDE_PERSISTENT_VARIABLES}{GET}{NAME})
		{
		$options->{INTERACTION}{DIE}->
			(
			$self,
			"$self->{NAME}: invalid definition, eval-side persistence handlers have the same name "
			. "at '$options->{FILE}:$options->{LINE}'!"
			)  ;
		}
	}
else
	{
	$options->{INTERACTION}{DIE}->($self, "$self->{NAME}: 'EVAL_SIDE_PERSISTENT_VARIABLES' isn't a hash reference at '$options->{FILE}:$options->{LINE}'!")  ;
	}
	
return(1) ;
}

#-------------------------------------------------------------------------------

sub RemoveEvalSidePersistenceHandlers
{

=head2 [p] RemoveEvalSidePersistenceHandlers

Removes I<eval-side> persistent variable handlers. Used after calling C<eval> so the
next C<eval> can not access I<eval-side> persistent variables without being allowed to do so.

=cut

my ($self, $options) = @_ ;

for my $handler_type ('SAVE', 'GET')
	{
	reinstall_sub({
		code => sub 
			{
			$options->{INTERACTION}{DIE}->
					(
					$self,
					"$self->{NAME}: No Persistence allowed on eval-side in package '$self->{CURRENT_RUNNING_PACKAGE}'!\n"
					) ;
			},
			
		into => $self->{CURRENT_RUNNING_PACKAGE},
		as => $options->{EVAL_SIDE_PERSISTENT_VARIABLES}{$handler_type}{NAME}
		}) ;
	}

return(1) ;
}

#-------------------------------------------------------------------------------

1 ;

=head1 BUGS AND LIMITATIONS

I have reported a very strange error when B<Safe> and B<Carp> are used together.
L<http://rt.cpan.org/Ticket/Display.html?id=31090>. The error can be reproduced
without using B<Eval::Context>.

=head1 AUTHOR

	Khemir Nadim ibn Hamouda
	CPAN ID: NKH
	mailto:nadim@khemir.net

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Eval::Context

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Eval-Context>

=item * RT: CPAN's request tracker

Please report any bugs or feature requests to  L <bug-eval-context@rt.cpan.org>.

We will be notified, and then you'll automatically be notified of progress on
your bug as we make changes.

=item * Search CPAN

L<http://search.cpan.org/dist/Eval-Context>

=back

=cut
