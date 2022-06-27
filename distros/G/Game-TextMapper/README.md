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

* File::ShareDir::Install or libfile-sharedir-install-perl
* IO::Socket::SSL or libio-socket-ssl-perl
* LWP::UserAgent or liblwp-useragent-perl
* List::MoreUtils or liblist-moreutils-perl
* Modern::Perl or libmodern-perl-perl
* Mojolicious or libmojolicious-perl
* Role::Tiny::With or librole-tiny-perl

If you are going to build IO::Socket::SSL, then you’ll need OpenSSL
development libraries installed: openssl-devel or equivalent,
depending on your package manager.

To install from the working directory (which will also install all the
dependencies from CPAN unless you installed them beforehand using your
system’s package manager) use cpan or cpanm.

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
  contrib => 'share',
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

## Quickstart

If you don’t know anything about Docker, this is how you set it up.

```bash
# install docker on a Debian system
sudo apt install docker.io
# add the current user to the docker group
sudo adduser $(whoami) docker
# if groups doesn’t show docker, you need to log in again
su - $(whoami)
```

### Running the latest Text Mapper

There is a Dockerfile in the repository. Check out the repository,
change into the working directory, and build a docker image, tagging
it `test/text-mapper`:

```bash
git clone https://alexschroeder.ch/cgit/text-mapper
cd text-mapper
docker build --tag test/text-mapper .
```

If you remove the `--notest` argument in the Dockerfile, this is a
good way to check for missing dependencies. 😁

To run the application on it:

```bash
docker run --publish=3010:3010 test/text-mapper \
  text-mapper daemon --listen "http://*:3010"
```

This runs the web application in the container and has it listen on
`http://127.0.0.1:3010` – and you can access it from the host.

### Troubleshooting

If something goes wrong, list the images you have in order to find its
ID. You might it for the other commands.

```bash
docker images
```

This tells us that the image we’re looking for is 6961f88a0e2b.

```text
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
<none>              <none>              6961f88a0e2b        4 minutes ago       862MB
perl                latest              4307319f1e3e        4 weeks ago         860MB
```

To run a command in the image:

```bash
docker run 6961f88a0e2b ls /app
```

Or interactively:

```bash
docker run --interactive --tty 6961f88a0e2b bash
```

In this example, docker build ended up without a tag. Let’s fix that:

```bash
docker tag 6961f88a0e2b test/text-mapper:latest
```

If your browser refuses to connect to the web application even though
it appears to be running, check the port mapping.

First, let’s find the container ID currently running:

```bash
$ docker ps
```

Note how there are no ports in the output:

```text
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
d76e0cfe79e6        test/text-mapper    "/usr/local/bin/text…"   2 minutes ago       Up 2 minutes                            hungry_lamport
```

The ports on the host are not mapped to the container! We need to stop
the stop container and make sure to run `docker run` with the
`--publish` argument. If we do, this is what the output will look:

```text
CONTAINER ID        IMAGE                     COMMAND                  CREATED             STATUS              PORTS                    NAMES
700606a5e230        test/text-mapper:latest   "text-mapper daemon …"   5 seconds ago       Up 4 seconds        0.0.0.0:3010->3010/tcp   relaxed_fermat
```
