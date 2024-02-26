use common::sense; use open qw/:std :utf8/;  use Carp qw//; use File::Basename qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  BEGIN {     $SIG{__DIE__} = sub {         my ($s) = @_;         if(ref $s) {             $s->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $s;             die $s;         } else {             die Carp::longmess defined($s)? $s: "undef"         }     };      my $t = File::Slurper::read_text(__FILE__);     my $s =  '/tmp/.liveman/perl-liveman/liveman'    ;     File::Path::rmtree($s) if -e $s;     File::Path::mkpath($s);     chdir $s or die "chdir $s: $!";      while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) {         my ($file, $code) = ($1, $2);         $code =~ s/^#>> //mg;         File::Path::mkpath(File::Basename::dirname($file));         File::Slurper::write_text($file, $code);     }  } # 
# # NAME
# 
# Liveman - компиллятор из markdown в тесты и документацию
# 
# # VERSION
# 
# 3.0
# 
# # SYNOPSIS
# 
# Файл lib/Example.md:
#@> lib/Example.md
#>> Дважды два:
#>> ```perl
#>> 2*2  # -> 2+2
#>> ```
#@< EOF
# 
# Тест:
subtest 'SYNOPSIS' => sub { 
use Liveman;

my $liveman = Liveman->new(prove => 1);

# Компилировать lib/Example.md файл в t/example.t 
# и добавить pod-документацию в lib/Example.pm
$liveman->transform("lib/Example.md");

::is scalar do {$liveman->{count}}, "1", '$liveman->{count}   # => 1';
::is scalar do {-f "t/example.t"}, "1", '-f "t/example.t"    # => 1';
::is scalar do {-f "lib/Example.pm"}, "1", '-f "lib/Example.pm" # => 1';

# Компилировать все lib/**.md файлы со временем модификации, превышающим соответствующие тестовые файлы (t/**.t):
$liveman->transforms;
::is scalar do {$liveman->{count}}, "0", '$liveman->{count}   # => 0';

# Компилировать без проверки времени модификации
::is scalar do {Liveman->new(compile_force => 1)->transforms->{count}}, "1", 'Liveman->new(compile_force => 1)->transforms->{count} # => 1';

# Запустить тесты с yath:
my $yath_return_code = $liveman->tests->{exit_code};

::is scalar do {$yath_return_code}, "0", '$yath_return_code           # => 0';
::is scalar do {-f "cover_db/coverage.html"}, "1", '-f "cover_db/coverage.html" # => 1';

# Ограничить liveman этими файлами для операций, преобразований и тестов (без покрытия):
my $liveman2 = Liveman->new(files => [], force_compile => 1);

# 
# # DESCRIPION
# 
# Проблема современных проектов в том, что документация оторвана от тестирования.
# Это значит, что примеры в документации могут не работать, а сама документация может отставать от кода.
# 
# Liveman компилирует файлы `lib/**.md` в файлы `t/**.t`
# и добавляет документацию в раздел `__END__` модуля к файлам `lib/**.pm`.
# 
# Используйте команду `liveman` для компиляции документации к тестам в каталоге вашего проекта и запускайте тесты:
# 
#     liveman
# 
# Запустите его с покрытием.
# 
# Опция `-o` открывает отчёт о покрытии кода тестами в браузере (файл отчёта покрытия: `cover_db/coverage.html`).
# 
# Liveman заменяет `our $VERSION = "...";` в `lib/**.pm` из `lib/**.md` из секции **VERSION** если она существует.
# 
# Если файл **minil.toml** существует, то Liveman прочитает из него `name` и скопирует файл с этим именем и расширением `.md` в `README.md`.
# 
# Если нужно, чтобы документация в `.md` была написана на одном языке, а `pod` – на другом, то в начале `.md` нужно указать `!from:to` (с какого на какой язык перевести, например, для этого файла: `!ru:en`).
# 
# Заголовки (строки на #) – не переводятся. Так же не переводятя блоки кода.
# А сам перевод осуществляется по абзацам.
# 
# Файлы с переводами складываются в каталог `i18n`, например, `lib/My/Module.md` -> `i18n/My/Module.ru-en.po`. Перевод осуществляется утилитой `trans` (она должна быть установлена в системе). Файлы переводов можно подкорректировать, так как если перевод уже есть в файле, то берётся он.
# 
# **Внимание!** Будьте осторожны и после редактирования `.md` просматривайте `git diff`, чтобы не потерять подкорректированные переводы в `.po`.
# 
# ## TYPES OF TESTS
# 
# Коды секций без указанного языка программирования или с `perl` записываются как код в файл `t/**.t`. А комментарий со стрелкой (# -> )превращается в тест `Test::More`.
# 
# ### `is`
# 
# Сравнить два эквивалентных выражения:
# 
done_testing; }; subtest '`is`' => sub { 
::is scalar do {"hi!"}, scalar do{"hi" . "!"}, '"hi!" # -> "hi" . "!"';
::is scalar do {"hi!"}, scalar do{"hi" . "!"}, '"hi!" # → "hi" . "!"';

# 
# ### `is_deeply`
# 
# Сравнить два выражения для структур:
# 
done_testing; }; subtest '`is_deeply`' => sub { 
::is_deeply scalar do {["hi!"]}, scalar do {["hi" . "!"]}, '["hi!"] # --> ["hi" . "!"]';
::is_deeply scalar do {"hi!"}, scalar do {"hi" . "!"}, '"hi!" # ⟶ "hi" . "!"';

# 
# ### `is` with extrapolate-string
# 
# Сравнить выражение с экстраполированной строкой:
# 
done_testing; }; subtest '`is` with extrapolate-string' => sub { 
my $exclamation = "!";
::is scalar do {"hi!2"}, "hi${exclamation}2", '"hi!2" # => hi${exclamation}2';
::is scalar do {"hi!2"}, "hi${exclamation}2", '"hi!2" # ⇒ hi${exclamation}2';

# 
# ### `is` with nonextrapolate-string
# 
# Сравнить выражение с неэкстраполированной строкой:
# 
done_testing; }; subtest '`is` with nonextrapolate-string' => sub { 
::is scalar do {'hi${exclamation}3'}, 'hi${exclamation}3', '\'hi${exclamation}3\' # \> hi${exclamation}3';
::is scalar do {'hi${exclamation}3'}, 'hi${exclamation}3', '\'hi${exclamation}3\' # ↦ hi${exclamation}3';

# 
# ### `like`
# 
# Проверяет регулярное выражение, включенное в выражение:
# 
done_testing; }; subtest '`like`' => sub { 
::like scalar do {'abbc'}, qr!b+!, '\'abbc\' # ~> b+';
::like scalar do {'abc'}, qr!b+!, '\'abc\'  # ↬ b+';

# 
# ### `unlike`
# 
# Он проверяет регулярное выражение, исключённое из выражения:
# 
done_testing; }; subtest '`unlike`' => sub { 
::unlike scalar do {'ac'}, qr!b+!, '\'ac\' # <~ b+';
::unlike scalar do {'ac'}, qr!b+!, '\'ac\' # ↫ b+';

# 
# ## EMBEDDING FILES
# 
# Каждый тест выполняется во временном каталоге, который удаляется и создается при запуске теста.
# 
# Формат этого каталога: /tmp/.liveman/*project*/*path-to-test*/.
# 
# Раздел кода в строке с префиксом md-файла **File `path`:** запишется в файл при тестировании во время выполнения.
# 
# Раздел кода в префиксной строке md-файла **File `path` is:** будет сравниваться с файлом методом `Test::More::is`.
# 
# Файл experiment/test.txt:
#@> experiment/test.txt
#>> hi!
#@< EOF
# 
# Файл experiment/test.txt является:

{ my $s = 'experiment/test.txt'; open my $__f__, '<:utf8', $s or die "Read $s: $!"; my $n = join '', <$__f__>; close $__f__; ::is $n, 'hi!
', "File $s"; }
# 
# **Внимание!** Пустая строка между префиксом и кодом не допускается!
# 
# Эти префиксы могут быть как на английском, так и на русском.
# 
# # METHODS
# 
# ## new (%param)
# 
# Конструктор. Имеет аргументы:
# 
# 1. `files` (array_ref) — список md-файлов для методов `transforms` и `tests`.
# 1. `open` (boolean) — открыть покрытие в браузере. Если на компьютере установлен браузер **opera**, то будет использоватся команда `opera` для открытия. Иначе — `xdg-open`.
# 1. `force_compile` (boolean) — не проверять время модификации md-файлов.
# 1. `options` — добавить параметры в командной строке для проверки или доказательства.
# 1. `prove` — использовать доказательство (команду `prove` для запуска тестов), а не команду `yath`.
# 
# ## test_path ($md_path)
# 
# Получить путь к `t/**.t`-файлу из пути к `lib/**.md`-файлу:
# 
done_testing; }; subtest 'test_path ($md_path)' => sub { 
::is scalar do {Liveman->new->test_path("lib/PathFix/RestFix.md")}, "t/path-fix/rest-fix.t", 'Liveman->new->test_path("lib/PathFix/RestFix.md") # => t/path-fix/rest-fix.t';

# 
# ## transform ($md_path, [$test_path])
# 
# Компилирует `lib/**.md`-файл в `t/**.t`-файл.
# 
# А так же заменяет **pod**-документацию в секции `__END__` в `lib/**.pm`-файле и создаёт `lib/**.pm`-файл, если тот не существует.
# 
# Файл lib/Example.pm является:

{ my $s = 'lib/Example.pm'; open my $__f__, '<:utf8', $s or die "Read $s: $!"; my $n = join '', <$__f__>; close $__f__; ::is $n, 'package Example;

1;

__END__

=encoding utf-8

Дважды два:

	2*2  # -> 2+2

', "File $s"; }
# 
# Файл `lib/Example.pm` был создан из файла `lib/Example.md`, что описано в разделе `SINOPSIS` в этом документе.
# 
# ## transforms ()
# 
# Компилировать `lib/**.md`-файлы в `t/**.t`-файлы.
# 
# Все, если `$self->{files}` не установлен, или `$self->{files}`.
# 
# ## tests ()
# 
# Запустить тесты (`t/**.t`-файлы).
# 
# Все, если `$self->{files}` не установлен, или `$self->{files}` только.
# 
# # AUTHOR
# 
# Yaroslav O. Kosmina <dart@cpan.org>
# 
# # LICENSE
# 
# ⚖ **GPLv3**
# 
# # COPYRIGHT
# 
# The Liveman module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.

	done_testing;
};

done_testing;
