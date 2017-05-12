use Test;
BEGIN { plan tests => 1 };

# This is a completely inadequate test quite, that simply uses all the
# modules, to at least check that they compile

use Microarray::CdtDataset;
use Microarray::Config;
use Microarray::DataMatrix::AnySizeDataMatrix;
use Microarray::DataMatrix::BigDataMatrix;
use Microarray::DataMatrix::CdtFile;
use Microarray::DataMatrix::PclFile;
use Microarray::DataMatrix::SmallDataMatrix;
use Microarray::DataMatrix::TabDelimitedDataMatrix;
use Microarray::DataMatrix;
use Microarray::DatasetImageMaker;
use Microarray::Explorer;
use Microarray::Utilities::Filesystem;

ok(1); # If we made it this far, we're ok.

#########################

