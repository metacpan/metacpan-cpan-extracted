# Contributing

The code for this C library is hosted at
https://github.com/voegelas/shapereader.

Grab the latest version using the command:

    git clone https://github.com/voegelas/shapereader.git

You can submit code changes by forking the repository, pushing your code
changes to your clone, and then submitting a pull request.

Make sure to use only functions from the C standard library.

The library is managed with CMake.  Here are some commands you might try:

    mkdir build
    cd build
    cmake ..
    make
    make test

If clang-format is installed, you can format the source code files:

    make clang-format
