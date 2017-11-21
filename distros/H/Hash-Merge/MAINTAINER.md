# Maintainers Guide for Hash::Merge

Hash::Merge have common tests being run for several clone backends.
That's why it is a bit more complicated to setup a clone for hacking on the beast.

# Get what you need

At first one need to clone the project and all it's submodules:

  $ git clone https://github.com/perl5-utils/Hash-Merge.git

# Prepare environment for configure stage

Then some modules are required for Makefile.PL at author level itself:

  $ cpanm --with-recommends --with-suggests Test::WriteVariants

# Start working

The typical workflow for authoring modules with ExtUtils::MakeMaker...

  $ cpanm --with-recommends --with-suggests --with-develop --installdeps .
  $ perl Makefile.PL
  $ make manifest
  $ make test

# Submitting contributions

When submitting patches or proposals or ideas or whatever - you realize and
agree the copyright and license conditions. Do not submit anything when you
don't agree on that.

# Copyright and License

This library is free software.  You can redistribute it and/or modify it
under the same terms as Perl itself.
