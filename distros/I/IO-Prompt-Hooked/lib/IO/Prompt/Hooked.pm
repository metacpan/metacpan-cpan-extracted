#!/usr/bin/env perl
package IO::Prompt::Hooked;

use 5.006000;
use strict;
use warnings;
use Params::Smart;
use IO::Prompt::Tiny ();

our $VERSION = '0.10';

use parent 'Exporter';

our @EXPORT    = qw( prompt   );
our @EXPORT_OK = qw( terminate_input );

# Steal a subroutine from IO::Prompt::Tiny (Not published in the API)!
*_is_interactive = \&IO::Prompt::Tiny::_is_interactive;

# Template for Params::Smart validation.
my @params = (
    { name => 'message', required => 0, default => '' },
    { name => 'default', required => 0, },
    { name => 'tries',   required => 0, name_only => 1, default => -1 },
    {
        name      => 'validate',
        required  => 0,
        name_only => 1,
        default   => sub { 1 }
    },
    {
        name      => 'error',
        required  => 0,
        name_only => 1,
        default   => sub { q{} }
    },
    {
        name      => 'escape',
        required  => 0,
        name_only => 1,
        default   => sub { 0 }
    },
);

sub prompt {
    my @params = _unpack_prompt_params(@_);
    return _hooked_prompt(@params);
}

sub terminate_input {
    no warnings 'exiting';
    last;

    # Return, here, would be pointless.
}

sub _unpack_prompt_params {
    my @args = ref $_[0] ? %{ shift() } : @_;
    my %args = Params(@params)->args(@args);

    $args{message} = defined $args{message} ? $args{message} : '';
    # 'validate' and 'escape' can be passed a regex object instead of 
    # a subref.
    for my $arg (qw( validate escape )) {
        if ( ref $args{$arg} eq 'Regexp' ) {
            my $regex = $args{$arg};
            $args{$arg} = sub { $_[0] =~ $regex; };
        }
    }

    # Error can be passed a string or a subref.
    if ( ref( $args{error} ) ne 'CODE' ) {
        my $message = $args{error};
        $args{error} = sub { $message };
    }

    # If we're not interactive, make sure there's a tries limit.
    if ( ( $ENV{PERL_MM_USE_DEFAULT} || !_is_interactive() )
        && $args{tries} < 0 )
    {
        $args{tries} = 1;
    }

    return @args{qw( message default tries validate error escape )};
}

sub _hooked_prompt {
    my ( $msg, $default, $tries, $validate_cb, $error_cb, $escape_cb ) = @_;

  # Short-circuit to the default, whatever it is if we start out with $tries==0.
    return $default
      if defined $tries && $tries == 0;

    while ($tries) {

        my $raw = IO::Prompt::Tiny::prompt( $msg, $default );

        $tries--;

        last if $escape_cb->( $raw, $tries );

        return $raw if $validate_cb->( $raw, $tries );

        if ( my $error_msg =
                $error_cb->( $raw, $tries )
            and _is_interactive()
            and !$ENV{PERL_MM_USE_DEFAULT} )
        {
            print $error_msg;
        }
    }

    return;    # If we arrived here, no valid input accepted.
}

1;

__END__

=pod

=head1 NAME

IO::Prompt::Hooked - Simple prompting with validation hooks.

=head1 SYNOPSIS

    use IO::Prompt::Hooked;

    # Prompt exactly like IO::Prompt::Tiny
    $input = prompt( 'Continue? (y/n)' );       # No default.
    $input = prompt( 'Continue? (y/n)', 'y' );  # Defaults to 'y'.

    # Prompt with validation.
    $input = prompt(
      message  => 'Continue? (y/n)',
      default  => 'n',
      validate => qr/^[yn]$/i,
      error    => 'Input must be "y" or "n".',
    );

    # Limit number of attempts
    $input = prompt(
      message  => 'Continue? (y/n)',
      validate => qr/^[yn]$/i,
      tries    => 5,
      error    => sub {
        my( $raw, $tries ) = @_;
        return "'y' or 'n' only. You have $tries attempts remaining.";
      },
    );

    # Validate with a callback.
    $input = prompt(
      message  => 'Continue? (y/n)',
      validate => sub {
        my $raw = shift;
        return $raw =~ /^[yn]$/i;
      },
      error    => 'Input must be either "y" or "n".',
    );

    # Give user an escape sequence.
    $input = prompt(
      message  => 'Continue? (y/n)',
      escape   => qr/^A$/,
      validate => qr/^[yn]$/i,
      error    => 'Input must be "y" or "n" ("A" to abort input.)',
    );

    # Break out of allotted attempts early.
    $input = prompt(
      message  => 'Continue? (y/n)',
      validate => qr/^[yn]$/i,
      tries    => 5,
      error    => sub {
        my( $raw, $tries ) = @_;
        if( $raw !~ m/^[yn]/ && $tries > 3 ) {
          print "You're not reading the instructions!  Input terminated\n";
          IO::Prompt::Hooked::terminate_input(); # Think 'last', but dirtier.
        }
        return "Must enter a single character, 'y' or 'n'";
      },
    );

=head1 DESCRIPTION

IO::Prompt::Tiny is a nice module to use for basic prompting.  It properly
detects interactive sessions, and since it's based on the C<prompt()> routine
from L<ExtUtils::MakeMaker>, it's highly portable.

But L<IO::Prompt::Tiny> is intentionally minimal.  Often one begins wrapping it
in logic to validate input, retry on invalid, limit number of attempts, and
alert the user to invalid input.  L<IO::Prompt::Hooked> adds simple validation,
attempt limiting, and error handling to IO::Prompt::Tiny's minimalism.  It does
this by allowing you to supply simple Regexp objects for validation, or
subroutine callbacks if you need finer control.

"But we already have L<IO::Prompt> for non-trivial needs.", you
might be thinking.  And you're right.  But have you read its POD?  It's far from
being simple, and is not as portable as this module.  L<IO::Prompt::Hooked> aims
to provide the portability of IO::Tiny, and easy to use hooks for input
validation.

=head1 EXPORTS

L<IO::Prompt::Hooked> exports C<prompt()>, and optionally the
C<terminate_input()> helper.

=head1 SUBROUTINES

=head2 C<prompt>

=head3 Just like IO::Prompt::Tiny

    my $input = prompt( 'Prompt message' );
    my $input = prompt( 'Prompt message', 'Default value' );

=head3 Or not... (named parameters)

    my $input = prompt(
      message  => 'Please enter an integer between 0 and 255 ("A" to abort)',
      default  => '0',
      tries    => 5,
      validate => sub {
        my $raw = shift;
        return $raw =~ m/^[0-9]+$/ && $raw >= 0 && $raw <= 255;
      },
      escape   => qr/^A$/i,
      error    => sub {
        my( $raw, $tries ) = @_;
        return "Invalid input. You have $tries attempts remaining.";
      },
    );

=head3 Description of named parameters

Named parameters may be passed as a list of key/value pairs, or as a hash-ref
containing key/value pairs.  C<prompt> is smart enough to figure it out.  Named
parameters shouldn't be mixed with positional parameters though.

Unless otherwise mentioned, all named parameters are optional.

=head4 C<message>

(Optional; empty string used if omitted.)
    
    $input = prompt( message => 'Enter your first name' );

The message that will be displayed to the user ahead of the input cursor.  If
the session is not interactive, or if the C<PERL_MM_USE_DEFAULT> environment
variable is set, output will be suppressed, and the default will be used.  If
there is no default set, an empty string will be returned.

If C<message> is omitted an empty string is used.  This is different from
L<IO::Prompt::Tiny>'s C<prompt>, as that function throws an exception if no
message is passed.

=head4 C<default>

(Optional, but usually preferable.)

    $input = prompt( message => 'Favorite color', default => 'green' );

An optional default value that will be displayed as C<[default]> to the user,
and that will be returned if the user hits enter without providing any input.

Be sure to provide a meaningful default for scripts that might run
non-interactively.

=head4 C<validate>

(Required only if C<error>, or C<tries> are used.)

    $input = prompt( message  => 'Enter a word',
                     validate => qr/^\w+$/      );

    $input = prompt( message  => 'Enter a word',
                     validate => sub {
                       my( $raw, $tries_remaining ) = @_;
                       return $raw =~ m/^\w+$/
    } );

C<validate> accepts either a C<Regexp> object (created via C<qr//>), or a
subroutine reference.  The regexp must match, or the sub must return true for
the input to be accepted.  Any false value will cause input to be rejected, and
the user will be prompted again unless C<tries> has been set, and has run out
(see C<tries>, below).

The sub callback will be invoked as
C<< $valiate_cb->( $raw_input, $tries_remaining ) >>.  Thus, the sub you supply
has access to the raw (chomped) user input, as well as how many tries are
remaining.

=head4 C<tries>

(Optional. Only useful if C<validate> is used.)

    $input = prompt( message  => 'Proceed?',
                     default  => 'y',
                     validate => qr/^[yn]$/i,
                     tries    => 5,
                     error    => 'Invalid input, please try again.' );

Useful only if input is being validated.  By setting a positive number of
attempts, the prompt will continue trying to get valid input either until
valid input is provided, or the counter reaches zero..  If C<tries> is set to
zero, C<prompt> won't prompt, and will return the default if one exists, or
undef otherwise.

If C<tries> hasn't been explicitly set, it implicitly starts out at -1 for the
first attempt, and counts down, -2, -3, etc.  This may be useful to calbacks
that need to monitor how many attempts have been made even when no specific
limit is imposed.


=head4 C<error>

(Optional. Only useful if C<validate> is used.)

    $input = prompt( message  => 'Proceed?',
                     validate => qr/^[yn]$/i,
                     error    => "Invalid input.\n" );

    $input = prompt( message  => 'Your age?',
                     validate => qr/^[01]?[0-9]{1,2}$/,
                     error    => sub {
                       my( $raw, $tries ) = @_;
                       return 'Roman numerals not allowed'
                         if $raw =~ m/^[IVXLCDM]+$/i;
                       return 'Age must be specified in base-10.'
                         if $raw =~ m/[A-Fa-f]/;
                       return 'Invalid input.'
                     } );

The C<error> field accepts a string that will be printed to notify the user
of invalid input, or a subroutine reference that should return a string.  The
sub-ref callback has access to the raw input and number of tries remaining just
like the validate callback.  The purpose of the C<error> field is to generate
a warning message.  But by supplying a subref, it can be abused as you see fit.
The callback will only be invoked if the user input fails to validate.  Output
will be suppressed if the session is interactive, or if the environment variable
C<PERL_MM_USE_DEFAULT> is set.

If C<error> is omitted, and a validation fails, there will be no error message.

=head4 C<escape>

    $input = prompt( message  => 'True or false? (T, F, or S to skip.)',
                     validate => qr/^[tf]$/i,
                     error    => "Invalid input.\n",
                     escape   => qr/^s$/i );

The C<escape> field accepts a regular expression object, or a subroutine
reference to be used as a callback.  If the regex matches, or the callback
returns true, C<prompt()> returns C<undef> immediately.  C<default> will be
ignored.

As with the other callbacks, the escape callback is invoked as
C<< $escape_cb->( $raw, $tries ) >>.  The primary use is to give the user an
escape sequence.  But again, the sub callback opens the doors to much
flexibility.

=head2 C<terminate_input>

Insert a call to C<IO::Prompt::Hooked::terminate_input()> inside of any callback
to force C<prompt()> to return C<undef> immediately.  This is essentially a
means of placing "C<last>" into your callback without generating a warning about
returning from a subroutine via C<last>.  It's a dirty trick, but might be
useful.

=head1 CAVEATS & WARNINGS

Keep in mind that prompting behaves differently in a non-interactive
environment.  In a non-interactive environment, the default will be used.  If
no default is set, C<undef> will be returned.  If the default matches the
C<escape>, undef will be returned.  Next, if default fails to validate, then
C<tries> will count down until zero is reached, at which time C<undef> will be
returned.

If non-interactive mode is detected, and "C<tries>" isn't set to a positive
limit, a C<tries> limit of one is automatically set to prevent endless looping
in cases where validation doesn't match the default.

=head1 CONFIGURATION AND ENVIRONMENT

This module should be highly portable.  The environment variable
C<PERL_MM_USE_DEFAULT> may be set to prevent L<IO::Prompt::Hooked> from
prompting interactively.

This module is expected to work exactly like IO::Prompt::Tiny when invoked in
positional parameter (non-named-parameter) mode except that it uses an empty
string for the prompt message if no prompt message is supplied as a parameter,
rather than throwing an exception.  For regression testing the test suite
validates behavior against the IO::Prompt::Tiny tests.  Overall test coverage
for IO::Prompt::Hooked is 100%.

=head1 DEPENDENCIES

This module has two non-core dependencies: L<Params::Smart>, and
L<IO::Prompt::Tiny>.  The test suite requires L<Capture::Tiny>.

=head1 INCOMPATIBILITIES

No known incompatibilities.

=head1 SEE ALSO

L<IO::Prompt::Tiny>, L<IO::Prompt>

=head1 AUTHOR

David Oswald C<< <davido at cpan dot org> >>

=head1 DIAGNOSTICS

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IO::Prompt::Hooked

This module is maintained in a public repo at Github. You may look for
information at:

=over 4

=item * Github: Development is hosted on Github at:

L<http://www.github.com/daoswald/IO-Prompt-Hooked>

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IO-Prompt-Hooked>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IO-Prompt-Hooked>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IO-Prompt-Hooked>

=item * Search CPAN

L<http://search.cpan.org/dist/IO-Prompt-Hooked/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012 David Oswald.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
