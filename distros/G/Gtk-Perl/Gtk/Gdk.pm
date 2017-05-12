package Gtk::Gdk;

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
# Other items we are prepared to export if requested
@EXPORT_OK = qw(
);

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
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    ($pack,$file,$line) = caller;
	    die "Your vendor has not defined Gtk macro $constname, used at $file line $line.
";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

$Gtk::_init_package = "Gtk::Gdk";

use Gtk;

# Autoload methods go after __END__, and are processed by the autosplit program.

1;
__END__
