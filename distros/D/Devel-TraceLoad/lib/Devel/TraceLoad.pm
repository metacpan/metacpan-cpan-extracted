package Devel::TraceLoad;

use warnings;
use strict;
use Carp;
use Devel::TraceLoad::Hook qw( register_require_hook );

=head1 NAME

Devel::TraceLoad - Discover which modules a Perl program loads.

=head1 VERSION

This document describes Devel::TraceLoad version 1.04

=cut

use vars qw( $VERSION );
$VERSION = '1.04';

use constant OUTFILE => 'traceload';

my %opts = (
  after   => 0,    # Display summary after execution
  during  => 0,    # Display loads as they happen
  yaml    => 0,    # Summary is YAML, implies after
  dump    => 0,    # Dump to 'traceload' in the current dir
  summary => 0,    # Display summary of dependencies
  stdout  => 0,    # Output to stdout
);

# Naughty: used by the test suite
sub _option {
  my $name = shift;
  $opts{$name} = shift if @_;
  return $opts{name};
}

sub _is_version {
  my $ver = shift;
  return unless defined $ver;
  return $ver if $ver =~ /^ \d+ (?: [.] \d+ )* $/x;
  return;
}

sub _get_version {
  my $pkg = shift;
  no strict 'refs';
  return _is_version( ${"${pkg}::VERSION"} );
}

sub _get_module {
  my $file = shift;
  return $file if $file =~ m{^/};
  $file =~ s{/}{::}g;
  $file =~ s/[.]pm$//;
  return $file;
}

sub _text_out {
  my ( $fh, $log, $depth ) = @_;
  my $pad = '  ' x $depth;

  for my $info ( @$log ) {
    my @comment = ();

    push @comment,
     defined $info->{version}
     ? "version: $info->{version}"
     : 'no version';

    if ( my $err = $info->{error} ) {
      $err =~ s/\(.*//g;
      $err =~ s/\s+/ /g;
      $err =~ s/\s+$//;
      push @comment, "error: $err";
    }

    print $fh sprintf( "%s%s (%s), line %d: %s%s\n",
      $pad, $info->{file}, $info->{pkg}, $info->{line}, $info->{module},
      ( @comment ? ' (' . join( ', ', @comment ) . ')' : '' ) );
    _text_out( $fh, $info->{nested}, $depth + 1 );
  }
}

sub _gather_deps {
  my ( $by_dep, $log ) = @_;
  for my $info ( @$log ) {
    push @{ $by_dep->{ $info->{module} } }, $info;
    _gather_deps( $by_dep, $info->{nested} );
  }
}

sub _underline {
  my $str = shift;
  return "\n$str\n" . ( '=' x length( $str ) ) . "\n\n";
}

{
  my @load_log    = ();
  my @version_log = ();

  sub import {
    my ( $class, @args ) = @_;

    # Parse args
    for my $arg ( @args ) {
      my $set = ( $arg =~ s/^([+-])(.+)/$2/ ) ? ( $1 eq '+' || 0 ) : 1;
      croak "Unknown option: $arg" unless exists $opts{$arg};
      $opts{$arg} = $set;
    }

    # dump, yaml imply after
    $opts{after} ||= $opts{yaml} || $opts{dump};

    $opts{fh}        = $opts{stdout} ? \*STDOUT : \*STDERR;
    $opts{dump_name} = OUTFILE;
    $opts{enabled}   = 1;

    if ( $opts{yaml} ) {
      eval 'use YAML';
      if ( $@ ) {
        $opts{yaml}  = 0;
        $opts{after} = 0;
        croak "YAML not available";
      }
      $opts{dump_name} .= '.yaml';
    }

    my @stack   = ( \@load_log );
    my $exclude = qr{ [.] (?: al | ix ) $}x;

    # Register callback function
    register_require_hook(
      sub {
        my ( $when, $depth, $arg, $p, $f, $l, $rc, $err ) = @_;

        return unless $opts{enabled};
        return if $arg =~ $exclude;

        # require <version>
        if ( my $ver = _is_version( $arg ) ) {
          if ( $when eq 'before' ) {
            my $info = {
              file    => $f,
              line    => $l,
              pkg     => $p,
              version => $ver,    # Version desired
            };

            push @version_log, $info;
          }
        }
        else {
          if ( $when eq 'before' ) {
            my $module = _get_module( $arg );

            if ( $opts{during} ) {
              my $pad = '  ' x ( $depth - 1 );
              my $fh = $opts{fh};
              print $fh "$pad$f, line $l: $module\n";
            }

            my $info = {
              file   => $f,         # File executing require
              line   => $l,         # Line # of require
              pkg    => $p,         # Package executing require
              module => $module,    # Module being required
              nested => [],         # List of nested requires
            };

            push @{ $stack[-1] }, $info;
            push @stack, $info->{nested};
          }
          elsif ( $when eq 'after' ) {
            pop @stack;
            my $info = $stack[-1][-1];
            $info->{rc} = $rc;
            if ( $err ) {
              $info->{error} = $err;
            }
            else {
              $info->{version} = _get_version( $info->{module} );
            }
          }
        }
      }
    );
  }

  END {
    if ( $opts{after} ) {
      $opts{enabled} = 0;
      my $fh = $opts{fh};
      if ( $opts{dump} ) {
        open $fh, '>', $opts{dump_name}
         or croak "Can't write $opts{dump_name} ($!)";
      }

      if ( $opts{yaml} ) {
        print $fh Dump( \@load_log );
      }
      else {
        print $fh _underline( "Loaded Modules" );
        if ( @load_log ) {
          _text_out( $fh, \@load_log, 0 );
        }
        else {
          print $fh "No modules loaded\n";
        }
      }
    }

    if ( $opts{summary} ) {
      my $fh = $opts{fh};

      # Cross-reference of loaded modules
      print $fh _underline( "Loaded Modules Cross Reference" );

      my %loaded = ();
      _gather_deps( \%loaded, \@load_log );
      if ( %loaded ) {

        my $cmp_info = sub {
          return lc $a->{pkg} cmp lc $b->{pkg}
           || $a->{line} <=> $b->{line};
        };

        for my $module ( sort { lc $a cmp lc $b } keys %loaded ) {
          my $ver = _get_version( $module );
          print $fh $module, defined $ver ? " ($ver)" : '', "\n";

          for my $info ( sort $cmp_info @{ $loaded{$module} } ) {
            print $fh sprintf( "    %s (%s), line %d\n",
              $info->{file}, $info->{pkg}, $info->{line} );
          }
        }
      }
      else {
        print $fh "No modules loaded\n";
      }

      # Required versions
      print $fh _underline( "Required versions" );
      if ( @version_log ) {
        for my $ver ( sort { $b->{version} <=> $a->{version} }
          @version_log ) {
          print $fh sprintf(
            "%12s %s (%s), line %d\n",
            $ver->{version}, $ver->{file},
            $ver->{pkg},     $ver->{line}
          );
        }
      }
      else {
        print $fh "No versions required\n";
      }

    }
  }
}

1;

__END__

=head1 SYNOPSIS

    $ perl -MDevel::TraceLoad=summary my_prog.pl

    Loaded Modules Cross Reference
    ==============================

    base (2.06)
        andy/Spork.pm (Spork), line 7
    Carp (1.03)
        andy/Spork.pm (Spork), line 5
    Config
        /System/Library/Perl/5.8.6/darwin-thread-multi-2level/lib.pm (lib), line 6
    lib (0.5565)
        andy/my_prog.pl (main), line 5
    Spork (0.0.3)
        andy/my_prog.pl (main), line 11
    strict (1.03)
        /System/Library/Perl/5.8.6/darwin-thread-multi-2level/lib.pm (lib), line 8
        andy/my_prog.pl (main), line 3
        andy/Spork.pm (Spork), line 3
    vars (1.01)
        andy/Spork.pm (Spork), line 9
    warnings (1.03)
        andy/my_prog.pl (main), line 4
        andy/Spork.pm (Spork), line 4

    Required versions
    =================

        5.008005 andy/Spork.pm (Spork), line 14
        5.006001 andy/my_prog.pl (main), line 7

=head1 DESCRIPTION

=head1 INTERFACE 

Typically C<Devel::TraceLoad> will be loaded from the command line:

    $ perl -MDevel::TraceLoad=summary my_prog.pl

A number of options are recognised.

=over

=item C<after>

Display a summary of required modules after execution.

=item C<during>

Display requires as they happen.

=item C<yaml>

Write a YAML format summary to traceload.yaml.

=item C<dump>

Dump output to a file called 'traceload' in the current dir.

=item C<summary>

Display summary of dependencies after execution.

=item C<stdout>

Output to STDOUT instead of STDERR.

=back

=head1 CONFIGURATION AND ENVIRONMENT
  
Devel::TraceLoad requires no configuration files or environment variables.

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

Original version by Philippe Verdret C<< <pverdret@dalet.com> >>, from
the basis of an idea of Joshua Pritikin C<< <vishnu@pobox.com> >>.

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
