#!/bin/bash

$PKG = 'yum'

# Install the prerequisites for Graphics::Framebuffer

echo "Newer RedHat distributions have moved from YUM to DNF"
echo "The default is YUM"
read -p "Do you want to use DNF instead?" yn

case $yn in
    [Yy]* )
        $PKG = "dnf"
esac

sudo $PKG update # Bring RedHat's module database up to date

# Absolutely Needed

sudo $PKG install gcc \
                 gcc-c++ \
                 make \
                 autoconf \
                 automake \
                 bison \
                 byacc \
                 flex \
                 patch \
                 ffmpeg \
                 giflib-devel \
                 libjpeg-turbo-devel \
                 libpng-devel \
                 libtiff-devel \
                 freetype-devel

# Only needed if using the Yum installed Perl

echo "Necessary OS prerequisites installed, now to the Perl prerequisites.  It is recommended to answer YES to the following question:"

read -p "Do you wish to install the packaged/system Perl module prerequisites?" yn
case $yn in
    [Yy]* )
        sudo $PKG install perl-math-gradient \
                         perl-math-bezier \
                         perl-file-map \
                         perl-imager \
                         perl-inline-c \
                         perl-sys-cpu \
                         perl-term-readkey \
                         perl-test-most;;
esac
