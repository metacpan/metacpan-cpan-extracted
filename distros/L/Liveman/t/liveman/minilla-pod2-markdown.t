use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-2]); 	my $project_name = $dirs[$#dirs-2]; 	my @test_dirs = @dirs[$#dirs-2+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} } # 
# # NAME
# 
# Liveman::MinillaPod2Markdown – заглушка для Minilla, которая перебрасывает lib/MainModule.md в README.md
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
use Liveman::MinillaPod2Markdown;

my $mark = Liveman::MinillaPod2Markdown->new;

::is scalar do {$mark->isa("Pod::Markdown")}, scalar do{1}, '$mark->isa("Pod::Markdown")  # -> 1';

use File::Slurper qw/write_text/;
write_text "X.md", "hi!";
write_text "X.pm", "our \$VERSION = 1.0;";

$mark->parse_from_file("X.pm");
::is scalar do {$mark->{pm_path}}, "X.pm", '$mark->{pm_path}  # => X.pm';
::is scalar do {$mark->{md_path}}, "X.md", '$mark->{md_path}  # => X.md';

::is scalar do {$mark->as_markdown}, "hi!", '$mark->as_markdown  # => hi!';

# 
# # DESCRIPION
# 
# Добавьте строку `markdown_maker = "Liveman::MinillaPod2Markdown"` в `minil.toml`, и Minilla не будет создавать `README.md` из pod-документации главного модуля, а возьмёт из одноимённого файла рядом с расширением `*.md`.
# 
# # SUBROUTINES
# 
# ## as_markdown ()
# 
# Заглушка.
# 
# ## new ()
# 
# Конструктор.
# 
# ## parse_from_file ($path)
# 
# Заглушка.
# 
# ## parse_options ($options)
# 
# Парсит !options на первой строке:
# 
# 1. Удаляет ! и языки за ним.
# 2. Переводит бейджи через запятую в markdown-картинки.
# 
# Список бейджей:
# 
# 1. badges - все бейджи.
# 2. github-actions - бейдж на тесты гитхаба.
# 3. metacpan - бейдж на релиз.
# 4. cover - бейдж на покрытие который создаёт `liveman` при прохождении теста в `doc/badges/total.svg`.
# 
# ## github_path ()
# 
# Путь проекта на github: username/repository.
# 
# ## read_md ()
# 
# Считывает файл с markdown-документацией.
# 
# ## read_pm ()
# 
# Считывает модуль.
# 
# ## pm_version ()
# 
# Версия модуля.
# 
# # INSTALL
# 
# Чтобы установить этот модуль в вашу систему, выполните следующие действия [командой](https://metacpan.org/pod/App::cpm):
# 

# sudo cpm install -gvv Liveman::MinillaPod2Markdown

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
# The Liveman::MinillaPod2Markdown module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.

	::done_testing;
};

::done_testing;
