# This file converted to perltk using the tcl2perl script and much hand-editing.
#   jc 12/23/01
#


package Graphics::VTK::Tk::vtkImageWindow;

use Tk qw( Ev );

use Graphics::VTK;
use Graphics::VTK::Tk;

use AutoLoader;
use Carp;
use strict;

use base qw(Tk::Widget);

Construct Tk::Widget 'vtkImageWindow';  

bootstrap Graphics::VTK::Tk::vtkImageWindow;

sub Tk_cmd { \&Tk::vtkimagewindow };

	
sub Tk::Widget::ScrlvtkImageWindow { shift->Scrolled('vtkImageWindow' => @_) }

Tk::Methods("render", "Render", "cget", "configure", "vtkImageWindow");

#
#
# Remove from hash %$args any configure-like
# options which only apply at create time (e.g. -iw )
sub CreateArgs
{
  my ($package,$parent,$args) = @_;

  # Call inherited CreateArgs First:
  my @args = $package->SUPER::CreateArgs($parent,$args);
  
  if( defined( $args->{-iw} )){ # -iw defined in args, make sure args array includes it
  	my $value = delete $args->{-iw};
	push @args, '-iw', $value;
  }  
  return @args;
}

1;
__END__
