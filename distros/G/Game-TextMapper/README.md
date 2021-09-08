# Text Mapper

This application takes a textual representation of a map and produces
SVG output.

Example input:

```text
0101 empty
0102 mountain
0103 hill "bone hills"
0104 forest
```

[Try it](https://campaignwiki.org/text-mapper).

The app comes with a tutorial built in. See the
[Help](https://campaignwiki.org/text-mapper/help) link.

## Dependencies

Perl Modules (or Debian modules):

* IO::Socket::SSL or libio-socket-ssl-perl
* LWP::UserAgent or liblwp-useragent-perl
* List::MoreUtils or liblist-moreutils-perl
* Modern::Perl or libmodern-perl-perl
* Mojolicious or libmojolicious-perl
* Role::Tiny::With or librole-tiny-perl

The IO::Socket::SSL dependency means that you’ll need OpenSSL
development libraries installed as well: openssl-devel or equivalent,
depending on your package manager.

To install from the working directory (which will also install all the
dependencies) use cpan or cpanm.

Example:

```bash
cpanm .
```

## Installation

Use cpan or cpanm to install Game::TextMapper.

Using `cpan`:

```shell
cpan Game::TextMapper
```

Manual install:

```shell
perl Makefile.PL
make
make install
```

## Configuration

In the directory you want to run it from, you may create a config file
named `text-mapper.conf` like the following:

```perl
{
  # choose error, warn, info, or debug
  loglevel => 'debug',
  # use stderr, alternatively use a filename
  logfile => undef,
  # the URL where the contributions for include statements are
  # e.g. 'https://campaignwiki.org/contrib' (only HTTP and HTTPS
  # schema allowed), or a local directory
  contrib => '/home/alex/src/text-mapper/share',
}
```

## Development

As a developer, morbo makes sure to restart the web app whenever a
file changes:

```bash
morbo --mode development --listen "http://*:3010" script/text-mapper
```

Alternatively:

```bash
script/text-mapper daemon --mode development --listen "http://*:3010"
```

## Docker

If you want to experiment with a clean Perl environment in order to
check whether the dependencies are OK, make sure you have Docker
installed, are part of the docker group, and get the latest-perl
image:

```bash
sudo apt install docker.io
sudo adduser $(whoami) docker
# if groups doesn’t show docker, you need to log in again
su - $(whoami)
# this binds the working directory to /app inside the image
docker run -it --rm -v $(pwd):/app perl:latest /bin/bash
# now we’re root inside the image
cd /app
cpanm File::ShareDir::Install
cpanm .
```
