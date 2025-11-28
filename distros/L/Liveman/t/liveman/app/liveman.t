use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  use String::Diff qw//; use Data::Dumper qw//; use Term::ANSIColor qw//;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-3]); 	my $project_name = $dirs[$#dirs-3]; 	my @test_dirs = @dirs[$#dirs-3+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} }  my $white = Term::ANSIColor::color('BRIGHT_WHITE'); my $red = Term::ANSIColor::color('BRIGHT_RED'); my $green = Term::ANSIColor::color('BRIGHT_GREEN'); my $reset = Term::ANSIColor::color('RESET'); my @diff = ( 	remove_open => "$white\[$red", 	remove_close => "$white]$reset", 	append_open => "$white\{$green", 	append_close => "$white}$reset", );  sub _string_diff { 	my ($got, $expected, $chunk) = @_; 	$got = substr($got, 0, length $expected) if $chunk == 1; 	$got = substr($got, -length $expected) if $chunk == -1; 	String::Diff::diff_merge($got, $expected, @diff) }  sub _struct_diff { 	my ($got, $expected) = @_; 	String::Diff::diff_merge( 		Data::Dumper->new([$got], ['diff'])->Indent(0)->Useqq(1)->Dump, 		Data::Dumper->new([$expected], ['diff'])->Indent(0)->Useqq(1)->Dump, 		@diff 	) }  # 
# # NAME
# 
# liveman - «живое руководство». Утилита для конвертации файлов **lib/\*\*.md** в тестовые файлы (**t/\*\*.t**) и документацию (**POD**), которая размещается в соответствующем модуле (**lib/\*\*.pm**)
# 
# # SYNOPSIS
# 

# liveman [-h] [--man] [-A pkg [license]] [-w] [-o][-c][-f][-s][-a] [<files> ...]

# 
# # DESCRIPTION
# 
# Проблема современных проектов в том, что документация отделена от тестирования.
# Это означает, что примеры в документации могут не работать, а сама документация может отставать от кода.
# 
# Метод одновременного документирования и тестирования решает эту проблему.
# 
# Для документации был выбран формат **md**, поскольку он наиболее прост для ввода и широко распространён.
# Описанные в нем участки кода **perl** транслируются в тест. Документация переводится в **POD** и добавляется в раздел **\__END__** модуля perl.
# 
# Другими словами, **liveman** конвертирует **lib/\*\*.md**-файлы в тестовые файлы (**t/\*\*.t**) и документацию, которая помещается в соответствующую **lib/\*\*.pm** модуль. И сразу запускает тесты с покрытием.
# 
# Покрытие можно просмотреть в файле *cover_db/coverage.html*.
# 
# **Примечание:** лучше сразу поместить *cover_db/* в *.gitignore*.
# 
# # OPTIONS
# 
# **-h**, **--help**
# 
# Показать справку и выйти.
# 
# **-v**, **--version**
# 
# Показать версию и выйти.
# 
subtest 'OPTIONS' => sub { 
::like scalar do {`perl $ENV{PROJECT_DIR}/script/liveman -v`}, qr{^\d+\.\d+$}, '`perl $ENV{PROJECT_DIR}/script/liveman -v` # ~> ^\d+\.\d+$'; undef $::_g0; undef $::_e0;

# 
# **--man**
# 
# Распечатать инструкцию и завершиться.
# 
# **-c**, **--compile**
# 
# Только компилировать (без запуска тестов).
# 
# **-f**, **--force**
# 
# Преобразовать файлы *lib/\*\*.md*, даже если они не изменились.
# 
# **-p**, **--prove**
# 
# Использовать для тестов утилиту `prove`, а не `yath`.
# 
# **-o**, **--open**
# 
# Открыть покрытие в браузере.
# 
# **-O**, **--options** OPTIONS
# 
# Передать строку с опциями `yath` или `prove`. Эти параметры будут добавлены к параметрам по умолчанию.
# 
# Параметры по умолчанию для `yath`:
# 
#     `yath test -j4 --cover`
# 
# Параметры по умолчанию для `prove`:
# 
#     `prove -Ilib -r t`
# 
# **-а**, **--append**
# 
# Добавить разделы функций в `*.md` из `*.pm` и завершиться.
# 
# **-A**, **--new** PACKAGE \[LICENSE]
# 
# Создать новый репозиторий.
# 
# * *PACKAGE* — это имя нового пакета, например, `Aion::View`.
# * *LICENSE* — это имя лицензии, например, GPLv3 или perl_5.
# 
# **-D**, **--cpanfile**
# 
# Распечатать примерный cpanfile.
# 
# **-d**, **--diff-cpanfile** [meld]
# 
# Сравнить примерный cpanfile с существующим. Если параметр не указан – используется `meld`. В качестве альтернативы можно использовать `diff`, `colordiff`, `wdiff`, `kompare`, `kdiff3`, `tkdiff`, `diffuse` или любую другую утилиту, которая принимает два файла в качестве аргументов.
# 
# # INSTALL
# 
# Чтобы установить этот модуль в вашу систему, выполните следующую [команду](https://metacpan.org/pod/App::cpm):
# 

# sudo cpm install -gvv Liveman

# 
# # AUTHOR
# 
# Yaroslav O. Kosmina <mailto:dart@cpan.org>
# 
# # LICENSE
# 
# ⚖ **GPLv3**
# 
# # COPYRIGHT
# 
# The App::liveman module is copyright © 2024 Yaroslav O. Kosmina. Rusland. All rights reserved.

	::done_testing;
};

::done_testing;
