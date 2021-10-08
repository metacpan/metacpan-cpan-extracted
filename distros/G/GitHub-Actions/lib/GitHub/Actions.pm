package GitHub::Actions;

use Exporter 'import'; # needed to use @EXPORT
use warnings;
use strict;
use Carp;

use v5.14;

# Module implementation here
our %github;
our $EXIT_CODE = 0;

our @EXPORT = qw( %github set_output set_env debug error warning set_failed command_on_file error_on_file warning_on_file start_group end_group);

BEGIN {
  for my $k ( keys(%ENV) ) {
    if ( $k =~ /^GITHUB_/ ) {
      my ($nogithub) = ( $k =~ /^GITHUB_(\w+)/ );
      $github{$nogithub} = $ENV{$k} ;
    }
  }
}

use version; our $VERSION = qv('0.1.1');

sub set_output {
  carp "Need name and value" unless @_;
  my ($output_name, $output_value) = @_;
  $output_value ||='';
  say "::set-output name=$output_name\::$output_value";
}

sub set_env {
  my ($env_var_name, $env_var_value) = @_;
  open(my $fh, '>>', $github{'ENV'}) or die "Could not open file ". $github{'ENV'} ." $!";
  say $fh "$env_var_name=$env_var_value";
  close $fh;
}

sub debug {
  my $debug_message = shift;
  say "::debug::$debug_message";
}

sub error {
  my $error_message = shift;
  $EXIT_CODE = 1;
  say "::error::$error_message"
}

sub warning {
  my $warning = shift;
  say "::warning::$warning"
}

sub error_on_file {
  command_on_file( "::error", @_ );
}

sub warning_on_file {
  command_on_file( "::warning", @_ );
}

sub command_on_file {
  my $command = shift;
  my $message = shift;
  my ($file, $line, $col ) = @_;
  if ( $file ) {
    my @data;
    push( @data, "file=$file");
    push( @data, "line=$line") if $line;
    push( @data, "col=$col") if $col;
    $command .= " ".join(",", @data );
  }
  say $command."::$message"
}

sub start_group {
  say "::group::" . shift;
}

sub end_group {
  say "::endgroup::";
}

sub set_failed {
  error( @_ );
  exit( 1);
}

sub exit_action {
  exit( $EXIT_CODE );
}

"Action!"; # Magic true value required at end of module
__END__

=head1 NAME

GitHub::Actions - Work in GitHub Actions using Perl


=head1 VERSION

This document describes GitHub::Actions version 0.0.3


=head1 SYNOPSIS

    use GitHub::Actions;
    use v5.14;

    # %github contains all GITHUB_* environment variables
    for my $g (keys %github ) {
       say "GITHUB_$g -> ", $github{$g}
    }

    # Set step output
    set_output("FOO", "BAR");

    # Set environment variable value
    set_env("FOO", "BAR");

    # Produces an error and sets exit code to 1
    error( "FOO has happened" )

    # Exits with error if that's the case
    exit_action();

Install this module within a GitHub action

      . name: "Install GitHub::Actions"
        run: sudo cpan GitHub::Actions

(we need C<sudo> since we're using the system Perl)

You can use this as a C<step>

      - name: Test env variables
        shell: perl {0}
        run: |
          use GitHub::Actions;
          set_env( 'FOO', 'BAR');

=head1 DESCRIPTION

GitHub Actions include, by default, at least in its linux runners, a
system Perl which you can use directly in your GitHub actions. This is
a (for the time being) minimalistic module that tries to help a bit
with that, by defining a few functions that will be useful when
performing GitHub actions. Besides the system Perl, you can use any of
L<the modules
installed|https://gist.github.com/JJ/edf3a39d68525439978da2a02763d42b>. You
can install other modules via cpan or, preferably for speed, via the
Ubuntu package (or equivalent)

Check out an example of using it in the L<repository|https://github.com/JJ/perl-GitHub-Actions/blob/main/.github/workflows/self-test.yml>

=head1 INTERFACE 

=head2 set_env( $env_var_name, $env_var_value)

This is equivalent to L<setting an environment variable|https://docs.github.com/en/free-pro-team@latest/actions/reference/workflow-commands-for-github-actions#setting-an-environment-variable>

=head2 set_output( $output_name, $output_value)

Equivalent to L<C<set_output>|https://docs.github.com/en/free-pro-team@latest/actions/reference/workflow-commands-for-github-actions#setting-an-output-parameter>

=head2 debug( $debug_message )

Equivalent to L<C<debug>|https://docs.github.com/en/free-pro-team@latest/actions/reference/workflow-commands-for-github-actions#setting-a-debug-message>

=head2 error( $error_message )

Equivalent to L<C<error>|https://docs.github.com/en/free-pro-team@latest/actions/reference/workflow-commands-for-github-actions#setting-an-error-message>, prints an error message.

=head2 warning( $warning_message )

Equivalent to L<C<warning>|https://docs.github.com/en/actions/reference/workflow-commands-for-github-actions#setting-a-warning-message>, simply prints a warning.

=head2 command_on_file( $error_message, $file, $line, $col )

Common code for L<error_on_file> and L<warning_on_file>. Can be used for any future commands.

=head2 error_on_file( $error_message, $file, $line, $col )

Equivalent to L<C<error>|https://docs.github.com/en/free-pro-team@latest/actions/reference/workflow-commands-for-github-actions#setting-an-error-message>, prints an error message with file and line info

=head2 warning_on_file( $warning_message, $file, $line, $col )

Equivalent to L<C<warning>|https://docs.github.com/en/actions/reference/workflow-commands-for-github-actions#setting-a-warning-message>, prints an warning with file and line info.

=head2 set_failed( $error_message )

Exits with an error status of 1 after setting the error message.

=head2 start_group( $group_name )

Starts a group in the logs, grouping the following messages. Corresponds to
L<C<group>|https://docs.github.com/en/actions/reference/workflow-commands-for-github-actions#grouping-log-lines>.

=head2 end_group

Ends current log grouping.

=head2 exit_action

Exits with the exit code generated during run

=head1 CONFIGURATION AND ENVIRONMENT

GitHub::Actions requires no configuration files or environment
variables. Those set by GitHub Actions will only be available there,
or if you set them explicitly. Remember that they will need to be set
during the C<BEGIN> phase to be available when this module loads.

    BEGIN {
      $ENV{'GITHUB_FOO'} = 'foo';
      $ENV{'GITHUB_BAR'} = 'bar';
    }


=head1 DEPENDENCIES

Intentionally, no dependencies are included.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to L<https://github.com/JJ/perl-GitHub-Actions/issues>.


=head1 AUTHOR

JJ Merelo  C<< <jmerelo@CPAN.org> >>. Many thanks to RENEEB and Gabor Szabo for their help with test and metadata.


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2021, JJ Merelo C<< <jmerelo@CPAN.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
