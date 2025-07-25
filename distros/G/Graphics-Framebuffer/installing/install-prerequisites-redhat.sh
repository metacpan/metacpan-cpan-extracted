#!/bin/bash

# Install the prerequisites for Graphics::Framebuffer

sudo yum update # Bring RedHat's module database up to date

# I use "upgrade" instead of "install" to prevent errors if you already
# have some of these packages installed.  "upgrade" will install them if
# you do not have them.  Win-win

# Absolutely Needed

sudo yum install gcc \
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

read -p "Do you wish to install the packaged/system Perl prerequisites?" yn
case $yn in
    [Yy]* )
        sudo yum install perl-math-gradient \
                         perl-math-bezier \
                         perl-file-map \
                         perl-imager \
                         perl-inline-c \
                         perl-sys-cpu \
                         perl-term-readkey \
                         perl-test-most;;
esac
