package Devel::TraceLoad::Hook;

use strict;
use warnings;

=head1 NAME

Devel::TraceLoad::Hook - Install a hook function to be called for each require.

=head1 VERSION

This document describes Devel::TraceLoad::Hook version 1.04

=head1 SYNOPSIS

    register_require_hook( sub {
        my ( $when, $depth, $arg, $p, $f, $l, $rc, $err ) = @_;
        # ... do stuff ...
    } ); 

=head1 DESCRIPTION

Allows hook functions that will be called before and after each
C<require> (and C<use>) to be registered.

=head1 INTERFACE 

=cut

use base qw(Exporter);
use vars qw/$VERSION @EXPORT_OK/;

@EXPORT_OK = qw( register_require_hook );
$VERSION   = '1.04';

my @hooks;

{
  my $installed = 0;

  sub _install_hook {
    return if $installed;
    my $depth = 0;
    no warnings 'redefine';
    *CORE::GLOBAL::require = sub {

      my ( $p, $f, $l ) = caller;
      my $arg = @_ ? $_[0] : $_;
      my $rc;

      $depth++;

      # If a 'before' hook throws an error we'll still call the
      # 'after' hooks - to keep everything in balance.
      eval { _call_hooks( 'before', $depth, $arg, $p, $f, $l ) };

      # Only call require if the 'before' hooks succeeded.
      $rc = eval { CORE::require $arg } unless $@;

      # Save the error for later
      my $err = $@;

      # Call the 'after' hooks whatever happened.
      {
        local $@;    # Things break if we trample on $@
        eval {
          _call_hooks( 'after', $depth, $arg, $p, $f, $l, $rc, $err );
        };
        if ( my $err = $@ ) {
          $err =~ s/\s+/ /g;
          warn "Unexpected error $err in require hook\n";
        }
      }

      $depth--;

      if ( $err ) {

       # TODO: We don't seem to get the expected line number fix up here
        $err =~ s/at \s+ .*? \s+ line \s+ \d+/at $f line $l/x;
        die $err;
      }
      return $rc;
    };
    $installed++;
  }
}

sub import {
  my $pkg = shift;
  _install_hook();
  local $Exporter::ExportLevel += 1;
  return $pkg->SUPER::import( @_ );
}

sub _call_hooks {
  my @errs = ();

  for my $hook ( @hooks ) {
    eval { $hook->( @_ ) };
    push @errs, $@ if $@;
  }

  # Rethrow after calling all the hooks. We assume that usually only
  # one hook will fail and that we'll be rethrowing that error here -
  # but we concatenate all the errors so that when multiple hooks fail
  # someone gets to see the diagnostic.

  die join( ', ', @errs ) if @errs;
}

=head2 C<< register_require_hook >>

Register a function to be called immediately before and after each
C<require> (and C<use>).

The registered function should look something like this:

    sub done_require {
        my ( $when, $depth, $arg, $p, $f, $l, $rc, $err ) = @_;
        # ... do stuff ...
    }
    
The arguments are as follows:

=over

=item C<$when>

The hook function is called both before and after the require is
executed. The first argument will contain either 'before' or 'after' as
appropriate.

=item C<$depth>

How deeply nested this require is.

=item C<$arg>

The argument to C<require>.

=item C<$p>, C<$f>, C<$l>

The package, file and line where the calling C<require> or C<use> is.

=item C<$rc>, C<$err>

When the hook function is called after a C<require> C<$rc> and
C<$err> will contain the return value of the require and any error
that it raised.

=back

You may throw an error (using C<die>) from the hook function. If an
error is thrown during 'before' processing the real call to C<require>
will not take place. In this way it is possible to simulate a module
being unavailable.

See L<Devel::TraceLoad> for a complete example of this interface.

=cut

sub register_require_hook { push @hooks, @_ }

1;

__END__

=head1 CONFIGURATION AND ENVIRONMENT
  
Devel::TraceLoad::Hook requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<< YAML >> is required for yaml output.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to 
C<bug-devel-traceload>@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Andy Armstrong C<< <andy@hexten.net> >>.

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
