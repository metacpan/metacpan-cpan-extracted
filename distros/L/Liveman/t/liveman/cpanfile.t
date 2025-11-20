use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-2]); 	my $project_name = $dirs[$#dirs-2]; 	my @test_dirs = @dirs[$#dirs-2+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} } # 
# # NAME
# 
# Liveman::Cpanfile - анализатор зависимостей Perl проекта
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
use Liveman::Cpanfile;

chmod 0755, $_ for qw!scripts/test_script bin/tool!;

$::cpanfile = Liveman::Cpanfile->new;

::is scalar do {$::cpanfile->cpanfile}, scalar do{<< 'END'}, '$::cpanfile->cpanfile # -> << \'END\'';
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
	requires 'File::Basename';
	requires 'File::Find';
	requires 'File::Path';
	requires 'File::Slurper';
	requires 'File::Spec';
	requires 'Scalar::Util';
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

# 
# # DESCRIPTION
# 
# `Liveman::Cpanfile` анализирует структуру Perl проекта и извлекает информацию о зависимостях из исходного кода, тестов и документации. Модуль автоматически определяет используемые модули и помогает поддерживать актуальный `cpanfile`.
# 
# # SUBROUTINES
# 
# ## new ()
# 
# Конструктор.
# 
# ## pkg_from_path ()
# 
# Преобразует путь к файлу в имя пакета Perl.
# 
::done_testing; }; subtest 'pkg_from_path ()' => sub { 
::is scalar do {Liveman::Cpanfile::pkg_from_path('lib/My/Module.pm')}, "My::Module", 'Liveman::Cpanfile::pkg_from_path(\'lib/My/Module.pm\') # => My::Module';
::is scalar do {Liveman::Cpanfile::pkg_from_path('lib/My/App.pm')}, "My::App", 'Liveman::Cpanfile::pkg_from_path(\'lib/My/App.pm\')    # => My::App';

# 
# ## sc ()
# 
# Возвращает список исполняемых скриптов в директориях `scripts/` и `bin/`.
# 
# Файл scripts/test_script:
#@> scripts/test_script
#>> #!/usr/bin/env perl
#>> require Data::Printer;
#@< EOF
# 
# Файл bin/tool:
#@> bin/tool
#>> #!/usr/bin/env perl
#>> use List::Util;
#@< EOF
# 
::done_testing; }; subtest 'sc ()' => sub { 
::is_deeply scalar do {[$::cpanfile->sc]}, scalar do {[qw!bin/tool scripts/test_script!]}, '[$::cpanfile->sc] # --> [qw!bin/tool scripts/test_script!]';

# 
# ## pm ()
# 
# Возвращает список Perl модулей в директории `lib/`.
# 
# Файл lib/My/Module.pm:
#@> lib/My/Module.pm
#>> package My::Module;
#>> use strict;
#>> use warnings;
#>> 1;
#@< EOF
# 
# Файл lib/My/Other.pm:
#@> lib/My/Other.pm
#>> package My::Other;
#>> use common::sense;
#>> 1;
#@< EOF
# 
::done_testing; }; subtest 'pm ()' => sub { 
::is_deeply scalar do {[$::cpanfile->pm]}, scalar do {[qw!lib/My/Module.pm lib/My/Other.pm!]}, '[$::cpanfile->pm]  # --> [qw!lib/My/Module.pm lib/My/Other.pm!]';

# 
# ## mod ()
# 
# Возвращает список имен пакетов проекта соответствующих модулям в директории `lib/`.
# 
::done_testing; }; subtest 'mod ()' => sub { 
::is_deeply scalar do {[$::cpanfile->mod]}, scalar do {[qw/My::Module My::Other/]}, '[$::cpanfile->mod]  # --> [qw/My::Module My::Other/]';

# 
# ## md ()
# 
# Возвращает список Markdown файлов документации (`*.md`) в `lib/`.
# 
# Файл lib/My/Module.md:
#@> lib/My/Module.md
#>> # My::Module
#>> 
#>> This is a module for experiment with package My::Module.
#>> ```perl
#>> package My {}
#>> package My::Third {}
#>> use My::Other;
#>> use My;
#>> use Turbin;
#>> use Car::Auto;
#>> ```
#@< EOF
# 
::done_testing; }; subtest 'md ()' => sub { 
::is_deeply scalar do {[$::cpanfile->md]}, scalar do {[qw!lib/My/Module.md!]}, '[$::cpanfile->md]  # --> [qw!lib/My/Module.md!]';

# 
# ## md_mod ()
# 
# Список внедрённых в `*.md` пакетов.
# 
::done_testing; }; subtest 'md_mod ()' => sub { 
::is_deeply scalar do {[$::cpanfile->md_mod]}, scalar do {[qw!My My::Third!]}, '[$::cpanfile->md_mod]  # --> [qw!My My::Third!]';

# 
# ## deps ()
# 
# Список зависимостей явно указанных в скриптах и модулях без пакетов проекта.
# 
::done_testing; }; subtest 'deps ()' => sub { 
::is_deeply scalar do {[$::cpanfile->deps]}, scalar do {[qw!Data::Printer List::Util common::sense strict warnings!]}, '[$::cpanfile->deps]  # --> [qw!Data::Printer List::Util common::sense strict warnings!]';

# 
# ## t_deps ()
# 
# Список зависимостей из тестов за исключением:
# 
# 1. Зависмостей скриптов и модулей.
# 2. Пакетов проекта.
# 3. Внедрённых в `*.md` пакетов.
# 
::done_testing; }; subtest 't_deps ()' => sub { 
::is_deeply scalar do {[$::cpanfile->t_deps]}, scalar do {[qw!Car::Auto Carp Cwd File::Basename File::Find File::Path File::Slurper File::Spec Scalar::Util Test::More Turbin open!]}, '[$::cpanfile->t_deps]  # --> [qw!Car::Auto Carp Cwd File::Basename File::Find File::Path File::Slurper File::Spec Scalar::Util Test::More Turbin open!]';

# 
# ## cpanfile ()
# 
# Возвращает текст cpanfile c зависимостями для проекта.
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
# The Liveman::Cpanfile module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.

	::done_testing;
};

::done_testing;
