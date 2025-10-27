!ru:en
# NAME

Liveman::Project - создать новый Perl-репозиторий

# SYNOPSIS

```perl
use Liveman::Project;

my $liveman_project = Liveman::Project->new;

ref $liveman_project  # => Liveman::Project
```

# DESCRIPTION

Создает новый Perl-репозиторий.

# SUBROUTINES/METHODS

## new (@params)

Конструктор.

## make ()

Создаёт новый проект.

## minil_toml ()

Создаёт файл `minil.toml`.

## cpanfile ()

Создаёт `cpanfile`.

## mkpm ()

Создает главный модуль.

## license ()

Создаёт лицензию.

## warnings ()

Проверяет проект на ошибки и распечатывает их в STDOUT.

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Liveman::Project module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
