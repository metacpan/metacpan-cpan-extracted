# Project Name - HTTP-API-Client #

API Client

# SETUP #
--------------------------------------------------------------
## Setup your system with Docker and Vagrant ##

### Install Docker ###

p.s. If you already have docker, skip to next.

 >> sudo wget -q0- https://get.docker.com|sh
 >> sudo adduser $USER docker
 >> echo "export VAGRANT_DEFAULT_PROVIDER=docker" >> $HOME/.bashrc;
 >> export VAGRANT_DEFAULT_PROVIDER=docker
 >> sudo reboot
 
### Install Vagrant ###

p.s. If you already have vagrant, or use docker composer then skip to next.

Download the latest version from https://www.vagrantup.com/downloads.html

 >> sudo apt-get gdebi -y
 >> wget https://dl.bintray.com/mitchellh/vagrant/vagrant_1.7.2_x86_64.deb -cO vagrant.deb
 >> sudo gdebi vagrant.deb --no

### Add ./bin and ./tools to PATH ###

p.s. If you have already done that, skip this one. do not over done.

 >> echo "export PATH=bin:tools:$PATH" >> ~/.bashrc

=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-===-=

## Runing and Testing ##

### Add dependancies and install locally ###

 >> echo 'requires "IO::File";' >> cpanfile
 >> carton install

### Run your code ###

 >> carton exec prove -lr t

### Get inside the container as normal user ###

 >> container inside

### Get inside the container as root ###

 >> container inside-root

## Finally, you coding structure is ready. Take care ##

ps. get a list of command of container commands

 >> container help

-=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-===-=

# Developers #

 * Michael Vu <email@michael.vu>

# License #

None
