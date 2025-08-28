#!/bin/bash

# Install the prerequisites for Graphics::Framebuffer

sudo yum update # Bring RedHat's module database up to date

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

echo "Necessary OS prerequisites installed.  It is recommended to answer YES to the following question."

read -p "Do you wish to install the packaged/system Perl module prerequisites?" yn
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
