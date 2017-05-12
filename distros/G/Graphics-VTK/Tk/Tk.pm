package Graphics::VTK::Tk;



=head1 NAME

Graphics::VTK::Tk  - Tk widgets for Graphics::VTK 

=head1 SYNOPSIS

C<use Graphics::VTK;>
C<use Graphics::VTK::Tk>

=head1 DESCRIPTION

This module provides a perl/tk user interface for 
the Graphics::VTK objects. See the examples directory
in the source distribution for examples of how they are 
used.

=head1 AUTHOR

Roberto De Leo <rdl@math.umd.edu>
John Cerney <j-cerney1@raytheon.com>

=cut

use Graphics::VTK;
use DynaLoader;

@ISA =  qw( DynaLoader ); 
bootstrap Graphics::VTK::Tk;

package Graphics::VTK::XRenderWindowTclInteractor;

use Graphics::VTK;
use strict;
use vars qw($VERSION );

@Graphics::VTK::XRenderWindowTclInteractor::ISA = qw( Graphics::VTK::RenderWindowInteractor );

# Calling Graphics::VTK::RenderWindowInteractor actually creates
#  a VTKXRenderWindowTclInteractor Objects
#  (Problem, This won't allow RenderWindows Objects to be subclassed??)


package Graphics::VTK::RenderWindowInteractor;

sub Graphics::VTK::RenderWindowInteractor::new{

	my $type = shift;
	
	$type = 'Graphics::VTK::XRenderWindowTclInteractor' unless( $^O =~ /win32/i);
	$type = 'Graphics::VTK::Win32RenderWindowInteractor' if( $^O =~ /win32/i);
	# print "In RenderWindowInteractor, type = '$type'\n";

	

	my $self = $type->SUPER::new;

	if( $^O =~ /win32/i){ # win32 seems to need this to exit the non-Tk controlled
		# scripts (like ColorSph.pl as opposed to Decimate.pl) cleanly
		# Set exit 
		$self->SetClassExitMethod( sub{ exit(0)});
	}
	
	return $self;
}



1;


