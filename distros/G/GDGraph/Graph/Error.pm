#==========================================================================
#              Copyright (c) 1995-2000 Martien Verbruggen
#--------------------------------------------------------------------------
#
#   Name:
#       GD::Graph::Error.pm
#
# $Id: Error.pm,v 1.8 2005/12/14 04:08:05 ben Exp $
#
#==========================================================================

package GD::Graph::Error;

($GD::Graph::Error::VERSION) = '$Revision: 1.8 $' =~ /\s([\d.]+)/;

use strict;
use Carp;

my %Errors;
use vars qw( $Debug $ErrorLevel $CriticalLevel );

$Debug = 0;

# Warnings from 0 to 4, Errors from 5 to 9, and Critical 10 and above.
$ErrorLevel    = 5;
$CriticalLevel = 10;

=head1 NAME

GD::Graph::Error - Error handling for GD::Graph classes

=head1 SYNOPSIS

use GD::Graph::Error_subclass;

=head1 DESCRIPTION

This class is a parent for all GD::Graph classes, including
GD::Graph::Data, and offers error and warning handling and some
debugging control.

Errors are stored in a lexical hash in this package, so the
implementation of the subclass should be irrelevant. 

=head1 PUBLIC METHODS

These methods can be used by users of any of the subclasses of
GD::Graph::Error to get at the errors of objects or classes.

=head2 $object->error() OR Class->error()

Returns a list of all the errors that the current object has
accumulated. In scalar context, returns the last error. If called as a
class method it works at a class level. This is handy when a constructor
fails, for example:

  my $data = GD::Graph::Data->new()    
      or die GD::Graph::Data->error;
  $data->read(file => '/foo/bar.data') 
      or die $data->error;

or if you really are only interested in the last error:

  $data->read(file => '/foo/bar.data') 
      or die scalar $data->error;

This implementation does not clear the error list, so if you don't die
on errors, you will need to make sure to never ask for anything but the
last error (put this in scalar context) or to call C<clear_error()> now
and again.

Errors are more verbose about where the errors originated if the
$GD::Graph::Error::Debug variable is set to a true value, and even more
verbose if this value is larger than 5.

If $Debug is larger than 3, both of these will always return the
full list of errors and warnings (although the meaning of C<has_warning>
and C<has_error> does not change).

=cut

sub _error
{
    my $self = shift;
    my $min_level = shift || 0;
    my $max_level = shift || 1 << 31;
    return unless exists $Errors{$self};
    my $error = $Errors{$self};

    my @return;

    @return = 
        map { 
            ($Debug > 3 ? "[$_->{level}] " : '') .
            "$_->{msg}" .
            ($Debug ? " at $_->{whence}[1] line $_->{whence}[2]" : '') .
            ($Debug > 5 ? " => $_->{caller}[0]($_->{caller}[2])" : '') .
            "\n"
        } 
        grep { $_->{level} >= $min_level && $_->{level} <= $max_level }
        @$error;

    wantarray && @return > 1 and  
        $return[-1] =~ s/\n/\n\t/ or
        $return[-1] =~ s/\n//;

    return wantarray ? @return : $return[-1];
}

sub error
{
    my $self = shift;
    $Debug > 3 and return $self->_error();
    $self->_error($ErrorLevel);
}

sub warning
{
    my $self = shift;
    $Debug > 3 and return $self->_error();
    $self->_error(0, $ErrorLevel - 1);
}

=head2 $object->has_error() OR Class->has_error()

=head2 $object->has_warning() OR Class->has_warning()

Returns true if there are pending errors (warnings) for the object
(or class). To be more precise, it returns a list of errors in list
context, and the number of errors in scalar context.

This allows you to check for errors and warnings after a large number of
operations which each might fail:

  $data->read(file => '/foo/bar.data') or die $data->error;
  while (my @foo = $sth->fetchrow_array)
  {
      $data->add_point(@foo);
  }
  $data->set_x(12, 'Foo');
  $data->has_warning and warn $data->warning;
  $data->has_error   and die  $data->error;

The reason to call this, instead of just calling C<error()> or
C<warning()> and looking at its return value, is that this method is
much more efficient and fast.

If you want to count anything as bad, just set $ErrorLevel to 0, after
which you only need to call C<has_error>.

=cut

sub has_error
{
    my $self = shift;
    return unless exists $Errors{$self};
    grep { $_->{level} >= $ErrorLevel } @{$Errors{$self}};
}

sub has_warning
{
    my $self = shift;
    return unless exists $Errors{$self};
    grep { $_->{level} < $ErrorLevel } @{$Errors{$self}};
}

=head2 $object->clear_errors() or Class->clear_errors()

Clears all outstanding errors.

=cut

sub clear_errors
{
    my $self = shift;
    delete $Errors{$self};
}

=head1 PROTECTED METHODS

These methods are only to be called from within this class and its
Subclasses.

=head2 $object->_set_error(I<arg>) or Class->_set_error(I<arg>)

=head2 $object->_set_warning(I<arg>) or Class->_set_warning(I<arg>)

Subclasses call this to set an error. The argument can be a reference
to an array, of which the first element should be the error level, and
the second element the error message. Alternatively, it can just be the
message, in which case the error level will be assumed to be
$ErrorLevel.

If the error level is >= $CriticalLevel the program will die, using
Carp::croak to display the current message, as well as all the other
error messages pending.

In the current implementation these are almost identical when called
with a scalar argument, except that the default error level is
different. When called with an array reference, they are identical in
function. This may change in the future. They're mainly here for code
clarity.

=cut

# Private, for construction of error hash. This should probably be an
# object, but that's too much work right now.
sub __error_hash
{
    my $caller  = shift;
    my $default = shift;
    my $msg     = shift;

    my %error = (caller => $caller);

    if (ref($msg) && ref($msg) eq 'ARRAY' && @{$msg} >= 2)
    {
        # Array reference
        $error{level} = $msg->[0];
        $error{msg}   = $msg->[1];
    }
    elsif (ref($_[0]) eq '')
    {
        # simple scalar
        $error{level} = $default;
        $error{msg}   = $msg;
    }
    else
    {
        # something else, which I can't deal with
        warn "Did you read the documentation for GD::Graph::Error?";
        return;
    }

    my $lvl = 1;
    while (my @c = caller($lvl))
    {
        $error{whence} = [@c[0..2]];
        $lvl++;
    }

    return \%error;
}

sub _set_error
{
    my $self = shift;
    return unless @_;

    while (@_)
    {
        my $e_h = __error_hash([caller], $ErrorLevel, shift) or return;
        push @{$Errors{$self}}, $e_h;
        croak $self->error if $e_h->{level} >= $CriticalLevel;
    }
    return;
}

sub _set_warning
{
    my $self = shift;
    return unless @_;

    while (@_)
    {
        my $e_h = __error_hash([caller], $ErrorLevel, shift) or return;
        push @{$Errors{$self}}, $e_h;
        croak $self->error if $e_h->{level} >= $CriticalLevel;
    }
    return;
}

=head2 $object->_move_errors

Move errors from an object into the class it belongs to.  This can be
useful if something nasty happens in the constructor, while
instantiating one of these objects, and you need to move these errors
into the class space before returning. (see GD::Graph::Data::new for an
example)

=cut

sub _move_errors
{
    my $self = shift;
    my $class = ref($self);
    push @{$Errors{$class}}, @{$Errors{$self}};
    return;
}

sub _dump
{
    my $self = shift;
    require Data::Dumper;
    my $dd = Data::Dumper->new([$self], ['me']);
    $dd->Dumpxs;
}

=head1 VARIABLES

=head2 $GD::Graph::Error::Debug

The higher this value, the more verbose error messages will be. At the
moment, any true value will cause the line number and source file of the
caller at the top of the stack to be included, a value of more than 2
will include the error severity, and a value of more than 5 will also
include the direct caller's (i.e. the spot where the error message was
generated) line number and package. Default: 0.

=head2 $GD::Graph::Error::ErrorLevel

Errors levels below this value will be counted as warnings, and error
levels above (and inclusive) up to $CriticalLevel will be counted as
errors. This is also the default error level for the C<_set_error()>
method. This value should be 0 or larger, and smaller than
$CriticalLevel. Default: 5.

=head2 $GD::Graph::Error::CriticalLevel

Any errorlevel of or above this level will immediately cause the program
to die with the specified message, using Carp::croak. Default: 10.

=head1 NOTES

As with all Modules for Perl: Please stick to using the interface. If
you try to fiddle too much with knowledge of the internals of this
module, you could get burned. I may change them at any time.

=head1 AUTHOR

Martien Verbruggen E<lt>mgjv@tradingpost.com.auE<gt>

=head2 Copyright

(c) Martien Verbruggen.

All rights reserved. This package is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<GD::Graph>, L<GD::Graph::Data>

=cut

"Just another true value";
