!ru:en
# NAME

Liveman::Cpanfile - анализатор зависимостей Perl проекта

# SYNOPSIS

```perl
use Liveman::Cpanfile;

chmod 0755, $_ for qw!script/test_script bin/tool!;

$::cpanfile = Liveman::Cpanfile->new;
$::cpanfile->cpanfile # -> << 'END'
requires 'perl', '5.22.0';

on 'develop' => sub {
	requires 'App::cpm';
	requires 'CPAN::Uploader';
	requires 'Data::Printer', '1.000004';
	requires 'Minilla', 'v3.1.19';
	requires 'Liveman', '1.0';
	requires 'Software::License::GPL_3';
	requires 'V';
	requires 'Version::Next';
};

on 'test' => sub {
	requires 'Car::Auto';
	requires 'Carp';
	requires 'Cwd';
	requires 'Data::Dumper';
	requires 'File::Basename';
	requires 'File::Find';
	requires 'File::Path';
	requires 'File::Slurper';
	requires 'File::Spec';
	requires 'Scalar::Util';
	requires 'String::Diff';
	requires 'Term::ANSIColor';
	requires 'Test::More';
	requires 'Turbin';
	requires 'open';
};

requires 'Data::Printer';
requires 'List::Util';
requires 'common::sense';
requires 'strict';
requires 'warnings';
END
```

# DESCRIPTION

`Liveman::Cpanfile` анализирует структуру Perl проекта и извлекает информацию о зависимостях из исходного кода, тестов и документации. Модуль автоматически определяет используемые модули и помогает поддерживать актуальный `cpanfile`.

# SUBROUTINES

## new ()

Конструктор.

## pkg_from_path ()

Преобразует путь к файлу в имя пакета Perl.

```perl
Liveman::Cpanfile::pkg_from_path('lib/My/Module.pm') # => My::Module
Liveman::Cpanfile::pkg_from_path('lib/My/App.pm')    # => My::App
```

## sc ()

Возвращает список исполняемых скриптов в директориях `script/` и `bin/`.

Файл script/test_script:
```perl
#!/usr/bin/env perl
require Data::Printer;
```

Файл bin/tool:
```perl
#!/usr/bin/env perl
use List::Util;
```

```perl
[$::cpanfile->sc] # --> [qw!bin/tool script/test_script!]
```

## pm ()

Возвращает список Perl модулей в директории `lib/`.

Файл lib/My/Module.pm:
```perl
package My::Module;
use strict;
use warnings;
1;
```

Файл lib/My/Other.pm:
```perl
package My::Other;
use common::sense;
1;
```

```perl
[$::cpanfile->pm]  # --> [qw!lib/My/Module.pm lib/My/Other.pm!]
```

## mod ()

Возвращает список имен пакетов проекта соответствующих модулям в директории `lib/`.

```perl
[$::cpanfile->mod]  # --> [qw/My::Module My::Other/]
```

## md ()

Возвращает список Markdown файлов документации (`*.md`) в `lib/`.

Файл lib/My/Module.md:
```md
# My::Module

This is a module for experiment with package My::Module.
\```perl
package My {}
package My::Third {}
use My::Other;
use My;
use Turbin;
use Car::Auto;
\```
```

```perl
[$::cpanfile->md]  # --> [qw!lib/My/Module.md!]
```

## md_mod ()

Список внедрённых в `*.md` пакетов.

```perl
[$::cpanfile->md_mod]  # --> [qw!My My::Third!]
```

## deps ()

Список зависимостей явно указанных в скриптах и модулях без пакетов проекта.

```perl
[$::cpanfile->deps]  # --> [qw!Data::Printer List::Util common::sense strict warnings!]
```

## t_deps ()

Список зависимостей из тестов за исключением:

1. Зависмостей скриптов и модулей.
2. Пакетов проекта.
3. Внедрённых в `*.md` пакетов.

```perl
[$::cpanfile->t_deps]  # --> [qw!Car::Auto Carp Cwd Data::Dumper File::Basename File::Find File::Path File::Slurper File::Spec Scalar::Util String::Diff Term::ANSIColor Test::More Turbin open!]
```

## cpanfile ()

Возвращает текст cpanfile c зависимостями для проекта.

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Liveman::Cpanfile module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.
