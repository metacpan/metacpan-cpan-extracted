package Math::Matlab::Engine;

use 5.006;
use strict;
use warnings;
use Carp;

#use PDL;

require Exporter;
require DynaLoader;
use AutoLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Math::Matlab::Engine ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.02';

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
	    croak "Your vendor has not defined Math::Matlab::Engine macro $constname";
	}
    }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
	if ($] >= 5.00561) {
	    *$AUTOLOAD = sub () { $val };
	}
	else {
	    *$AUTOLOAD = sub { $val };
	}
    }
    goto &$AUTOLOAD;
}

bootstrap Math::Matlab::Engine $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Math::Matlab::Engine - Perl extension for using Matlab from within Perl

=head1 SYNOPSIS

  use Math::Matlab::Engine;

  $ep = Math::Matlab::Engine->new();

  $ep->PutMatrix('N',2,3,[1,2,3,4,5,6]);

  $n = $ep->GetGetMatrix('N');

  $ep->EvalString("plot(N)");

=head1 DESCRIPTION

This module is a wrapper around the C library matlab.h.

=head2 CLASS METHODS

  $ep = Math::Matlab::Engine->new();

     creates a new Math::Matlab::Engine object

=head2 OBJECT METHODS

  $ep->PutMatrix($name, $rows, $columns, $dataref);

This methods hands a matrix with $column columns and $rows rows
to Matlab with the name $name.
The data is specified by the arrayref $dataref.

 EXAMPLE: $ep->PutMatrix('N',3,2,[0,8,15,2,3,9]);
writes the matrix "N=[0,8,15;2,3,9]" into matlab's namespace.

  $n = $ep->GetMatrix($name);

This method retrieves the matlab object $name if it represents 
a two-dimensional matrix, undef otherwise.

  $ep->EvalString($string);

This methods sends an arbitrary string expression to matlab for 
evaluation, 
 EXAMPLE: $ep->EvalString("[T,Y]=ode23t('func',[0 100],[1,1,1,1])");

  $ep->PutArray($name, $dimlistref, $dataref);

This methods hands a multidimensional array to Matlab with the name $name.
The dimensions are defined by the arrayref $dimlistref, the data is specified
by the arrayref $dataref.

If $p is a pdl object, one can write "$ep->PutArray($name,[$p->dims],[$p->list]);";

  $n = $ep->GetArray($name);

This method retrieves the matlab object $name as a multidimensional arrayref.



=head2 EXPORT

None by default.

=head2 BUGS

PutArray whirls around the dimensions. I did not find an elegant solution to this problem.
For 2-d arrays, use the Matrix methods.

=head2 TODO

The -Array methods have to be corrected to correctly reflect the numbering
of the dimensions

=head1 AUTHOR

O. Ebenhoeh, E<lt>oliver.ebenhoeh@rz.hu-berlin.deE<gt>

=head1 SEE ALSO

L<perl>.

=cut

# WARNING!!!!!!!!
# this does only work with arrays of dimension <= 2.
# I don't know why!!!! It is very mysterious.
# use the two steps seperately, then it works. I.e., say:
# $x = $ep->GetArray
# $p = pdl $x

#sub GetPDL {
#  my ($engine,$name) = @_;

#  my $mat = $engine->GetArray($name);
##  print "matrix returned to GetPDL!!!\n";
#  my $pdl = pdl $mat;
#  return $pdl;
##  return pdl $engine->GetArray($name);
#}

#sub PutPDL {
#  my ($engine,$name,$pdl) = @_;

#  my @dims = $pdl->dims;
#  print "dims:".join(",",@dims)."\n";
#  my @list = $pdl->list;
#  print "list:".join(",",@list)."\n";
##  return $engine->PutArray($name,[$pdl->dims],[$pdl->list]);
#  return $engine->PutArray($name,\@dims,\@list);
#}
