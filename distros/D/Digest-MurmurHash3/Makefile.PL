use inc::Module::Install;
use Config;

all_from 'lib/Digest/MurmurHash3.pm';

tests "t/*.t";
use_xshelper();
cc_src_paths "src";

# Oh all ye C++ wizards, pray tell me, what is the portable way to
# specify that I'd like to use C++ files from with my XS modules?
cc_append_to_ccflags '-x c++';
cc_libs '-lstdc++';

if ( $Config{use64bitint} ) {
    makemaker_args DEFINE => "-DHAVE_64BITINT";
}

WriteAll;