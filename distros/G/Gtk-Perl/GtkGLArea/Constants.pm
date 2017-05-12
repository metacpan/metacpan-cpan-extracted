

package Gtk::GLArea::Constants;

require Gtk;

require Exporter;
require AutoLoader;

use Carp;

@ISA = qw(Exporter AutoLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

@EXPORT = qw(
GDK_GL_NONE
GDK_GL_USE_GL
GDK_GL_BUFFER_SIZE
GDK_GL_LEVEL
GDK_GL_RGBA
GDK_GL_DOUBLEBUFFER
GDK_GL_STEREO
GDK_GL_AUX_BUFFERS
GDK_GL_RED_SIZE
GDK_GL_GREEN_SIZE
GDK_GL_BLUE_SIZE
GDK_GL_ALPHA_SIZE
GDK_GL_DEPTH_SIZE
GDK_GL_STENCIL_SIZE
GDK_GL_ACCUM_RED_SIZE
GDK_GL_ACCUM_GREEN_SIZE
GDK_GL_ACCUM_BLUE_SIZE
GDK_GL_ACCUM_ALPHA_SIZE
GDK_GL_X_VISUAL_TYPE_EXT
GDK_GL_TRANSPARENT_TYPE_EXT
GDK_GL_INDEX_VALUE_EXT
GDK_GL_RED_VALUE_EXT
GDK_GL_GREEN_VALUE_EXT
GDK_GL_BLUE_VALUE_EXT
GDK_GL_ALPHA_VALUE_EXT

);

# Other items we are prepared to export if requested
@EXPORT_OK = qw();

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    # NOTE: THIS AUTOLOAD FUNCTION IS FLAWED (but is the best we can do for now).
    # Avoid old-style ``&CONST'' usage. Either remove the ``&'' or add ``()''.
    if (@_ > 0) {
	$AutoLoader::AUTOLOAD = $AUTOLOAD;
	goto &AutoLoader::AUTOLOAD;
    }
    local($constname);
    ($constname = $AUTOLOAD) =~ s/.*:://;
    $val = constant($constname, @_ ? $_[0] : 0);
    if (not defined $val) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    ($pack,$file,$line) = caller;
	    die "Your vendor has not defined GL macro $constname, used at $file line $line.
";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

1;
__END__
