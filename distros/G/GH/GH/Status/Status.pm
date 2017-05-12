package GH::Status;

require 5.005_62;
use strict;
use warnings;
use Carp;

require Exporter;
require DynaLoader;
use AutoLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use GH::Status ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	STAT_BAD_ARGS
	STAT_BOUND_TOO_TIGHT
	STAT_EOF
	STAT_FAIL
	STAT_NO_MEM
        STAT_NULL_PTR
	STAT_NOT_OPTIMAL
	STAT_OK
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	STAT_BAD_ARGS
	STAT_BOUND_TOO_TIGHT
	STAT_EOF
	STAT_FAIL
	STAT_NO_MEM
        STAT_NULL_PTR
	STAT_NOT_OPTIMAL
	STAT_OK
	statusToString 
);
our $VERSION = '0.01';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/ || $!{EINVAL}) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    croak "Your vendor has not defined GH::Status macro $constname";
	}
    }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
	#if ($] >= 5.00561) {
	#    *$AUTOLOAD = sub () { $val };
	#}
	#else {
	    *$AUTOLOAD = sub { $val };
	#}
    }
    goto &$AUTOLOAD;
}

sub statusToString {
  my($status) = @_;
  my($return) = "";

  if ($status == &STAT_OK) {
    $return = "ok";
  }
  elsif ($status == &STAT_FAIL) {
    $return = "fail";
  }
  elsif ($status == &STAT_EOF) {
    $return = "end of file";
  }
  elsif ($status == &STAT_NULL_PTR) {
    $return = "unexpected null pointer";
  }
  elsif ($status == &STAT_NO_MEM) {
    $return = "unable to allocate requested memory";
  }
  elsif ($status == &STAT_BAD_ARGS) {
    $return = "problem with arguments";
  }
  elsif ($status == &STAT_BOUND_TOO_TIGHT) {
    $return = "bound too tight to give optimal alignment";
  }
  elsif ($status == &STAT_NOT_OPTIMAL) {
    $return = "result not optimal";
  }
  else {
    $return = "unknown status";
  }
  return($return);
}

bootstrap GH::Status $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

GH::Status - Perl extension for blah blah blah

=head1 SYNOPSIS

  # this example (and this man page) may be out of date.  Think twice.

  use GH::Status;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for GH::Status, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.

=head2 Exportable constants

  STAT_BAD_ARGS
  STAT_BOUND_TOO_TIGHT
  STAT_EOF
  STAT_FAIL
  STAT_NO_MEM
  STAT_NULL_PTR
  STAT_OK


=head1 AUTHOR

A. U. Thor, a.u.thor@a.galaxy.far.far.away

=head1 SEE ALSO

perl(1).

=cut
