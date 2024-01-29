# NAME

Liveman::Project - maker of the new perl-repository

# SYNOPSIS

```perl
use Liveman::Project;

my $liveman_project = Liveman::Project->new;

ref $liveman_project  # => Liveman::Project
```

# DESCRIPTION

Creates a new perl-repository.

# SUBROUTINES/METHODS

## new (@params)

The constructor.

## make ()

Creates a new project.

## minil_toml ()

Creates a file `minil.toml`.

## cpanfile ()

Creates a cpanfile.

## mkpm ()

Creates a main module.

## license ()

Creates a license.

# AUTHOR

Yaroslav O. Kosmina [darviarush@mail.ru](mailto:darviarush@mail.ru)

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Liveman::Project module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
