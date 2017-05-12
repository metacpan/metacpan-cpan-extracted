package Locale::MakePhrase::Utils;
our $VERSION = 0.4;
our $DEBUG = 0;
our $DIE_FROM_CALLER = 0;

=head1 NAME

Locale::MakePhrase::Utils - Collection of useful functions

=head1 SYNOPSIS

This module implements some useful functions used within the
L<Locale::MakePhrase> modules.

=head1 FUNCTIONS

The functions we export:

=cut

use strict;
use warnings;
use base qw(Exporter);
use vars qw(@EXPORT_OK);

@EXPORT_OK = qw(
  is_number
  left
  right
  alltrim
  die_from_caller
);

#--------------------------------------------------------------------------

=head2 boolean is_number(value)

Returns true/false indicating if the value is numeric.

=cut

my $is_number_re = qr/^-?(?:\d+(?:\.\d*)?|\.\d+)(?:[Ee]-?\d+)?$/;

sub is_number {
  my $value = shift;
  return 0 if ( !defined $value or !length $value or $value eq "-" );
  return 1 if ( $value =~ $is_number_re );
  return 0;
}

#--------------------------------------------------------------------------

=head2 string left(string,length)

Return the left part of a sub-string.

=cut

sub left {
  return substr($_[0],0,$_[1]);
}

#--------------------------------------------------------------------------

=head2 string right(string,length)

Return the right part of a sub-string.

=cut

sub right {
  return substr($_[0],-$_[1],$_[1]);
}

#--------------------------------------------------------------------------

=head2 string alltrim(string)

Trim all leading and trailing whitespace.

=cut

sub alltrim {
  my $value = shift;
  return undef unless defined $value;
  $value =~ s/^\s*//;
  $value =~ s/\s*$//;
  $value;
}

#--------------------------------------------------------------------------

=head2 void die_from_caller($message)

Throw an exception, from a caller's perspective (ie: not from within
the Locale::MakePhrase modules).  This allows us to generate an error
message for which the user can figure out what they did wrong.

Note: if you set C<Locale::MakePhrase::Utils::DIE_FROM_CALLER> to a
value other than zero, die_from_caller() will recurse that number of
levels further up the stack backtrace, before die()ing.  This allows
you to wrap your $makePhrase-E<gt>translate(...) calls in a global
wrapper function; eg: by setting the value to 1, the message is
displayed with respect to one level up of your applications' calling
code.

=cut

sub die_from_caller {
  if ($DEBUG) {
    require Carp;
    Carp::confess "Locale::MakePhrase detected an error:";
  }
  my $caller_count = 0;
  while (1) {
    $caller_count++;
    my $caller = caller($caller_count);
    last if (!defined $caller || $caller !~ /^Locale::MakePhrase/);
  }
  my ($caller,$file,$line) = caller($caller_count);
  if (defined $caller) {
    for (1..$DIE_FROM_CALLER) {
      $caller_count++;
      ($caller,$file,$line) = caller($caller_count);
      last unless defined $caller;
    }
  }
  $caller = "main" unless defined $caller;
  $file = "(unknown)" unless defined $file;
  $line = "(unknown)" unless defined $line;
  my $msg = "Fatal: ". caller() ." detected an error in: $caller\n";
  $msg .= "File: $file\n";
  $msg .= "Line: $line\n";
  @_ and $msg .= join (" ", @_) . "\n";
  die $msg;
}

1;
__END__
#--------------------------------------------------------------------------

=cut

