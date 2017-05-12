package MPE::CIvar;

require 5.005_62;
use strict;
use warnings;

require Exporter;
require DynaLoader;
require Tie::Hash;

our @ISA = qw(Exporter DynaLoader Tie::Hash);

our %CIVAR;

tie %CIVAR, 'MPE::CIvar';



# This allows declaration       use MPE::CIvar ':all';
our %EXPORT_TAGS = ( 'all' => [ qw(
hpcigetvar hpciputvar hpcideletevar
%CIVAR
hpcicommand hpcicmds
findjcw getjcw putjcw setjcw
) ],
'varcalls' => [ qw(hpcigetvar hpciputvar hpcideletevar) ],
'jcwcalls' => [ qw(findjcw getjcw putjcw setjcw) ],
'cmdcalls' => [ qw(hpcicommand hpcicmds) ]);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );
our $VERSION = '1.11';

our $lastcmd;
our $parmnum;
our $cmderr;
our $msglevel = 0;

bootstrap MPE::CIvar $VERSION;

sub hpcicmds {
  $cmderr=0;
  for my $cmd (@_) {
    $lastcmd = $cmd;
    last if hpcicommand($cmd, $cmderr, $parmnum, $msglevel)>0;
  }
  return !$cmderr;
}

sub TIEHASH {
  my $class = shift;
  my $self;
  return bless \$self, $class;
}
sub DELETE {
  my $self = shift;
  my $key  = shift;
  hpcideletevar($key);
}

sub STORE {
  my $self   = shift;
  my $key    = shift;
  my $value  = shift;
  hpciputvar($key, $value);
}

sub FETCH {
  my $self   = shift;
  my $key    = shift;
  return hpcigetvar($key);
}

# thanks to Ted Ashton for this:
sub EXISTS {
  my $self   = shift;
  my $key    = shift;
  return defined(hpcigetvar($key));
}

1;
__END__

=head1 NAME

MPE::CIvar - Perl extension for CI variables and JCWs on MPE/ix

=head1 SYNOPSIS

  use MPE::CIvar ':all';


  $acct = hpcigetvar("HPACCOUNT");

  hpciputvar("TEMPVAR", 1);
  hpciputvar("TEMPVAR", hpcigetvar("TEMPVAR")+1);
  $hold = hpcigetvar("TEMPVAR");
  hpcideletevar("TEMPVAR");
  print "tempvar value was $hold\n";
  setjcw(32768);
  $jcw = getjcw();
  $ci = findjcw("CIERROR");
  putjcw("CIERROR", 0);

  hpcicommand("build TOOOLONGNAME.PUB,invaliddomain", undef, undef, 2);
  if ($CIVAR{HPCIERR}) {
    print "Error message: $CIVAR{HPCIERRMSG}\n";
  }

  hpcicmds("purge larry", 
           "build larry;rec=-80,,f,ascii",
           "file input=larry,old",
           "run darryl.pub")
    or die "Error on cmd: '$MPE::CIvar::lastcmd': $CIVAR{HPCIERRMSG}\n";

  $CIVAR{HPPATH} .= ",PERL.PUB";  # append PERL.PUB to HPPATH

=head1 DESCRIPTION

Access to the MPE/iX intrinsic functions:

     setjcw, getjcw
     putjcw, findjcw
     hpciputvar, hpcigetvar
     hpcideletevar
     hpcicommand

See the MPE/iX documentation at http://docs.hp.com/mpeix/all/
Specifically relevant for this module are:

   MPE/iX Intrinsics Reference Manual
   Command Interpreter Access and Variables Programmer's Guide
   Interprocess Communications Programmer's Guide

You may also access the CI variables through the tied hash, %CIVAR.
This is analogous to %ENV but currently does not support 'each' or
'keys'.

=over

=item setjcw(VALUE)

Sets the jcw JCW to the value VALUE (a 16-bit unsigned integer).  Note
that setting JCW to a value of 32768 or greater indicates that the
program terminated in an error state and may cause a batch job to
terminate.

=item getjcw()

Returns the value of the jcw JCW.

=item putjcw($name, VALUE)

Sets the jcw $name to the value VALUE (a 16-bit unsigned integer).
The function putjcw will return 0 on success, an error code on failure.

=item findjcw($name)

Returns the value of the jcw $name.

=item hpcigetvar($name)

Returns the value of the CI variable $name.  This function will return
'undef' if the variable does not exist.  A boolean variable will be
returned as 0 or 1.

=item hpciputvar($name, VALUE)

Sets the CI variable $name to VALUE.  If VALUE is an integer it will be
put as an integer value.  If not, hpciputvar will try to interpret as a
boolean or just put it as a string.
The function hpciputvar will return 0 on success, an error code on failure.

=item hpcideletevar($name)

Deletes the CI variable $name.  It will return 0 on success,
an error code on failure.

=item %CIVAR

A hash tied to the CI variables.  The follow are equivalent:

   $CIVAR{$name}         hpcigetvar($name)

   $CIVAR{$name}=VALUE   hpciputvar($name, value)

   delete $CIVAR{$name}  hpcideletevar($name)

=item hpcicommand($command [, $cmderr [, $parmnum [,$msglevel]]])

Calls intrinsic C<HPCICOMMAND> with the command string.  The other arguments
are optional.  A value of 0 will be returned on success, otherwise an error
value will be returned and assigned to $cmderr if a variable is passed
as the second argument.  You can set $msglevel to 1 to suppress warnings
and set it to 2 to suppress errors as well as warnings.  For example,

   hpcicommand($command, undef, undef, 2);

=item hpcicmds( @cmdlist )

Calls C<hpcicommand> for each string in C<@cmdlist>.  It will stop
processing the list on an error, but not a warning.  You can set
the C<msglevel> (see above) by assigning to C<$MPE::CIvar::msglevel>
before calling C<hpcicmds>.  You can see the last command 
executed by looking at C<$MPE::CIvar::lastcmd> and any error in
C<$MPE::CIvar::cmderr>.


=back

=head1 EXPORT

None by default.


=head1 AUTHOR

Ken Hirsch E<lt>F<kenhirsch@myself.com>E<gt>

This module may be used and distributed on the same terms as Perl.

=head1 SEE ALSO

perl(1).

=cut
