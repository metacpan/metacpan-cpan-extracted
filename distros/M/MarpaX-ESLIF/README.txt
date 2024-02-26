Prologue:

If marpaESLIF version is A.B.C make sure that there is a tag A.B.C.0 if A.B.C interface was never pushed.

The version of marpaESLIFPerl is always A.B.C.D, where:
- A.B.C is the version of marpaESLIF
- D is the version of the perl interface for A.B.C

Once the tag A.B.C.D exist, a release will automatically increase and publish the tag A.B.C.D+1.

Usage:

cmake -S c-marpaESLIFPerl -B c-marpaESLIFPerl-build
cmake --build c-marpaESLIFPerl-build


cmake --build c-marpaESLIFPerl-build --target marpaESLIFPerlTest
cmake --build c-marpaESLIFPerl-build --target marpaESLIFPerlXTest

Because of the way Dist::Zilla works, most of things are done in the source dir anyway, regardless of cmake -B option.

Releases must be preceeded by:

cd c-marpaESLIFPerl
git clean -ffdx
git checkout .
git pull
cd -

An official release is then done using:
cmake -S c-marpaESLIFPerl -B c-marpaESLIFPerl-build
cmake --build c-marpaESLIFPerl-build --target marpaESLIFPerlRelease

A test release is then done using:
cmake -S c-marpaESLIFPerl -B c-marpaESLIFPerl-build
cmake --build c-marpaESLIFPerl-build --target marpaESLIFPerlReleaseTrial
