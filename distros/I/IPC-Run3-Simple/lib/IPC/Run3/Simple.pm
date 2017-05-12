package IPC::Run3::Simple;

# ABSTRACT: Simple utility module to make the easy to use IPC::Run3 even more easy to use.

use strict;
use warnings;

use Carp;
use IPC::Run3 ();
use Exporter 'import';

our $VERSION = '0.011'; # VERSION

our @EXPORT = qw( run3 );

our @EXPORT_OK = qw(

  chomp_err chomp_out croak_on_err default_stderr default_stdin default_stdout
  tee_systemcall

);

our %EXPORT_TAGS = ( 'all' => [ @EXPORT, @EXPORT_OK ] );

our $CHOMP_ERR      = 1;
our $CHOMP_OUT      = 1;
our $CROAK_ON_ERR   = 0;
our $DEFAULT_STDIN  = undef;
our $DEFAULT_STDOUT = \my $out;
our $DEFAULT_STDERR = \my $err;
our $TEE_SYSTEMCALL = 0;

BEGIN {

  # Is Capture::Tiny available?

  if ( eval { require Capture::Tiny } ) {

    Capture::Tiny->import( 'tee' );
    *tee_systemcall = sub { $TEE_SYSTEMCALL = ! ! +shift };

  } else {

    *tee_systemcall = sub { $TEE_SYSTEMCALL = 0 };

  }

  # Is Time::HiRes available?

  if ( eval { require Time::HiRes } ) {

    Time::HiRes->import( qw( gettimeofday tv_interval ) );

  } else {

    *gettimeofday = sub { time, 0 };

    *tv_interval = sub {
      my ( $t0, $t1 ) = @_;
      $t1 = [ gettimeofday() ] unless defined $t1;
      $t1->[ 0 ] - $t0->[ 0 ];
    };

  }
}


# '!! +shift' forces the value to be either undef or 1;

sub chomp_err      { $CHOMP_ERR      = ! ! +shift }
sub chomp_out      { $CHOMP_OUT      = ! ! +shift }
sub croak_on_err   { $CROAK_ON_ERR   = ! ! +shift }
sub default_stderr { $DEFAULT_STDERR = shift }
sub default_stdin  { $DEFAULT_STDIN  = shift }
sub default_stdout { $DEFAULT_STDOUT = shift }


sub run3 {

  my $arg = shift;
  my $ref = ref $arg;

  my $return_array = 0;

  my ( $cmd, $stdin, $stdout, $stderr, $options );

  if ( $ref eq 'ARRAY' ) {

    $return_array++;
    $cmd     = $arg;
    $stdin   = $DEFAULT_STDIN;
    $stdout  = $DEFAULT_STDOUT;
    $stderr  = $DEFAULT_STDERR;
    $options = {};

  } elsif ( $ref eq 'HASH' ) {

    croak "'cmd' required and must be a reference to an array"
      unless exists $arg->{ 'cmd' } && ref $arg->{ 'cmd' } eq 'ARRAY';

    $cmd     = $arg->{ 'cmd' };
    $stdin   = $arg->{ 'stdin' } || $DEFAULT_STDIN;
    $stdout  = $arg->{ 'stdout' } || $DEFAULT_STDOUT;
    $stderr  = $arg->{ 'stderr' } || $DEFAULT_STDERR;
    $options = $arg->{ 'options' } || {};

    chomp_err( $arg->{ 'CHOMP_ERR' } )
      if exists $arg->{ 'CHOMP_ERR' };

    chomp_out( $arg->{ 'CHOMP_OUT' } )
      if exists $arg->{ 'CHOMP_OUT' };

    croak_on_err( $arg->{ 'CROAK_ON_ERR' } )
      if exists $arg->{ 'CROAK_ON_ERR' };

  } else {

    croak "Expecting either an array ref or a hash ref";

  }

  my $t0 = [ gettimeofday() ];

  if ( exists $ENV{ DEBUG_IPCR3S_CALL } ) {

    $stdout = $cmd;

  } elsif ( $TEE_SYSTEMCALL ) {

    # If you run 'perl -M-indirect -c thispackage' you will see a warning
    # about this line.  This shouldn't be a problem because, hopefully,
    # execution will never get here if Capture::Tiny isn't available.

    ( $stdout, $stderr ) = tee { IPC::Run3::run3( $cmd, $stdin, undef, undef, $options ) };

  } else {

    IPC::Run3::run3( $cmd, $stdin, $stdout, $stderr, $options );

  }

  my $time = tv_interval( $t0 );

  my $syserr = $?;

  croak $$stderr
    if $CROAK_ON_ERR && $$stderr ne '';

  if ( ref $stdout eq 'SCALAR' ) {

    $stdout = $$stdout;
    chomp $stdout if $CHOMP_OUT;

  } elsif ( ref $stdout eq 'ARRAY' && $CHOMP_OUT ) {

    chomp @$stdout;

  }

  if ( ref $stderr eq 'SCALAR' ) {

    $stderr = $$stderr;
    chomp $stderr if $CHOMP_OUT;

  } elsif ( ref $stderr eq 'ARRAY' && $CHOMP_OUT ) {

    chomp @$stderr;

  }

  return ( $stdout, $stderr, $syserr, $time )
    if $return_array;

} ## end sub run3

1;


__END__
=pod

=for :stopwords Alan Young

=encoding utf-8

=head1 NAME

IPC::Run3::Simple - Simple utility module to make the easy to use IPC::Run3 even more easy to use.

=head1 VERSION

  This document describes v0.011 of IPC::Run3::Simple - released April 23, 2012 as part of IPC-Run3-Simple.

=head1 SYNOPSIS

 use IPC::Run3::Simple;

 # Dead simple, ignoring system error and getting rid of the final newline in
 # the output.

 my ( $out, $err ) = run3( [qw( ls -AGlh )] ); # syserr and timing is ignored
 die $err if $err;

 # Manipulate $out however you want.

 # Dump file listing into array, then chomp the array, ignoring any errors.

 my $args = {

  'cmd'    => [qw( ls -AGlh )],
  'stdout' => \my @files,

 };

 run3( $args );

 for my $file ( @files ) { print "filename: $file\n" }

=head1 METHODS

=head2 chomp_err

  If a false value is passed, run3 will not chomp any error if it's stored in
  a scalar or array ref. Default is to chomp any error.

=head2 chomp_out

  If a false value is passed, run3 will not chomp the result if it's stored in
  a scalar or array ref. Default is to chomp any result.

=head2 croak_on_err

  If a false value is passed, run3 will return instead of croaking on error.
  Default is to return instead of croaking.

=head2 default_stdin

  Set the default stdin to be used. Default is 'undef' (inherits the parent's
  STDIN filehandle). See L<IPC::Run3> documentation for other options.

=head2 default_stdout

  Set the default stdout to be used. Default is a scalar reference. See
  L<IPC::Run3> documentation for other options.

=head2 default_stderr

  Set the default stderr to be used. Default is a scalar reference. See
  L<IPC::Run3> documentation for other options.

=head2 tee_systemcall

  Turn on or off teeing of system call.  If L<Capture::Tiny> is not installed
  this will be ignored.

=head2 run3

This method is exported into the calling namespace.

Expects either a reference to an array or a reference to a hash.

If a reference to an array is passed it is assumed to be a list of the command
and option(s) to be run. A list containing the results, errors, exit code and
execution time (in that order) will be returned. See SYNOPSIS for an example.

If a reference to a hash is passed in, the following information is expected:

 See IPC::Run3 documentation for possible values for each of these keys.

 'cmd'     Required
 'stdin'   Optional
 'stdout'  Optional
 'stderr'  Optional
 'options' Optional

Note: If any of stdin, stdout or stderr are not passed in the hash 'undef'
will be used in their place.

In addition, the following variables can be set, either in the hash passed in
or globally via $IPC::Run3::Simple::VARIABLE.

 CROAK_ON_ERR If true, run3 will 'croak $stderr' instead of returning if
 $stderr contains anything.  Default is to return instead of croaking.

 CHOMP_OUT If true, run3 will 'chomp $$stdout' if stdout is a scalar reference
 or 'chomp @$stdout' if stdout is an array reference. Otherwise, it has no
 effect. If false, nothing will be done to the output of the call. Default is
 true.

 CHOMP_ERR If true, run3 will 'chomp $$stderr' if stderr is a scalar reference
 or 'chomp @$stderr' if stderr is an array reference. Otherwise, it has no
 effect. If false, nothing will be done to the error output of the call.
 Default is true.

 TEE_SYSTEMCALL This depends on the L<Capture::Tiny> package.  If it is not
 available this option will be silently ignored. If true, run3 will wrap the
 system call in the Capture::Tiny::tee function which will dump the output to
 STDERR and STDOUT as usual while still returning the output to the calling
 function.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AUTHOR

Alan Young <harleypig@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Alan Young.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut

