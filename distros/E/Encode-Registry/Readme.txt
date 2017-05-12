                        Encode::Registry

Encode::Registry is a package to handle multiple encoding transformation
packages. It keeps a registry of where mapping descriptions may be found
and also what type of mapping description they are. An application may
also keep references to particular handlers for particular file types
in the registry. When an application needs to convert some data it can
simply look up the appropriate mapping description in the registry and
use it.

In the case of Encode::Registry and Perl, this can be as simple as something
like:

use Encode::Registry;

while(<>)
{
    print decode(1252, $_);
}

or

perl -MEncode::Registry -ne "print decode(1252,$_);" <infile >outfile

There is no need for the application to have to worry about how the system
handles codepage 1252 or whatever. Although it may be more helpful to use
the OO interface to find out whether the system can handle the said
encoding:

use Encode::Registry;
use Getopt::Std;

getopts('e:');
$opt_e = '1252' unless defined $opt_e;

$enc = find_encoding($opt_e) || die "Can't get encoding $opt_e";

while(<>)
{
    print $enc->decode($_);
}

At the moment the package can handle on a couple of mapping description
types, but this is intended to grow with the advent of Perl 5.8, etc.

For more details, see the POD for Encode::Registry itself.


REGISTERING ENCODINGS

See addencoding


WHY

Why yet another encoding mapping package?

1. I need a way to not worry about which package to use for which mapping
2. I need to support complex mappings
3. I need to be able to access the same mapping descriptions across multiple
   architectures, languages, etc.
4. I think this is a good way to go about it!


INSTALLATION

Installation of this package is in two steps

1. Installing the package

Unpack the tarball into a temporary directory

perl Makefile.PL
make install

Or if on a Win32 system

perl Makefile.PL
pmake install

Alternatively, on a Win32 system you can simply run Setup.bat


COPYRIGHT

This package is published under the terms of the Perl Artistic License.


AUTHOR

martin_hosken@sil.org

