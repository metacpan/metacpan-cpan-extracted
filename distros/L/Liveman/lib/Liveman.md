!ru:en,badges
# NAME

Liveman - компиллятор из markdown в тесты и документацию

# VERSION

3.3

# SYNOPSIS

Файл lib/Example.md:
```markdown
Twice two:
\```perl
2*2  # -> 2+2
\```
```

Тест:
```perl
use Liveman;

my $liveman = Liveman->new(prove => 1);

$liveman->transform("lib/Example.md");

$liveman->{count}   # => 1
-f "t/example.t"    # => 1
-f "lib/Example.pm" # => 1

$liveman->transforms;
$liveman->{count}   # => 0

Liveman->new(compile_force => 1)->transforms->{count} # => 1

my $prove_return_code = $liveman->tests->{exit_code};

$prove_return_code           # => 0
-f "cover_db/coverage.html" # => 1
```

# DESCRIPION

Проблема современных проектов в том, что документация оторвана от тестирования.
Это значит, что примеры в документации могут не работать, а сама документация может отставать от кода.

Liveman компилирует файлы `lib/**.md` в файлы `t/**.t`
и добавляет документацию в раздел `__END__` модуля к файлам `lib/**.pm`.

Используйте команду `liveman` для компиляции документации к тестам в каталоге вашего проекта и запускайте тесты:

    liveman

Запустите его с покрытием.

Опция `-o` открывает отчёт о покрытии кода тестами в браузере (файл отчёта покрытия: `cover_db/coverage.html`).

Liveman заменяет `our $VERSION = "...";` в `lib/**.pm` из `lib/**.md` из секции **VERSION** если она существует.

Если файл **minil.toml** существует, то Liveman прочитает из него `name` и скопирует файл с этим именем и расширением `.md` в `README.md`.

Если нужно, чтобы документация в `.md` была написана на одном языке, а `pod` – на другом, то в начале `.md` нужно указать `!from:to` (с какого на какой язык перевести, например, для этого файла: `!ru:en`).

Заголовки (строки на #) – не переводятся. Так же не переводятя блоки кода.
А сам перевод осуществляется по абзацам.

Файлы с переводами складываются в каталог `i18n`, например, `lib/My/Module.md` -> `i18n/My/Module.ru-en.po`. Перевод осуществляется утилитой `trans` (она должна быть установлена в системе). Файлы переводов можно подкорректировать, так как если перевод уже есть в файле, то берётся он.

**Внимание!** Будьте осторожны и после редактирования `.md` просматривайте `git diff`, чтобы не потерять подкорректированные переводы в `.po`.

**Примечание:** `trans -R` покажет список языков, которые можно указывать в **!from:to** на первой строке документа.

## TYPES OF TESTS

Коды секций без указанного языка программирования или с `perl` записываются как код в файл `t/**.t`. А комментарий со стрелкой (# -> )превращается в тест `Test::More`.

### `is`

Сравнить два эквивалентных выражения:

```perl
"hi!" # -> "hi" . "!"
"hi!" # → "hi" . "!"
```

### `is_deeply`

Сравнить два выражения для структур:

```perl
["hi!"] # --> ["hi" . "!"]
"hi!" # ⟶ "hi" . "!"
```

### `is` with extrapolate-string

Сравнить выражение с экстраполированной строкой:

```perl
my $exclamation = "!";
"hi!2" # => hi${exclamation}2
"hi!2" # ⇒ hi${exclamation}2
```

### `is` with nonextrapolate-string

Сравнить выражение с неэкстраполированной строкой:

```perl
'hi${exclamation}3' # \> hi${exclamation}3
'hi${exclamation}3' # ↦ hi${exclamation}3
```

### `like`

Скаляр должен быть сопостовим с регулярным выражением:

```perl
'abbc' # ~> b+
'abc'  # ↬ b+
```

### `unlike`

В скаляре не должно быть совпадения с регулярным выражением:

```perl
'ac' # <~ b+
'ac' # ↫ b+
```

### `like` begins with extrapolate-string

Скаляр должен начинаться экстраполированой срокой:

```perl
my $var = 'b';

'abbc' # ^=> a$var
'abc'  # ⤇ a$var
```

### `like` ends with extrapolate-string

Скаляр должен заканчиваться экстраполированой срокой:

```perl
my $var = 'c';

'abbc' # $=> b$var
'abc'  # ➾ b$var
```

### `like` inners with extrapolate-string

Скаляр должен содержать экстраполированую сроку:

```perl
my $var = 'x';

'abxc'  # *=> b$var
'abxs'  # ⥴ b$var
```

### `like` begins with nonextrapolate-string

Скаляр должен начинаться неэкстраполированой срокой:

```perl
'abbc' # ^-> ab
'abc'  # ↣ ab
```

### `like` ends with nonextrapolate-string

Скаляр должен заканчиваться неэкстраполированой срокой:

```perl
'abbc' # $-> bc
'abc'  # ⇥ bc
```

### `like` inners with nonextrapolate-string

Скаляр должен содержать неэкстраполированую сроку:

```perl
'abbc' # *-> bb
'abc'  # ⥵ b
```

### `like` throw begins with nonextrapolate-string

Исключение должно начинаться с неэкстраполированой сроки:

```perl
1/0 # @-> Illegal division by zero
1/0 # ↯ Illegal division by zero
```

### `like` throw begins with extrapolate-string

Исключение должно начинаться с экстраполированой сроки:

```perl
my $by = 'by';

1/0 # @=> Illegal division $by zero
1/0 # ⤯ Illegal division $by zero
```

### `like` throw

Исключение должно быть сопостовимо с регулярным выражением:

```perl
1/0 # @~> division\s*by\s*zero
1/0 # ⇝ division\s*by\s*zero
```

### `unlike` throw

Исключение не должно быть сопостовимо с регулярным выражением:

```perl
1/0 # <~@ auto
1/0 # ⇜ auto
```

## EMBEDDING FILES

Каждый тест выполняется во временном каталоге, который удаляется и создается при запуске теста.

Формат этого каталога: /tmp/.liveman/*project*/*path-to-test*/.

Раздел кода в строке с префиксом md-файла **File `path`:** запишется в файл при тестировании во время выполнения.

Раздел кода в префиксной строке md-файла **File `path` is:** будет сравниваться с файлом методом `Test::More::is`.

Файл experiment/test.txt:
```text
hi!
```

Файл experiment/test.txt является:
```text
hi!
```

**Внимание!** Пустая строка между префиксом и кодом не допускается!

Эти префиксы могут быть как на английском, так и на русском (`File [path](https://metacpan.org/pod/path):` и `File [path](https://metacpan.org/pod/path) is:`).

# METHODS

## new (%param)

Конструктор. Имеет аргументы:

1. `files` (array_ref) — список md-файлов для методов `transforms` и `tests`.
1. `open` (boolean) — открыть покрытие в браузере. Если на компьютере установлен браузер **opera**, то будет использоватся команда `opera` для открытия. Иначе — `xdg-open`.
1. `force_compile` (boolean) — не проверять время модификации md-файлов.
1. `options` — добавить параметры в командной строке для проверки или доказательства.
1. `prove` — использовать доказательство (команду `prove` для запуска тестов), а не команду `yath`.

## test_path ($md_path)

Получить путь к `t/**.t`-файлу из пути к `lib/**.md`-файлу:

```perl
Liveman->new->test_path("lib/PathFix/RestFix.md") # => t/path-fix/rest-fix.t
```

## transform ($md_path, [$test_path])

Компилирует `lib/**.md`-файл в `t/**.t`-файл.

А так же заменяет **pod**-документацию в секции `__END__` в `lib/**.pm`-файле и создаёт `lib/**.pm`-файл, если тот не существует.

Файл lib/Example.pm является:
```perl
package Example;

1;

__END__

=encoding utf-8

Twice two:

	2*2  # -> 2+2

```

Файл `lib/Example.pm` был создан из файла `lib/Example.md`, что описано в разделе `SINOPSIS` в этом документе.

## transforms ()

Компилировать `lib/**.md`-файлы в `t/**.t`-файлы.

Все, если `$self->{files}` не установлен, или `$self->{files}`.

## tests ()

Запустить тесты (`t/**.t`-файлы).

Все, если `$self->{files}` не установлен, или `$self->{files}` только.

## load_po ($md, $from, $to)

Считывает po-файл.

## save_po ()

Сохраняет po-файл.

## trans ($text, $lineno)

Функция переводит текст с одного языка на другой используя утилиту trans.

## trans_paragraph ($paragraph, $lineno)

Так же разбивает по параграфам.

# DEPENDENCIES IN CPANFILE

В своей библиотеке, которую вы будете тестировать Liveman-ом, нужно будет указать дополнительные зависимости для тестов в **cpanfile**:

```cpanfile
on 'test' => sub {
    requires 'Test::More', '0.98';

    requires 'Carp';
    requires 'File::Basename';
    requires 'File::Path';
    requires 'File::Slurper';
    requires 'File::Spec';
    requires 'Scalar::Util';
};
```

Так же неплохо будет указать и сам **Liveman** в разделе для разработки:

```cpanfile
on 'develop' => sub {
    requires 'Minilla', 'v3.1.19';
    requires 'Data::Printer', '1.000004';
    requires 'Liveman', '1.0';
};
```

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Liveman module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
