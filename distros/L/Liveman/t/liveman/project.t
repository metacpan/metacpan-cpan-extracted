use common::sense; use open qw/:std :utf8/;  use Carp qw//; use File::Basename qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  BEGIN {     $SIG{__DIE__} = sub {         my ($s) = @_;         if(ref $s) {             $s->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $s;             die $s;         } else {             die Carp::longmess defined($s)? $s: "undef"         }     };      my $t = File::Slurper::read_text(__FILE__);     my $s =  '/tmp/.liveman/perl-liveman/liveman!project'    ;     File::Path::rmtree($s) if -e $s;     File::Path::mkpath($s);     chdir $s or die "chdir $s: $!";      while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) {         my ($file, $code) = ($1, $2);         $code =~ s/^#>> //mg;         File::Path::mkpath(File::Basename::dirname($file));         File::Slurper::write_text($file, $code);     }  } # 
# # NAME
# 
# Liveman::Project - создать новый Perl-репозиторий
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
use Liveman::Project;

my $liveman_project = Liveman::Project->new;

::is scalar do {ref $liveman_project}, "Liveman::Project", 'ref $liveman_project  # => Liveman::Project';

# 
# # DESCRIPTION
# 
# Создает новый Perl-репозиторий.
# 
# # SUBROUTINES/METHODS
# 
# ## new (@params)
# 
# Конструктор.
# 
# ## make ()
# 
# Создаёт новый проект.
# 
# ## minil_toml ()
# 
# Создаёт файл `minil.toml`.
# 
# ## cpanfile ()
# 
# Создаёт `cpanfile`.
# 
# ## mkpm ()
# 
# Создает главный модуль.
# 
# ## license ()
# 
# Зоздёт лицензию.
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
# The Liveman::Project module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.

	done_testing;
};

done_testing;
