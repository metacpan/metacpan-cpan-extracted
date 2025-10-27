!ru:en
# NAME

Liveman::MinillaPod2Markdown – заглушка для Minilla, которая перебрасывает lib/MainModule.md в README.md

# SYNOPSIS

```perl
use Liveman::MinillaPod2Markdown;

my $mark = Liveman::MinillaPod2Markdown->new;

$mark->isa("Pod::Markdown")  # -> 1

use File::Slurper qw/write_text/;
write_text "X.md", "hi!";
write_text "X.pm", "our \$VERSION = 1.0;";

$mark->parse_from_file("X.pm");
$mark->{pm_path}  # => X.pm
$mark->{md_path}  # => X.md

$mark->as_markdown  # => hi!
```

# DESCRIPION

Добавьте строку `markdown_maker = "Liveman::MinillaPod2Markdown"` в `minil.toml`, и Minilla не будет создавать `README.md` из pod-документации главного модуля, а возьмёт из одноимённого файла рядом с расширением `*.md`.

# SUBROUTINES

## as_markdown ()

Заглушка.

## new ()

Конструктор.

## parse_from_file ($path)

Заглушка.

## parse_options ($options)

Парсит !options на первой строке:

1. Удаляет ! и языки за ним.
2. Переводит бейджи через запятую в markdown-картинки.

Список бейджей:

1. badges - все бейджи.
2. github-actions - бейдж на тесты гитхаба.
3. metacpan - бейдж на релиз.
4. cover - бейдж на покрытие который создаёт `liveman` при прохождении теста в `doc/badges/total.svg`.

## github_path ()

Путь проекта на github: username/repository.

## read_md ()

Считывает файл с markdown-документацией.

## read_pm ()

Считывает модуль.

## pm_version ()

Версия модуля.

# INSTALL

Чтобы установить этот модуль в вашу систему, выполните следующие действия [командой](https://metacpan.org/pod/App::cpm):

```sh
sudo cpm install -gvv Liveman::MinillaPod2Markdown
```

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Liveman::MinillaPod2Markdown module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
