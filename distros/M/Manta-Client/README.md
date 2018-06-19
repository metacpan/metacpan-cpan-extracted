# Manta::Client

Manta::Client is a Perl module for interacting with Joyent's [Manta](http://https://apidocs.joyent.com/manta/) system.

## Obtaining:
 * https://metacpan.org/release/Manta-Client
 * https://github.com/joyent/Manta-Client

## Requires:
 * Perl 5.10+

## Contributing
Pull requests are welcome.

## Building

Generate a build for distribution using the following commands:
```
$ perl Makefile.PL
$ make manifest
$ make
$ make dist
...
Created Manta-Client-${VERSION}.tar.gz
```

This tarball can be uploaded to [PAUSE](https://pause.perl.org/) to publish a new release on [CPAN](https://www.cpan.org/). Note the warning about unique version numbers on the upload page in PAUSE.

Alternatively a new version may be released by tagging a commit, pushing the tag to Github, and supplying the release tarball URL to PAUSE.

## License
Manta::Client is licensed under the MPLv2. Please see the `LICENSE` file for more details.
