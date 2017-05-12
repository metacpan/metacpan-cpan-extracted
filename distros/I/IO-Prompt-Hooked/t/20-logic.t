
use strict;
use warnings;
use Test::More;
use IO::Prompt::Hooked;

use constant EMPTY_STRING => q{};

our $TEST_INPUT;
our $TEST_MESSAGE;
our $TEST_DEFAULT;
our $TEST_RESULT;

local $ENV{PERL_MM_USE_DEFAULT} = 0; # Tests self-manage interactivity.

{
  no warnings 'redefine';
  *IO::Prompt::Hooked::_is_interactive = sub { 1 };
}

# Override IO::Prompt::Tiny::prompt so that we don't need to capture input and
# output.  We're going to take the leap of faith that IO::Prompt::tiny already
# does what it should.  We only want to test the functionality we're layering
# on top of it.

{
    no warnings 'redefine';
    *IO::Prompt::Tiny::prompt = sub {
        my ( $message, $default ) = @_;
        $TEST_MESSAGE = $message;
        $TEST_DEFAULT = $default;
        if ( $ENV{PERL_MM_USE_DEFAULT} ) {
            return defined $default ? $default : EMPTY_STRING;
        }
        my $input =
            ( defined $TEST_INPUT && length $TEST_INPUT ) ? $TEST_INPUT
          : defined $default ? $default
          :                    EMPTY_STRING;
        return $input;
    };
}

# Basic tests: Positional arguments.  Positional args should behave like
# IO::Prompt::Tiny, with no changes.

# Given a prompt message, a default, and known input, we get back the input.
{
    local $ENV{PERL_MM_USE_DEFAULT} = undef;
    $TEST_INPUT = 'Good day.';
    is( prompt( 'Hello world.', 'Howdy' ),
        'Good day.', 'Positional params return input.' );
}

# Our positional $message parameter passed through to IO::Prompt::Tiny::prompt.
is( $TEST_MESSAGE, 'Hello world.',
    'Positional params pass the prompt message.' );

# Our positional default parameter passed through to IO::Prompt::Tiny::prompt.
is( $TEST_DEFAULT, 'Howdy', 'Positional params pass the default.' );


# Verify that if no message is specified, or if message is undefined,
# we get an empty string message.
{
    local $ENV{PERL_MM_USE_DEFAULT} = undef;
    $TEST_INPUT = 'Hello world';
    prompt( message => undef );
    is( $TEST_MESSAGE, '', 
        'No message specified: default to empty string.' 
    );
}

# If user just hits enter, use the default.
$TEST_INPUT = EMPTY_STRING;
is( prompt( 'Hello world.', 'Howdy' ),
    'Howdy', 'Positional params return the default.' );

# If user just hits enter, and there's no default, return an empty string.
is( prompt('Hello world.'), EMPTY_STRING,
    'Positional params with no input and no default return an empty string.' );

# Test basic features using named parameters.

# Given a prompt message, a default, and known input, we get back the input.
{
    local $ENV{PERL_MM_USE_DEFAULT} = undef;
    $TEST_INPUT = 'Good day.';
    is( prompt( message => 'Hello world.', default => 'Howdy' ),
        'Good day.', 'Named params return input.' );
}

# Our positional $message parameter passed through to IO::Prompt::Tiny::prompt.
is( $TEST_MESSAGE, 'Hello world.', 'Named params pass the prompt message.' );

# Our positional default parameter passed through to IO::Prompt::Tiny::prompt.
is( $TEST_DEFAULT, 'Howdy', 'Named params pass the default.' );

# If user just hits enter, use the default.
$TEST_INPUT = EMPTY_STRING;
is( prompt( message => 'Hello world.', default => 'Howdy' ),
    'Howdy', 'Named params return the default.' );

# If user just hits enter, and there's no default, return an empty string.
is( prompt( message => 'Hello world.' ),
    EMPTY_STRING,
    'Named params with no input and no default return an empty string.' );

# message, default, tries, validate, error, bad_try, escape.

# Test failed validation.

{
    my $test_tries = 0;
    $TEST_RESULT = 0;
    $TEST_INPUT  = 'Invalid';
    is(
        prompt(
            message  => 'Hello',
            default  => 'world',
            tries    => 50,
            validate => sub { 0 },
            error    => sub { $TEST_RESULT = 1; ++$test_tries; EMPTY_STRING; },
        ),
        undef,
        "Validation rejects bad input."
    );
    is( $TEST_MESSAGE, 'Hello', 'Named parameters pass the message properly.' );
    is( $TEST_DEFAULT, 'world', 'Named parameters pass the default properly.' );
    is( $test_tries > 0, 1,  'error subref called on failed attempts.' );
    is( $test_tries,     50, 'Stopped after proper number of attempts.' );
    is( $TEST_RESULT,    1,  'Error callback invoked.' ); # Test 16.

}

# Test escape mechanism ( Test 17 ).

{
  $TEST_INPUT = "escape";
  local $ENV{PERL_MM_USE_DEFAULT} = 0;
  is(
      prompt(
          message  => 'Hello from Test 17.',
          default  => 'world',
          validate => sub { 1 },
          escape   => sub { $_[0] =~ qr/\bescape\b/ },
      ),
      undef,
      'Escape bypasses validation and returns undef.'
  );
}

undef $TEST_INPUT;
is(
    prompt(
        message  => 'Hello',
        default  => 'world',
        validate => sub { 0 },
        tries    => 2,
        escape   => sub { 0 },
    ),
    undef,
    'Negative RV for escape CB always returns undef.'
);

# Test terminate_input().

{
    $TEST_INPUT = 'Invalid';
    my $test_tries = 0;
    is(
        prompt(
            message  => 'Hello',
            validate => sub { $_[0] =~ m/^valid$/ },
            tries    => 5,
            error    => sub {
                ++$test_tries;
                IO::Prompt::Hooked::terminate_input();
            },
        ),
        undef,
        'Invalid input rejected.'
    );
    is( $test_tries, 1, 'Error may break out of loop.' );
}

# Test tries == 0.

$TEST_INPUT = 'no';
is( 
  prompt( 
    message  => 'hello', 
    validate => qr/^y/, 
    error    => '', 
    tries    => undef,
  ),
  undef,
  "Tries==undef should return undef."
);

# Test no validation, with error set. (should have no impact).

is(
  prompt(
    message  => 'hello',
    error    => undef,
    tries    => 1,
  ),
  'no',
  'No validation, and error response set. (no impact)'
);

# Test hashref params.

$TEST_INPUT = 'yes';
is( prompt( { message => 'hello' } ), 'yes', 'Params may be a hashref.' );

# Test zero tries.

is( prompt( { message => 'hello', validate => qr/^n/i, tries => 0 } ),
    undef, 'Tries==0 no-ops' );

# Test non-interactive.

{
    $TEST_INPUT = 'yes';
    local $ENV{PERL_MM_USE_DEFAULT} = 1;
    is( prompt( message => 'hello', default => 'no' ),
        'no', 'Non-interactive sessions use default.' );
    is(
        prompt(
            message  => 'hello',
            validate => qr/^n/i,
            error    => "# Test error. (shouldn't see)\n",
            tries    => 2
        ),
        undef,
        'Non-printing error branch.'
    );
}

# Test interactive, validated with regex, one try, invalid input.

is(
    prompt(
        message  => 'hello',
        validate => qr/^n/i,
        error    => "# Test error (expected, ok)\n",
        tries    => 1
    ),
    undef,
    'Printing error branch.'
);

{
    no warnings 'redefine';
    local *IO::Prompt::Hooked::_is_interactive = sub { 0 };
    is(
        prompt(
            validate => qr/^n/,
            error    => "Test error (shouldn't see)\n",
            tries    => 1,
        ),
        undef,
        "Shouldn't print when non-interactive (_is_interactive())."
    );
}

{
    local $ENV{PERL_MM_USE_DEFAULT} = 1;
    no warnings 'redefine';
    local *IO::Prompt::Hooked::_is_interactive = sub { 0 };
    is(
    prompt(
      validate => qr /^n/,
      error    => "Test error (shouldn't see)\n",
      tries    => 1,
    ),
    undef,
    "Shouldn't print when non-interactive (_is_interactive & ENV)."
  );
}

{
  local $ENV{PERL_MM_USE_DEFAULT} = 1;
  no warnings 'redefine';
  local *IO::Prompt::Hooked::_is_interactive = sub {1};
  is(
	prompt( 
	  validate => qr/^n/,
	  error    => "Test error (shouldn't see)\n",
	  tries    => 1,
    ),
    undef,
	"PERL_MM_USE_DEFAULT=1, _is_interactive()==true, shouldn't print."
  );
}

{
    local $ENV{PERL_MM_USE_DEFAULT} = 0;
    no warnings 'redefine';
    local *IO::Prompt::Hooked::_is_interactive = sub {1};
    is(
    prompt(
      validate => qr /^n/,
      error    => "# Test error (expected).\n",
      tries    => 1,
    ),
    undef,
    "Generate a printing test error."
  );
}


# Test escape sequence as regex.

undef $TEST_INPUT;
is( prompt( message => 'hello', default => 'a', escape => qr/a/ ),
    undef, 'Regex escape.' );

# Test POD SYNOPSIS code examples.

subtest 'POD synopsis' => sub {

    my $input;

    $TEST_INPUT = 'n';

    # Prompt exactly like IO::Prompt::Tiny
    $input = prompt('Continue? (y/n)');    # No default.
    is( $input, $TEST_INPUT,
        'Prompt exactly like IO::Prompt::Tiny (input given).' );

    $TEST_INPUT = EMPTY_STRING;
    $input = prompt( 'Continue? (y/n)', 'y' );    # Defaults to 'y'.
    is( $input, 'y',
        'Prompt exactly like IO::Prompt::Tiny (default accepted).' );

    $TEST_INPUT = 'y';

    # Prompt with validation.
    $input = prompt(
        message  => 'Continue? (y/n)',
        default  => 'y',
        validate => qr/^[yn]$/i,
        error    => 'Input must be either "y" or "n".',
    );
    is( $input, $TEST_INPUT, 'Input validates.' );

    # Limit number of attempts
    $TEST_INPUT = 'Invalid';
    $input      = prompt(
        message  => 'Continue? (y/n)',
        default  => 'y',
        validate => qr/^[yn]$/i,
        tries    => 5,
        error    => sub {
            my ( $raw, $tries ) = @_;
            return '';
        },
    );
    is( $input, undef, 'Rejected invalid input after 5 tries.' );

    # Validate with a callback.
    $TEST_INPUT = 'y';
    $input      = prompt(
        message  => 'Continue? (y/n)',
        default  => 'y',
        validate => sub {
            my $raw = shift;
            return $raw =~ /^[yn]$/i;
        },
        error => 'Input must be either "y" or "n".',
    );
    is( $input, $TEST_INPUT, 'Callback validated input.' );

    # Give user an escape sequence.
    $TEST_INPUT = 'A';
    $input      = prompt(
        message  => 'Continue? (y/n)',
        default  => 'y',
        escape   => qr/^A$/,
        validate => qr/^[yn]$/i,
        error    => 'Input must be "y" or "n" ("A" to abort input.)',
    );
    is( $input, undef, 'Escape sequence aborted input.' );

    # Break out of allotted attempts early.
    my $test_tries = 0;
    $input = prompt(
        message  => 'Continue? (y/n)',
        default  => 'y',
        validate => qr/^[yn]$/i,
        tries    => 5,
        error    => sub {
            my ( $raw, $tries ) = @_;
            if ( $raw !~ m/^[yn]/ && $tries < 3 ) {
                IO::Prompt::Hooked::terminate_input();
            }
            $test_tries++;
            return '';
        }
    );
    is( $test_tries, 2, 'terminate_input() breaks out of loop early.' );

    done_testing();
};

# Test POD subroutine examples.

subtest 'POD subroutine examples' => sub {

    # prompt "Just like IO::Prompt::Tiny"
    $TEST_INPUT = 'world';
    my $input = prompt('Prompt message');
    is( $input, 'world', 'Basic, single param.' );

    $input = prompt( 'Prompt message', 'Default value' );
    is( $input, 'world', 'Basic, two params, input supplied.' );

    undef $TEST_INPUT;
    $input = prompt( 'Prompt message', 'Default value' );
    is( $input, 'Default value', 'Basic, two params, default used.' );

    # prompt "Or not... (named parameters)"

    undef $TEST_INPUT;
    $input = prompt(
        message  => 'Please enter an integer between 0 and 255 ("A" to abort)',
        default  => '0',
        tries    => 5,
        validate => sub {
            my $raw = shift;
            return $raw =~ /^[0-9]+$/ && $raw >= 0 && $raw <= 255;
        },
        escape => qr/^A$/i,
        error  => sub {
            my ( $raw, $tries ) = @_;
            return "# Invalid input. You have $tries attempts remaining.";
        },
    );
    is( $input, '0', 'named parameters example, got default.' );

    # message

    $TEST_INPUT = "hello";
    $input = prompt( message => 'Enter your first name' );
    is( $input, 'hello', 'message example returned input.' );

    # default

    $input = prompt( message => 'Favorite color', default => 'green' );
    is( $input, 'hello', 'default example returns input.' );
    undef $TEST_INPUT;
    $input = prompt( message => 'Favorite color', default => 'green' );
    is( $input, 'green', 'default example returned default.' );

    # validate

    $TEST_INPUT = 'hello';

    $input = prompt( message => 'Enter a word', validate => qr/^\w+$/ );
    is( $input, 'hello', 'validate example with qr// passes good input.' );

    $input = prompt(
        message  => 'Enter a word',
        validate => sub {
            my ( $raw, $tries_remaining ) = @_;
            return $raw =~ m/^\w+$/;
        }
    );
    is( $input, 'hello', 'validate example with subref passes good input.' );

    $TEST_INPUT = '!@#$%';

    $input =
      prompt( message => 'Enter a word', validate => qr/^\w+$/, tries => 1 );
    is( $input, undef, 'validate example with qr// rejects bad input.' );

    $input = prompt(
        message  => 'Enter a word',
        validate => sub {
            my ( $raw, $tries_remaining ) = @_;
            return $raw =~ m/^\w+$/;
        },
        tries => 1
    );
    is( $input, undef, 'validate example with subref rejects bad input.' );

    # tries

    $TEST_INPUT = 'garbage';

    $input = prompt(
        message  => 'Proceed?',
        default  => 'y',
        validate => qr/^[yn]$/i,
        tries    => 5,
        error    => "# Invalid input.(expected, ok)\n"
    );
    is( $input, undef, 'tries example rejects bad input, and "tries" out.' );

    undef $TEST_INPUT;

    $input = prompt(
        message  => 'Proceed?',
        default  => 'y',
        validate => qr/^[yn]$/i,
        tries    => 5,
        error    => "# Invalid input.(expected, ok)\n"
    );
    is( $input, 'y', 'tries example passes good input.' );

    # error

    $TEST_INPUT = '444';
    $input      = prompt(
        message  => 'Your age?',
        validate => qr/^[01]?[0-9]{1,2}$/,
        tries    => 5,
        error    => sub {
            my ( $raw, $tries ) = @_;
            return 'Roman numerals not allowed'
              if $raw =~ qr/^[IVXLCDM]+$/i;
            return 'Age must be specified in base-10.'
              if $raw =~ qr/^\p{Hex}$/;
            return "# Invalid input.(expected, ok)\n";
        }
    );
    is( $input, undef, 'error example rejects bad input, invoking error cb.' );

    # escape

    $TEST_INPUT = 's';
    $input      = prompt(
        message  => 'True or false? (T, F, or S to skip.)',
        validate => qr/^[tf]$/i,
        error    => "Invalid input.\n",
        escape   => qr/^s$/i
    );
    is( $input, undef, 'escape example short-circuits.' );

    done_testing();
};

done_testing();
