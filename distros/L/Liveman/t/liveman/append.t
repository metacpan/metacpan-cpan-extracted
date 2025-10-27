use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-2]); 	my $project_name = $dirs[$#dirs-2]; 	my @test_dirs = @dirs[$#dirs-2+2 .. $#dirs]; 	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} } # 
# # NAME
# 
# Liveman::Append - добавляет секции для методов и функций из `lib/**.pm` в `lib/**.md`
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
use Liveman::Append;

my $liveman_append = Liveman::Append->new;

::is scalar do {ref $liveman_append}, "Liveman::Append", 'ref $liveman_append     # => Liveman::Append';

# 
# # DESCRIPTION
# 
# Добавляет руководство по методам и функциям модулей (`lib/**.pm`) к их руководствам (`lib/**.md`).
# 
# 1. Методы — это Perl-подпрограмма, начинающаяся с ключевого слова `sub`.
# 1. Особенности — это свойства экземпляров добавляемые ООП-фреймворками, такими как `Aion`, `Moose`, `Moo`, `Mo`, и начинающиеся с ключевого слова `has`.
# 
# # SUBROUTINES
# 
# ## new (@params)
# 
# Конструктор.
# 
# ## mkmd ($md)
# 
# Создаёт md-файл.
# 
# ## appends ()
# 
# Добавляет в `lib/**.md` из `lib/**.pm` подпрограммы и особенности.
# 
# ## append ($path)
# 
# Добавляет подпрограммы и функции из модуля (`$path`) в его мануал.
# 
# File lib/Alt/The/Plan.pm:
#@> lib/Alt/The/Plan.pm
#>> package Alt::The::Plan;
#>> 
#>> sub planner {
#>> 	my ($self) = @_;
#>> }
#>> 
#>> # This is first!
#>> sub miting {
#>> 	my ($self, $meet, $man, $woman) = @_;
#>> }
#>> 
#>> sub _exquise_me {
#>> 	my ($self, $meet, $man, $woman) = @_;
#>> }
#>> 
#>> 1;
#@< EOF
# 
::done_testing; }; subtest 'append ($path)' => sub { 
::is scalar do {-e "lib/Alt/The/Plan.md"}, scalar do{undef}, '-e "lib/Alt/The/Plan.md" # -> undef';

# Set the mocks:
*Liveman::Append::_git_user_name = sub {'Yaroslav O. Kosmina'};
*Liveman::Append::_git_user_email = sub {'dart@cpan.org'};
*Liveman::Append::_year = sub {2023};
*Liveman::Append::_license = sub {"Perl5"};
*Liveman::Append::_land = sub {"Rusland"};

my $liveman_append = Liveman::Append->new->append("lib/Alt/The/Plan.pm");
::is scalar do {$liveman_append->{count}}, scalar do{1}, '$liveman_append->{count}	# -> 1';
::is scalar do {$liveman_append->{added}}, scalar do{2}, '$liveman_append->{added}	# -> 2';

::is scalar do {-e "lib/Alt/The/Plan.md"}, scalar do{1}, '-e "lib/Alt/The/Plan.md" # -> 1';

# And again:
$liveman_append = Liveman::Append->new->append("lib/Alt/The/Plan.pm");
::is scalar do {$liveman_append->{count}}, scalar do{1}, '$liveman_append->{count}	# -> 1';
::is scalar do {$liveman_append->{added}}, scalar do{0}, '$liveman_append->{added}	# -> 0';

# 
# File lib/Alt/The/Plan.md is:

{ my $s = 'lib/Alt/The/Plan.md'; open my $__f__, '<:utf8', $s or die "Read $s: $!"; my $n = join '', <$__f__>; close $__f__; ::is $n, '# NAME

Alt::The::Plan - 

# SYNOPSIS

```perl
use Alt::The::Plan;

my $alt_the_plan = Alt::The::Plan->new;
```

# DESCRIPTION

.

# SUBROUTINES

## planner ()

.

```perl
my $alt_the_plan = Alt::The::Plan->new;
$alt_the_plan->planner  # -> .3
```

## miting ($meet, $man, $woman)

This is first!

```perl
my $alt_the_plan = Alt::The::Plan->new;
$alt_the_plan->miting($meet, $man, $woman)  # -> .3
```

# INSTALL

For install this module in your system run next [command](https://metacpan.org/pod/App::cpm):

```sh
sudo cpm install -gvv Alt::The::Plan
```

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **Perl5**

# COPYRIGHT

The Alt::The::Plan module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
', "File $s"; }
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
# The Liveman::Append module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.

	::done_testing;
};

::done_testing;
