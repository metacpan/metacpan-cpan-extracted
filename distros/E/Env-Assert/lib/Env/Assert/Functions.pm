## no critic (ControlStructures::ProhibitPostfixControls)
## no critic (ControlStructures::ProhibitCascadingIfElse)
## no critic (ValuesAndExpressions::ProhibitConstantPragma)
package Env::Assert::Functions;
use strict;
use warnings;
use 5.010;

# ABSTRACT: The functionality of Env::Assert and bin/envassert.

our $VERSION = '0.018';

=pod

=encoding utf8

=for :stopwords env filepath filepaths params

=cut

use Exporter 'import';
our @EXPORT_OK = qw(
  assert
  report_errors
  file_to_desc
  ENV_ASSERT_MISSING_FROM_ENVIRONMENT
  ENV_ASSERT_INVALID_CONTENT_IN_VARIABLE
  ENV_ASSERT_MISSING_FROM_DEFINITION
  OPTION_ENV_EXACT
  OPTION_VAR_REGEXP
  OPTION_VAR_REQUIRED
);
our %EXPORT_TAGS = (
    'all' => [
        qw(
          assert
          report_errors
          file_to_desc
          ENV_ASSERT_MISSING_FROM_ENVIRONMENT
          ENV_ASSERT_INVALID_CONTENT_IN_VARIABLE
          ENV_ASSERT_MISSING_FROM_DEFINITION
          OPTION_ENV_EXACT
          OPTION_VAR_REGEXP
          OPTION_VAR_REQUIRED
        )
    ],
    'constants' => [
        qw(
          ENV_ASSERT_MISSING_FROM_ENVIRONMENT
          ENV_ASSERT_INVALID_CONTENT_IN_VARIABLE
          ENV_ASSERT_MISSING_FROM_DEFINITION
          OPTION_ENV_EXACT
          OPTION_VAR_REGEXP
          OPTION_VAR_REQUIRED
        )
    ],
);

use Cwd     qw( abs_path );
use English qw( -no_match_vars );
use File::Spec;
use IO::File;
use English qw( -no_match_vars );    # Avoids regex performance penalty in perl 5.18 and earlier
use Carp;

use constant {
    ENV_ASSERT_MISSING_FROM_ENVIRONMENT    => 1,
    ENV_ASSERT_INVALID_CONTENT_IN_VARIABLE => 2,
    ENV_ASSERT_MISSING_FROM_DEFINITION     => 3,
};

use constant {
    DEFAULT_PARAMETER_BREAK_AT_FIRST_ERROR => 0,
    DEFAULT_REQUIRED                       => 1,
    DEFAULT_REGEXP_ANY                     => q{^.*$},
    INDENT                                 => q{    },
};

use constant {
    OPTION_ENV_EXACT            => q{env:exact},
    OPTION_VAR_REGEXP           => q{var:regexp},
    OPTION_VAR_REQUIRED         => q{var:required},
    DEFAULT_OPTION_ENV_EXACT    => 0,
    DEFAULT_OPTION_VAR_REQUIRED => 1,
};
#
my %ENVASSERT_OPTIONS = map { $_ => 1 } ( OPTION_ENV_EXACT(), OPTION_VAR_REQUIRED() );

=head1 NAME

Env::Assert::Functions - The functionality of Env::Assert and bin/envassert.

=head1 VERSION

version 0.018

=head1 SYNOPSIS

    use Env::Assert::Functions qw( assert report_errors );

    my %want = (
        options => {
            'env:exact' => 1,
        },
        variables => {
            USER => { 'var:regexp' => '^[[:word:]]{1}$', 'var:required' => 1 },
        },
    );
    my %parameters;
    $parameters{'break_at_first_error'} = 1;
    my $r = assert( \%ENV, \%want, \%parameters );
    if( ! $r->{'success'} ) {
        print report_errors( $r->{'errors'} );
    }

=head1 STATUS

Package Env::Assert is currently being developed so changes in the API are possible,
though not likely.

=head1 NOTES

Functionality of L<Env::Assert> has been moved to this package since
version 0.013.
L<Env::Assert> has a different API now.
It can be used by itself at the start of the program, similar to
L<Env::Dot>.

=head1 FUNCTIONS

No functions are automatically exported to the calling namespace.

=head2 assert( \%env, \%want, \%params )

Ensure your environment, parameter I<env> (hashref), matches with
the environment description, parameter I<want> (hashref).
Use parameter I<params> (hashref) to specify processing options.

Supported params:

=over 8

=item break_at_first_error

Verify environment only up until the first error.
Then break and return with only that error.

=back

Return: hashref: { success => 1/0, errors => hashref, };

=cut

sub assert {
    my ( $env, $want, $params ) = @_;
    $params = {} if !$params;
    croak 'Invalid options. Not a hash' if ( ref $env ne 'HASH' || ref $want ne 'HASH' );

    # Set default options
    $params->{'break_at_first_error'} //= DEFAULT_PARAMETER_BREAK_AT_FIRST_ERROR;

    my $success = 1;
    my %errors;
    my $vars = $want->{'variables'} ? $want->{'variables'} : $want->{'vars'};
    my $opts = $want->{'options'}   ? $want->{'options'}   : $want->{'opts'};
    foreach my $var_name ( keys %{$vars} ) {
        my $env_var  = $vars->{$var_name};
        my $required = $env_var->{ OPTION_VAR_REQUIRED() } // DEFAULT_OPTION_VAR_REQUIRED();
        my $regexp   = $env_var->{ OPTION_VAR_REGEXP() }   // DEFAULT_REGEXP_ANY;
        if (    # If var is required we must have it or error
            $required && !defined $env->{$var_name}
        ) {
            $success = 0;
            $errors{'variables'}->{$var_name} = {
                type    => ENV_ASSERT_MISSING_FROM_ENVIRONMENT,
                message => "Variable $var_name is missing from environment",
            };
            goto EXIT if ( $params->{'break_at_first_error'} );
        } elsif (    # if var is not required but it exists, it must match wanted regexp
            defined $env->{$var_name} && $env->{$var_name} !~ m/$regexp/msx
        ) {
            $success = 0;
            $errors{'variables'}->{$var_name} = {
                type    => ENV_ASSERT_INVALID_CONTENT_IN_VARIABLE,
                message => "Variable $var_name has invalid content",
            };
            goto EXIT if ( $params->{'break_at_first_error'} );
        }
    }
    if ( $opts->{ OPTION_ENV_EXACT() } ) {
        foreach my $var_name ( keys %{$env} ) {
            if ( !exists $vars->{$var_name} ) {
                $success = 0;
                $errors{'variables'}->{$var_name} = {
                    type    => ENV_ASSERT_MISSING_FROM_DEFINITION,
                    message => "Variable $var_name is missing from description",
                };
                goto EXIT if ( $params->{'break_at_first_error'} );
            }
        }
    }

  EXIT:
    return { success => $success, errors => \%errors, };
}

=head2 report_errors( \%errors )

Report errors in a nicely formatted way.

=cut

sub report_errors {
    my ($errors) = @_;
    my $out = q{};
    $out .= sprintf "Environment Assert: ERRORS:\n";
    foreach my $error_area_name ( sort keys %{$errors} ) {
        $out .= sprintf "%s%s:\n", INDENT, $error_area_name;
        foreach my $error_key ( sort keys %{ $errors->{$error_area_name} } ) {
            $out .= sprintf "%s%s: %s\n", INDENT . INDENT, $error_key, $errors->{$error_area_name}->{$error_key}->{'message'};
        }
    }
    return $out;
}

=head2 file_to_desc( @rows )

Extract an environment description from a F<.envdesc> file.

=cut

sub file_to_desc {
    my ( $fp, @rows ) = @_;
    my %env_options =
      ( OPTION_ENV_EXACT() => DEFAULT_OPTION_ENV_EXACT(), );    # Options related to reading the file. Applied as they are read.
    my %var_options =
      ( OPTION_VAR_REQUIRED() => DEFAULT_OPTION_VAR_REQUIRED(), )
      ;    # Options related to reading the next variable definition. Reset to defaults after reading.
    my %variables;
    my $prg     = 'envassert';
    my $row_num = 1;
    foreach (@rows) {

        ## no critic (RegularExpressions::ProhibitComplexRegexes)
        if (    # This is envassert meta command
            m{
            ^ [[:space:]]{0,} [#]{2}
            [[:space:]]{1,} $prg [[:space:]]{1,}
            [(] opts: [[:space:]]{0,} (?<opts> .*) [)]
            [[:space:]]{0,} $
            }msx
        ) {
            my $opts = _interpret_opts( $LAST_PAREN_MATCH{opts} );
            foreach my $key ( keys %{$opts} ) {

                # Compatibility issues:
                $key = 'env:' . $key if ( $key eq 'exact' );
                $key = 'var:' . $key if ( $key eq 'required' );
                if ( !exists $ENVASSERT_OPTIONS{$key} ) {
                    my $err = "Unknown $prg option: '$key'";
                    croak _create_error_msg( $err, $row_num, $fp );
                }
            }
            foreach ( keys %{$opts} ) {
                $env_options{$_} = $opts->{$_} if (m/^env/msx);
                $var_options{$_} = $opts->{$_} if (m/^var/msx);
            }
        } elsif (    # This is comment row
            m{ ^ [[:space:]]{0,} [#]{1} .* $ }msx
        ) {
            next;
        } elsif (    # This is empty row
            m{ ^ [[:space:]]{0,} $ }msx
        ) {
            next;
        } elsif (    # This is env var description
            m{ ^ (?<name> [^=]{1,}) = (?<value> .*) $ }msx
        ) {
            $variables{ $LAST_PAREN_MATCH{name} } = {
                OPTION_VAR_REGEXP()   => $LAST_PAREN_MATCH{value},
                OPTION_VAR_REQUIRED() => $var_options{ OPTION_VAR_REQUIRED() },
            };

            # The var:<value> options can only apply to one subsequent var row.
            # We reset the var options back to defaults.
            $var_options{ OPTION_VAR_REQUIRED() } = DEFAULT_OPTION_VAR_REQUIRED();
        }
    } continue {
        $row_num++;
    }

    return opts => \%env_options, vars => \%variables;
}

# Private subroutines

sub _interpret_opts {
    my ($opts_str) = @_;
    my @opts = split qr{
        [[:space:]]{0,} [,] [[:space:]]{0,}
        }msx, $opts_str;
    my %opts;
    foreach (@opts) {
        my ( $key, $val ) = split qr{
        [[:space:]]{0,} [=] [[:space:]]{0,}
        }msx;
        $val        = $val // 1;
        $val        = 1 if ( $val eq 'true'  || $val eq 'True'  || $val eq '1' );
        $val        = 0 if ( $val eq 'false' || $val eq 'False' || $val eq '0' );
        $opts{$key} = $val;
    }
    return \%opts;
}

# create an error message (exception) from the three elements: err, line and filepath.
sub _create_error_msg {
    my ( $err, $line, $filepath ) = @_;
    if ( !$err ) {
        croak 'Parameter error: missing parameter \'err\'';
    }
    if ( !$line && $filepath ) {
        croak 'Parameter error: missing parameter \'line\'';
    }
    return "${err}!" . ( defined $line ? " line ${line}" : q{} ) . ( defined $filepath ? " file '${filepath}'" : q{} );
}

=head1 DEPENDENCIES

No external dependencies outside Perl's standard distribution.

=head1 SEE ALSO

L<Env::Dot> is a "sister" to Env::Assert.
Read environment variables from a F<.env> file directly into you program.
There is also script F<envdot> which can turn F<.env> file's content
into environment variables for different shells.

=head1 AUTHOR

Mikko Koivunalho <mikkoi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Mikko Koivunalho.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
__END__
