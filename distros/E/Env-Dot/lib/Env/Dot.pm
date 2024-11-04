## no critic (ValuesAndExpressions::ProhibitConstantPragma)
package Env::Dot;
use strict;
use warnings;

# We define our own import routine because
# this is the point (when `use Env::Dot` is called)
# when we do our magic.

{
    no warnings 'redefine';    ## no critic [TestingAndDebugging::ProhibitNoWarnings]

    sub import {
        load_vars();
        return;
    }
}

use English qw( -no_match_vars );    # Avoids regex performance penalty in perl 5.18 and earlier
use Carp;

# ABSTRACT: Read environment variables from .env file

our $VERSION = '0.017';

use Env::Dot::Functions qw(
  get_dotenv_vars
  interpret_dotenv_filepath_var
  get_envdot_filepaths_var_name
  extract_error_msg
  create_error_msg
);

use constant {
    OPTION_FILE_TYPE         => q{file:type},
    OPTION_FILE_TYPE_PLAIN   => q{plain},
    OPTION_FILE_TYPE_SHELL   => q{shell},
    DEFAULT_OPTION_FILE_TYPE => q{shell},
    DEFAULT_ENVDOT_FILEPATHS => q{.env},
    INDENT                   => q{    },
};

sub load_vars {
    my @dotenv_filepaths;
    if ( exists $ENV{ get_envdot_filepaths_var_name() } ) {
        @dotenv_filepaths = interpret_dotenv_filepath_var( $ENV{ get_envdot_filepaths_var_name() } );
    }
    else {
        if ( -f DEFAULT_ENVDOT_FILEPATHS ) {
            @dotenv_filepaths = (DEFAULT_ENVDOT_FILEPATHS);    # The CLI parameter
        }
    }

    my @vars;
    eval { @vars = get_dotenv_vars(@dotenv_filepaths); 1; } or do {
        my $e = $EVAL_ERROR;
        my ( $err, $l, $fp ) = extract_error_msg($e);
        croak 'Error: ' . $err . ( $l ? qq{ line $l} : q{} ) . ( $fp ? qq{ file '$fp'} : q{} );
    };
    my %new_env;

    # Populate new env with the dotenv variables.
    foreach my $var (@vars) {
        $new_env{ $var->{'name'} } = $var->{'value'};
    }
    foreach my $var_name ( sort keys %ENV ) {
        $new_env{$var_name} = $ENV{$var_name};
    }

    # We need to replace the current %ENV, not change individual values.
    ## no critic [Variables::RequireLocalizedPunctuationVars]
    %ENV = %new_env;
    return \%ENV;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Env::Dot - Read environment variables from .env file

=head1 VERSION

version 0.017

=head1 SYNOPSIS

    use Env::Dot;

    print $ENV{'VAR_DEFINED_IN_DOTENV_FILE'};

=head1 DESCRIPTION

More flexibility in how you manage and use your F<.env> file.

B<Attn. Existing environment variables always take precedence to dotenv variables!>
A dotenv variable (variable from a file) does not overwrite
an existing environment variable. This is by design because
a dotenv file is to augment the environment, not to replace it.

This means that you can override a variable in `.env` file by creating
its counterpart in the environment. For instance:

    unset VAR
    echo "VAR='Good value'" >> .env
    perl -e 'use Env::Dot; print "VAR:$ENV{VAR}\n";'
    # VAR:Good value
    VAR='Better value'; export VAR
    perl -e 'use Env::Dot; print "VAR:$ENV{VAR}\n";'
    # VAR:Better value

=head2 Features

=over 8

=item If no B<.env> file is present, then do nothing

By default, Env::Dot will do nothing if there is no
B<.env> file.
You can also configure Env::Dot to emit an alarm
or break execution, if you want.

=item Specify other dotenv files with path

If your B<.env> file is located in another path,
not the current working directory,
you can use the environment variable
B<ENVDOT_FILEPATHS> to tell where your dotenv file is located.
You can specify several file paths; just separate
them by B<:>. Env::Dot will load the files in the B<reverse order>,
starting from the last. This is the same ordering as used in B<PATH> variable:
the first overrules the following ones, that is, when reading from the last path
to the first path, if same variable is present in more than one file, the later
one replaces the one already read.

Attn. If you are using Windows, separate the paths by <;>!

For example, if you have the following directory structure:

    project-root
    | .env
    + - sub-project
      | .env

and you specify B<ENVDOT_FILEPATHS=project-root/sub-project/.env:project-root/.env>,
then the variables in file B<project-root/.env> will get replaced
by the more specific variables in B<project-root/sub-project/.env>.

In Windows, this would be B<ENVDOT_FILEPATHS=project-root\sub-project\.env;project-root\.env>

N.B. The ordering has changed in version 0.0.9.

=item Support different types of .env files

Unix Shell I<source> command compatible dotenv files use double or single quotation marks
(B<"> or B<'>) to define a variable which has spaces. But, for instance,
Docker compatible F<.env> files do not use quotation marks. The variable's
value begins with B<=> sign and ends with linefeed.

You can specify in the dotenv file itself - by using meta commands -
which type of file it is.

=item Use executable B<envdot> to bring the variables into your shell

The executable is distributed together with Env::Dot package.
It is in the directory I<script>.

The executable I<script/envdot> is not Windows compatible!

A Windows (MS Command and Powershell compatible) version, I<script\envdot.bat>, is possible
in a future release. Please contact the author if you are interested in it.

    eval "$(envdot)"

N.B. If your B<.env> file(s) contain variables which need interpolating,
for example, to combine their value from other variables or execute a command
to produce their value, you have to use the B<envdot> program.
B<Env::Dot> does not do any interpolating. It cannot because that would involve
running the variable in the shell context.

=back

=head2 DotEnv File Meta Commands

The B<var:> commands affect only the subsequent variable definition.
If there is another B<envdot> command, the second overwrites the first
and default values are applied again.

=over 8

=item read:from_parent

By setting this option to B<true>, B<Env::Dot> or B<envdot> command
will search for F<.env> files in the file system tree upwards.
It will load the first F<.env> file it finds from
the current directory upwards to root.

Using B<read:from_parent> will only find and read
one B<.env> file in a parent directory.
If you want to chain the B<.env> files,
they all must set B<read:from_parent> - except the top one.

This functionality can be useful in situations where you have
parallel projects which share common environment variables
in one F<.env> file in a parent directory.

If there is no parent F<.env> file, Env::Dot will break execution
and give an error.

By default this setting is off.

=item read:allow_missing_parent

When using option B<read:from_parent>, if the parent F<.env> file does not exist,
by default Env::Dot will emit an error and break execution.
In some situations, it might be normal that a parent F<.env> file
could be missing. Turn on option B<read:allow_missing_parent> if you
do not want an error in that case.

By default this setting is off.

=item file:type

Changes how B<Env::Dot> reads lines below from this commands. Default is:

    # envdot (file:type=shell)
    VAR="value"

Other possible value of B<file:type> is:

    # envdot (file:type=plain)
    VAR=My var value

=item var:allow_interpolate

By default, when writing variable definitions for the shell,
every variable is treated as static and surrounded with
single quotation marks B<'> in Unix shell which means
shell will read the variable content as is.
By setting this to B<1> or B<true>, you allow shell
to interpolate.
This meta command is only useful when running B<envdot> command
to create variable definitions for B<eval> command to read.

    # envdot (var:allow_interpolate)
    DYNAMIC_VAR="$(pwd)/${ANOTHER_VAR}"

=back

=for stopwords dotenv env envdot

=head1 STATUS

This module is currently being developed so changes in the API are possible,
though not likely.

=head1 DEPENDENCIES

No external dependencies outside Perl's standard distribution.

=head1 FUNCTIONS

No functions exported to the calling namespace.

=head2 load_vars

Load variables from F<.env> file or files in environment variable
B<ENVDOT_FILEPATHS>.

=head1 SEE ALSO

L<Env::Assert> will verify that you certainly have those environmental
variables you need. It also has an executable which can perform the check
in the beginning of a B<docker> container run.

L<Dotenv> and L<ENV::Util|https://metacpan.org/pod/ENV::Util>
are packages which also implement functionality to use
F<.env> files in Perl.

L<Config::ENV> and L<Config::Layered::Source::ENV> provide other means
to configure application with the help of environment variables.

=head1 AUTHOR

Mikko Koivunalho <mikkoi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Mikko Koivunalho.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
