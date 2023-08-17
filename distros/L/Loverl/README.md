# SYNOPSIS

    loverl [options]
        Options:
            new [New Project Name]
            build
            help
            version

## Options

new - Initializes a new LÖVE2D project directory.

run - Runs the LÖVE2D project through the Love application.

build - Builds the LÖVE2D project into a build directory

help - Displays a help message on how to use Loverl.

version - Displays Loverl's version number.

# DESCRIPTION

Loverl is a LÖVE2D game development command-line interface.

# Setup

Loverl uses Perl version 5.36 or later.

## Installation

### Using cpanm

    cpanm Loverl

### Using the Project Directory

    cpanm --installdeps .
    perl Makefile.PL
    make
    make install

## Git

[Git](https://git-scm.com/) should already be installed.

## LÖVE2D

[LÖVE2D](https://love2d.org/) should already be installed.

### love PATH on Linux

The LINUX\_LOVE\_PATH environment variable should be set inorder to utilize the run command.
