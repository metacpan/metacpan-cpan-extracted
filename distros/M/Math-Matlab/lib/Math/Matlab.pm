package Math::Matlab;

use strict;
use vars qw($VERSION $Revision);

BEGIN {
	$VERSION = '0.08';
	$Revision = sprintf "%d.%03d", q$Revision: 1.9 $ =~ /: (\d+)\.(\d+)/;
}

##-----  Public Class Methods  -----
sub new { die "Unable to create instance of abstract class " . __PACKAGE__; };

##-----  Public Object Methods  -----
sub execute { die "Abstract method execute() must be overridden." };
sub err_msg {	my $self = shift; return $self->_getset('err_msg',	@_); }
sub clear_err_msg { return $_[0]->{err_msg} = undef; }

sub get_result {
	my $self = shift;

	my ($result) = $self->{'result'} =~ /-----MATLAB-BEGIN-----\n-----SUCCESS\n(.*)/s;
# 	$result =~ s/EDU>> //g;		##Êremove edu prompts
# 	$result =~ s/>> //g;		## remove normal prompts

	return $result;
}

sub fetch_result {
	my $self	= shift;
	my $result	= $self->get_result;
	
	$self->{'result'} = '';

	return $result;
}

sub get_raw_result { return $_[0]->{'result'}; }

sub fetch_raw_result {
	my $self	= shift;
	my $result	= $self->get_raw_result;
	
	$self->{'result'} = '';

	return $result;
}

##-----  Private Object Methods  -----
sub _getset {
	my ($self, $field, $val) = @_;
	$self->{$field} = $val	if defined($val);
	return $self->{$field};
}

1;
__END__

=head1 NAME

Math::Matlab - An abstract base class for a simple Matlab API.

=head1 SYNOPSIS

  If MyMatlab is a sub-class of Math::Matlab ...

  use MyMatlab;
  $matlab = MyMatlab->new( { %args } );
  
  my $code = q/fprintf( 'Hello world!\n' );/
  if ( $matlab->execute($code) ) {
      print $matlab->fetch_result;
  } else {
      print $matlab->err_msg;
  }

=head1 DESCRIPTION

Math::Matlab is an abstract class for a simple interface to Matlab, a
mathematical computation package from The MathWorks (for more info on
Matlab, see http://www.mathworks.com/).

=head1 METHODS

=head2 Public Object Methods

=over 4

=item execute

 $success = $matlab->execute($matlab_code, @args)

An abstract method which executes the Matlab code passed in the first
argument and returns true if successful. The handling of any additional
arguments are determined by the implementing sub-class. The output of
the Matlab code is stored in the object to be retreived by one of the
following 4 methods. The Matlab code must print all output to STDOUT.

=item get_result

 $str = $matlab->get_result
 $str = $matlab->get_result( $str )

Returns the Matlab output after stripping the extra junk.

=item fetch_result

 $str = $matlab->fetch_result
 $str = $matlab->fetch_result( $str )

Returns the Matlab output after stripping the extra junk, then deletes
it from memory.

=item get_raw_result

 $str = $matlab->get_raw_result
 $str = $matlab->get_raw_result( $str )

Returns the Matlab output in raw form. Can be helpful for debugging
errors.

=item fetch_raw_result

 $str = $matlab->fetch_raw_result
 $str = $matlab->fetch_raw_result( $str )

Returns the Matlab output in raw form, then deletes it from memory. Can
be helpful for debugging errors.

=item err_msg

 $str = $matlab->err_msg
 $str = $matlab->err_msg( $str )

Returns the most recent error message. Or sets the message to be
returned.

=back

=head2 Private Object Methods

=over 4

=item _getset

 $value = $object->_getset($field)          ## get a field's value
 $value = $object->_getset($field, $value)  ## set a field's value

A utility method used to get or set a field in the object. 

=back

=head1 COPYRIGHT

Copyright (c) 2002, 2007 PSERC. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

  Ray Zimmerman, <rz10@cornell.edu>

=head1 SEE ALSO

  perl(1), Math::Matlab::Local, Math::Matlab::Remote, Math::Matlab::Server

=cut
