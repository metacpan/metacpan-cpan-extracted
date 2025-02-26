# This module is for internal use by other FU modules.
package FU::XS 0.1;
use Carp; # may be called by XS.
use XSLoader;
XSLoader::load('FU');
1;
