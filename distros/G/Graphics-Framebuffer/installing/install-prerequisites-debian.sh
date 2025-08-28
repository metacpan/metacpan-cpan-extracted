#!/bin/bash

# Install all of the prerequsites for Graphics::Framebuffer

sudo apt update # Bring the Debian module database up to date

# Absolutely needed

sudo apt install -y build-essential \
                    libfreetype-dev \
                    libgif-dev \
                    libjpeg-dev \
                    libpng-dev \
                    libtiff-dev \
					ffmpeg \
					fonts-freefont-ttf \
                    fonts-wine

# Only needed if you are using the OS installed (packaged) Perl
echo "OS prerequisites installed.  It is recommended you answer YES to the next question."

read -p "Do you wish to install the packaged/system Perl module prerequisites?  " yn
case $yn in
    [Yy]* ) 
        sudo apt install -y libimager-perl \
                            libinline-c-perl \
                            libmath-gradient-perl \
                            libmath-bezier-perl \
                            libfile-map-perl \
                            libtest-most-perl \
                            libterm-readkey-perl \
                            libsys-cpu-perl;;
esac
