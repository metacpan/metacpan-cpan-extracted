#!/bin/bash

sudo apt update

# Absolutely needed

sudo apt install build-essential \
                 libfreetype6-dev \
                 libgif-dev \
                 libjpeg-dev \
                 libpng-dev \
                 libtiff-dev \
                 libfreetype6-dev \
                 fonts-wine

# Only needed if you are using the OS installed (packaged) Perl
read -p "Do you wish to install the packaged/system Perl prerequisites?" yn
case $yn in
    [Yy]* ) 
        sudo apt install libimager-perl \
                         libinline-c-perl \
                         libmath-gradient-perl \
                         libmath-bezier-perl \
                         libfile-map-perl \
                         libtest-most-perl \
                         libsys-cpu-perl;;
esac

