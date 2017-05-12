| NOTE TO LCFG AUTHORS: This file documents the build process for end |
| users. If you are looking for instructions describing how to        |
| generate a package from the repository you should read the          |
| information provided at http://www.lcfg.org/doc/buildtools/         |

To build this software you need CMake, version 2.6.0 or newer. If you
do not have CMake installed on your system you can download it from
http://www.cmake.org/ It is also available as a package for pretty
much every flavour of Linux and major Operating System

Building the software on a Unix platform is done in a few easy steps:

1) cmake .
2) make
3) make install

After stage 1 you can use ccmake or cmake-gui to edit various options,
in particular you may wish to alter CMAKE_INSTALL_PREFIX from
/usr/local to something like /opt or /usr if that is more suitable.

If you have an amd64 based Linux system you might put your libraries
into /usr/lib64 rather than /usr/lib (this is true on Redhat-style
systems). In which case you need to alter CMAKE_INSTALL_LIBDIR.

Both these options can be altered on the cmake command line like so:

cmake -DCMAKE_INSTALL_PREFIX:PATH=/usr \
      -DCMAKE_INSTALL_LIBDIR:PATH=/usr/lib64 .

You can also control where the install tree goes by passing the
DESTDIR option through the "make install" stage, e.g.

make install DESTDIR=/tmp/foo

This can be handy when building RPM or Debian packages.

CMake can also handle building and installing software on Windows and
MacOSX. This should work but is not currently officially supported,
please let us know if you have success on those platforms.

