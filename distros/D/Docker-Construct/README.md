# docker-construct

A simple tool to reconstruct the filesystem of an exported docker image.
That is, it takes a tarball exported by `docker save`, and recreates the
filesystem with all the layers flattened in a directory.

# USAGE

```sh
# docker-construct acts on exported tarball and extracts into
# a given directory
$ docker save myimage:latest > myimage_latest.tar
$ mkdir myimage/
$ docker-construct myimage_latest.tar myimage/
```

# INSTALLATION

```sh
perl Build.PL
./Build
./Build test
./Build install
```

# LICENSE AND COPYRIGHT

This software is copyright (c) 2020 by Cameron Tauxe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

