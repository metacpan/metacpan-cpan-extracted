use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  use String::Diff qw//; use Data::Dumper qw//; use Term::ANSIColor qw//;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-1]); 	my $project_name = $dirs[$#dirs-1]; 	my @test_dirs = @dirs[$#dirs-1+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} }  my $white = Term::ANSIColor::color('BRIGHT_WHITE'); my $red = Term::ANSIColor::color('BRIGHT_RED'); my $green = Term::ANSIColor::color('BRIGHT_GREEN'); my $reset = Term::ANSIColor::color('RESET'); my @diff = ( 	remove_open => "$white\[$red", 	remove_close => "$white]$reset", 	append_open => "$white\{$green", 	append_close => "$white}$reset", );  sub _string_diff { 	my ($got, $expected, $chunk) = @_; 	$got = substr($got, 0, length $expected) if $chunk == 1; 	$got = substr($got, -length $expected) if $chunk == -1; 	String::Diff::diff_merge($got, $expected, @diff) }  sub _struct_diff { 	my ($got, $expected) = @_; 	String::Diff::diff_merge( 		Data::Dumper->new([$got], ['diff'])->Indent(0)->Useqq(1)->Dump, 		Data::Dumper->new([$expected], ['diff'])->Indent(0)->Useqq(1)->Dump, 		@diff 	) }  # 
# # NAME
# 
# Liveman - компиллятор из markdown в тесты и документацию
# 
# # VERSION
# 
# 3.7
# 
# # SYNOPSIS
# 
# Файл lib/Example.md:
#@> lib/Example.md
#>> Twice two:
#>> ```perl
#>> 2*2  # -> 2+2
#>> ```
#@< EOF
# 
# Тест:
subtest 'SYNOPSIS' => sub { 
use Liveman;

my $liveman = Liveman->new(prove => 1);

$liveman->transform("lib/Example.md");

local ($::_g0 = do {$liveman->{count}}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$liveman->{count}    # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {-f "t/example.t"}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '-f "t/example.t"     # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {-f "lib/Example.pod"}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '-f "lib/Example.pod" # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

$liveman->transforms;
local ($::_g0 = do {$liveman->{count}}, $::_e0 = do {0}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$liveman->{count}   # -> 0' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {Liveman->new(compile_force => 1)->transforms->{count}}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'Liveman->new(compile_force => 1)->transforms->{count} # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

my $prove_return_code = $liveman->tests->{exit_code};

local ($::_g0 = do {$prove_return_code}, $::_e0 = do {0}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$prove_return_code          # -> 0' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {-f "cover_db/coverage.html"}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '-f "cover_db/coverage.html" # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

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
# **Примечание:** `trans -R` покажет список языков, которые можно указывать в **!from:to** на первой строке документа.
# 
# Предшественником `liveman` является [miu](https://github.com/darviarush/miu).
# 
# ## TYPES OF TESTS
# 
# Коды секций без указанного языка программирования или с `perl` записываются как код в файл `t/**.t`. А комментарий со стрелкой (# -> )превращается в тест `Test::More`.
# 
# Поддерживаемые тесты:
# 
# * `->`, `→` – сравнение скаляров;
# * `-->`, `⟶` – сравнение структур;
# * `=>`, `⇒` – сравнение c интерполируемой строкой;
# * `\>`, `↦` – сравнение с неинтерполируемой строкой;
# * `^=>`, `⤇` – сравнение начала скаляра с интерполируемой строкой;
# * `$=>`, `➾` – сравнение конца скаляра с интерполируемой строкой;
# * `*=>`, `⥴` – сравнение середины скаляра с интерполируемой строкой;
# * `^->`, `↣` – сравнение начала скаляра с неинтерполируемой строкой;
# * `$->`, `⇥` – сравнение конца скаляра с неинтерполируемой строкой;
# * `*->`, `⥵` – сравнение середины скаляра с неинтерполируемой строкой;
# * `~>`, `↬` – сопоставление скаляра с регулярным выражением (`$code =~ /.../`);
# * `<~`, `↫` – отрицательное сопоставление скаляра с регулярным выражением (`$code !~ /.../`);
# * `@->`, `↯` – сравнение начала исключения с неинтерполируемой строкой;
# * `@=>`, `⤯` – сравнение начала исключения с интерполируемой строкой;
# * `@~>`, `⇝` – сопоставление исключения с регулярным выражением (`defined $@ && $@ =~ /.../`);
# * `<~@`, `⇜` – отрицательное сопоставление исключения с регулярным выражением (`defined $@ && $@ !~ /.../`);
# 
# ### `is`
# 
# Сравнить два эквивалентных выражения:
# 
::done_testing; }; subtest '`is`' => sub { 
local ($::_g0 = do {"hi!"}, $::_e0 = do {"hi" . "!"}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"hi!" # -> "hi" . "!"' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"hi!"}, $::_e0 = do {"hi" . "!"}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"hi!" # → "hi" . "!"' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ### `is_deeply`
# 
# Сравнить два выражения для структур:
# 
::done_testing; }; subtest '`is_deeply`' => sub { 
local ($::_g0 = do {["hi!"]}, $::_e0 = do {["hi" . "!"]}); ::is_deeply $::_g0, $::_e0, '["hi!"] # --> ["hi" . "!"]' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"hi!"}, $::_e0 = do {"hi" . "!"}); ::is_deeply $::_g0, $::_e0, '"hi!" # ⟶ "hi" . "!"' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ### `is` with extrapolate-string
# 
# Сравнить выражение с экстраполированной строкой:
# 
::done_testing; }; subtest '`is` with extrapolate-string' => sub { 
my $exclamation = "!";
local ($::_g0 = do {"hi!2"}, $::_e0 = "hi${exclamation}2"); ::ok $::_g0 eq $::_e0, '"hi!2" # => hi${exclamation}2' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"hi!2"}, $::_e0 = "hi${exclamation}2"); ::ok $::_g0 eq $::_e0, '"hi!2" # ⇒ hi${exclamation}2' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ### `is` with nonextrapolate-string
# 
# Сравнить выражение с неэкстраполированной строкой:
# 
::done_testing; }; subtest '`is` with nonextrapolate-string' => sub { 
local ($::_g0 = do {'hi${exclamation}3'}, $::_e0 = 'hi${exclamation}3'); ::ok $::_g0 eq $::_e0, '\'hi${exclamation}3\' # \> hi${exclamation}3' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {'hi${exclamation}3'}, $::_e0 = 'hi${exclamation}3'); ::ok $::_g0 eq $::_e0, '\'hi${exclamation}3\' # ↦ hi${exclamation}3' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ### `like`
# 
# Скаляр должен быть сопостовим с регулярным выражением:
# 
::done_testing; }; subtest '`like`' => sub { 
::like scalar do {'abbc'}, qr{b+}, '\'abbc\' # ~> b+'; undef $::_g0; undef $::_e0;
::like scalar do {'abc'}, qr{b+}, '\'abc\'  # ↬ b+'; undef $::_g0; undef $::_e0;

# 
# ### `unlike`
# 
# В скаляре не должно быть совпадения с регулярным выражением:
# 
::done_testing; }; subtest '`unlike`' => sub { 
::unlike scalar do {'ac'}, qr{b+}, '\'ac\' # <~ b+'; undef $::_g0; undef $::_e0;
::unlike scalar do {'ac'}, qr{b+}, '\'ac\' # ↫ b+'; undef $::_g0; undef $::_e0;

# 
# ### `like` begins with extrapolate-string
# 
# Скаляр должен начинаться экстраполированой срокой:
# 
::done_testing; }; subtest '`like` begins with extrapolate-string' => sub { 
my $var = 'b';

local ($::_g0 = do {'abbc'}, $::_e0 = "a$var"); ::ok $::_g0 =~ /^${\quotemeta $::_e0}/, '\'abbc\' # ^=> a$var' or ::diag ::string_diff($::_g0, $::_e0, 1); undef $::_g0; undef $::_e0;
local ($::_g0 = do {'abc'}, $::_e0 = "a$var"); ::ok $::_g0 =~ /^${\quotemeta $::_e0}/, '\'abc\'  # ⤇ a$var' or ::diag ::string_diff($::_g0, $::_e0, 1); undef $::_g0; undef $::_e0;

# 
# ### `like` ends with extrapolate-string
# 
# Скаляр должен заканчиваться экстраполированой срокой:
# 
::done_testing; }; subtest '`like` ends with extrapolate-string' => sub { 
my $var = 'c';

local ($::_g0 = do {'abbc'}, $::_e0 = "b$var"); ::ok $::_g0 =~ /${\quotemeta $::_e0}$/, '\'abbc\' # $=> b$var' or ::diag ::string_diff($::_g0, $::_e0, 1); undef $::_g0; undef $::_e0;
local ($::_g0 = do {'abc'}, $::_e0 = "b$var"); ::ok $::_g0 =~ /${\quotemeta $::_e0}$/, '\'abc\'  # ➾ b$var' or ::diag ::string_diff($::_g0, $::_e0, 1); undef $::_g0; undef $::_e0;

# 
# ### `like` inners with extrapolate-string
# 
# Скаляр должен содержать экстраполированую сроку:
# 
::done_testing; }; subtest '`like` inners with extrapolate-string' => sub { 
my $var = 'x';

local ($::_g0 = do {'abxc'}, $::_e0 = "b$var"); ::ok $::_g0 =~ quotemeta $::_e0, '\'abxc\'  # *=> b$var' or ::diag ::string_diff($::_g0, $::_e0, 0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {'abxs'}, $::_e0 = "b$var"); ::ok $::_g0 =~ quotemeta $::_e0, '\'abxs\'  # ⥴ b$var' or ::diag ::string_diff($::_g0, $::_e0, 0); undef $::_g0; undef $::_e0;

# 
# ### `like` begins with nonextrapolate-string
# 
# Скаляр должен начинаться неэкстраполированой срокой:
# 
::done_testing; }; subtest '`like` begins with nonextrapolate-string' => sub { 
local ($::_g0 = do {'abbc'}, $::_e0 = 'ab'); ::ok $::_g0 =~ /^${\quotemeta $::_e0}/, '\'abbc\' # ^-> ab' or ::diag ::string_diff($::_g0, $::_e0, 1); undef $::_g0; undef $::_e0;
local ($::_g0 = do {'abc'}, $::_e0 = 'ab'); ::ok $::_g0 =~ /^${\quotemeta $::_e0}/, '\'abc\'  # ↣ ab' or ::diag ::string_diff($::_g0, $::_e0, 1); undef $::_g0; undef $::_e0;

# 
# ### `like` ends with nonextrapolate-string
# 
# Скаляр должен заканчиваться неэкстраполированой срокой:
# 
::done_testing; }; subtest '`like` ends with nonextrapolate-string' => sub { 
local ($::_g0 = do {'abbc'}, $::_e0 = 'bc'); ::ok $::_g0 =~ /${\quotemeta $::_e0}$/, '\'abbc\' # $-> bc' or ::diag ::string_diff($::_g0, $::_e0, -1); undef $::_g0; undef $::_e0;
local ($::_g0 = do {'abc'}, $::_e0 = 'bc'); ::ok $::_g0 =~ /${\quotemeta $::_e0}$/, '\'abc\'  # ⇥ bc' or ::diag ::string_diff($::_g0, $::_e0, -1); undef $::_g0; undef $::_e0;

# 
# ### `like` inners with nonextrapolate-string
# 
# Скаляр должен содержать неэкстраполированую сроку:
# 
::done_testing; }; subtest '`like` inners with nonextrapolate-string' => sub { 
local ($::_g0 = do {'abbc'}, $::_e0 = 'bb'); ::ok $::_g0 =~ quotemeta $::_e0, '\'abbc\' # *-> bb' or ::diag ::string_diff($::_g0, $::_e0, 0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {'abc'}, $::_e0 = 'b'); ::ok $::_g0 =~ quotemeta $::_e0, '\'abc\'  # ⥵ b' or ::diag ::string_diff($::_g0, $::_e0, 0); undef $::_g0; undef $::_e0;

# 
# ### `like` throw begins with nonextrapolate-string
# 
# Исключение должно начинаться с неэкстраполированой сроки:
# 
::done_testing; }; subtest '`like` throw begins with nonextrapolate-string' => sub { 
eval {1/0}; local ($::_g0 = $@, $::_e0 = 'Illegal division by zero'); ok defined($::_g0) && $::_g0 =~ /^${\quotemeta $::_e0}/, '1/0 # @-> Illegal division by zero' or ::diag ::string_diff($::_g0, $::_e0, 1); undef $::_g0; undef $::_e0;
eval {1/0}; local ($::_g0 = $@, $::_e0 = 'Illegal division by zero'); ok defined($::_g0) && $::_g0 =~ /^${\quotemeta $::_e0}/, '1/0 # ↯ Illegal division by zero' or ::diag ::string_diff($::_g0, $::_e0, 1); undef $::_g0; undef $::_e0;

# 
# ### `like` throw begins with extrapolate-string
# 
# Исключение должно начинаться с экстраполированой сроки:
# 
::done_testing; }; subtest '`like` throw begins with extrapolate-string' => sub { 
my $by = 'by';

eval {1/0}; local ($::_g0 = $@, $::_e0 = "Illegal division $by zero"); ok defined($::_g0) && $::_g0 =~ /^${\quotemeta $::_e0}/, '1/0 # @=> Illegal division $by zero' or ::diag ::string_diff($::_g0, $::_e0, 1); undef $::_g0; undef $::_e0;
eval {1/0}; local ($::_g0 = $@, $::_e0 = "Illegal division $by zero"); ok defined($::_g0) && $::_g0 =~ /^${\quotemeta $::_e0}/, '1/0 # ⤯ Illegal division $by zero' or ::diag ::string_diff($::_g0, $::_e0, 1); undef $::_g0; undef $::_e0;

# 
# ### `like` throw
# 
# Исключение должно быть сопостовимо с регулярным выражением:
# 
::done_testing; }; subtest '`like` throw' => sub { 
eval {1/0}; local ($::_g0 = $@, $::_e0 = qr{division\s*by\s*zero}); ok defined($::_g0) && $::_g0 =~ $::_e0, '1/0 # @~> division\s*by\s*zero' or ::diag defined($::_g0)? "Got:$::_g0": 'Got is undef'; undef $::_g0; undef $::_e0;
eval {1/0}; local ($::_g0 = $@, $::_e0 = qr{division\s*by\s*zero}); ok defined($::_g0) && $::_g0 =~ $::_e0, '1/0 # ⇝ division\s*by\s*zero' or ::diag defined($::_g0)? "Got:$::_g0": 'Got is undef'; undef $::_g0; undef $::_e0;

# 
# ### `unlike` throw
# 
# Исключение не должно быть сопостовимо с регулярным выражением (но оно должно иметь место):
# 
::done_testing; }; subtest '`unlike` throw' => sub { 
eval {1/0}; local ($::_g0 = $@, $::_e0 = qr{auto}); ok defined($::_g0) && $::_g0 !~ $::_e0, '1/0 # <~@ auto' or ::diag defined($::_g0)? "Got:$::_g0": 'Got is undef'; undef $::_g0; undef $::_e0;
eval {1/0}; local ($::_g0 = $@, $::_e0 = qr{auto}); ok defined($::_g0) && $::_g0 !~ $::_e0, '1/0 # ⇜ auto' or ::diag defined($::_g0)? "Got:$::_g0": 'Got is undef'; undef $::_g0; undef $::_e0;

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
# Эти префиксы могут быть как на английском, так и на русском (`File [path](https://metacpan.org/pod/path):` и `File [path](https://metacpan.org/pod/path) is:`).
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
::done_testing; }; subtest 'test_path ($md_path)' => sub { 
local ($::_g0 = do {Liveman->new->test_path("lib/PathFix/RestFix.md")}, $::_e0 = "t/path-fix/rest-fix.t"); ::ok $::_g0 eq $::_e0, 'Liveman->new->test_path("lib/PathFix/RestFix.md") # => t/path-fix/rest-fix.t' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## transform ($md_path, [$test_path])
# 
# Компилирует `lib/**.md`-файл в `t/**.t`-файл.
# 
# А так же заменяет **pod**-документацию в секции `__END__` в `lib/**.pm`-файле и создаёт `lib/**.pm`-файл, если тот существует, а иначе – создаёт файл`lib/**.pod`.
# 
# При вызове `transform` в `SYNOPSYS` был создан файл `lib/Example.pod`.
# 
# Файл lib/Example.pod является:

{ my $s = 'lib/Example.pod'; open my $__f__, '<:utf8', $s or die "Read $s: $!"; my $n = join '', <$__f__>; close $__f__; ::is $n, 'Twice two:

	2*2  # -> 2+2

', "File $s"; }
# 
# Создадим `lib/Example.pm` и вызовем `transform`:
# 
::done_testing; }; subtest 'transform ($md_path, [$test_path])' => sub { 
open my $fh, ">", "lib/Example.pm" or die $!;
print $fh q{package Example;

1;};
close $fh;

my $liveman = Liveman->new(prove => 1);

$liveman->transform("lib/Example.md");

# 
# Файл lib/Example.pm является:

{ my $s = 'lib/Example.pm'; open my $__f__, '<:utf8', $s or die "Read $s: $!"; my $n = join '', <$__f__>; close $__f__; ::is $n, 'package Example;

1;

__END__

=encoding utf-8

Twice two:

	2*2  # -> 2+2

', "File $s"; }
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
# ## load_po ($md, $from, $to)
# 
# Считывает po-файл.
# 
# ## save_po ()
# 
# Сохраняет po-файл.
# 
# ## trans ($text, $lineno)
# 
# Функция переводит текст с одного языка на другой используя утилиту trans.
# 
# ## trans_paragraph ($paragraph, $lineno)
# 
# Так же разбивает по параграфам.
# 
# # DEPENDENCIES IN CPANFILE
# 
# В своей библиотеке, которую вы будете тестировать Liveman-ом, нужно будет указать дополнительные зависимости для тестов в **cpanfile**:
# 

# on 'test' => sub {
#     requires 'Test::More', '0.98';
# 
#     requires 'Carp';
#     requires 'File::Basename';
#     requires 'File::Path';
#     requires 'File::Slurper';
#     requires 'File::Spec';
#     requires 'Scalar::Util';
# };

# 
# Так же неплохо будет указать и сам **Liveman** в разделе для разработки:
# 

# on 'develop' => sub {
#     requires 'Minilla', 'v3.1.19';
#     requires 'Data::Printer', '1.000004';
#     requires 'Liveman', '1.0';
# };

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

	::done_testing;
};

::done_testing;
