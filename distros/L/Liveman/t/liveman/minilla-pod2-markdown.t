use common::sense; use open qw/:std :utf8/;  use Carp qw//; use File::Basename qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  BEGIN {     $SIG{__DIE__} = sub {         my ($s) = @_;         if(ref $s) {             $s->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $s;             die $s;         } else {             die Carp::longmess defined($s)? $s: "undef"         }     };      my $t = File::Slurper::read_text(__FILE__);     my $s =  '/tmp/.liveman/perl-liveman/liveman!minilla-pod2-markdown'    ;     File::Path::rmtree($s) if -e $s;     File::Path::mkpath($s);     chdir $s or die "chdir $s: $!";      while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) {         my ($file, $code) = ($1, $2);         $code =~ s/^#>> //mg;         File::Path::mkpath(File::Basename::dirname($file));         File::Slurper::write_text($file, $code);     }  } # 
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
::is scalar do {$mark->{path}}, "X.md", '$mark->{path}  # => X.md';

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

	done_testing;
};

done_testing;
