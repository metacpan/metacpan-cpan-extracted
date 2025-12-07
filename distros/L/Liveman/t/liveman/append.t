use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  use String::Diff qw//; use Data::Dumper qw//; use Term::ANSIColor qw//;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-2]); 	my $project_name = $dirs[$#dirs-2]; 	my @test_dirs = @dirs[$#dirs-2+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} }  my $white = Term::ANSIColor::color('BRIGHT_WHITE'); my $red = Term::ANSIColor::color('BRIGHT_RED'); my $green = Term::ANSIColor::color('BRIGHT_GREEN'); my $reset = Term::ANSIColor::color('RESET'); my @diff = ( 	remove_open => "$white\[$red", 	remove_close => "$white]$reset", 	append_open => "$white\{$green", 	append_close => "$white}$reset", );  sub _string_diff { 	my ($got, $expected, $chunk) = @_; 	$got = substr($got, 0, length $expected) if $chunk == 1; 	$got = substr($got, -length $expected) if $chunk == -1; 	String::Diff::diff_merge($got, $expected, @diff) }  sub _struct_diff { 	my ($got, $expected) = @_; 	String::Diff::diff_merge( 		Data::Dumper->new([$got], ['diff'])->Indent(0)->Useqq(1)->Dump, 		Data::Dumper->new([$expected], ['diff'])->Indent(0)->Useqq(1)->Dump, 		@diff 	) }  # 
# # NAME
# 
# Liveman::Append - добавляет секции для методов и функций из `lib/**.pm` в `lib/**.md`
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
use Liveman::Append;

my $liveman_append = Liveman::Append->new;

local ($::_g0 = do {ref $liveman_append}, $::_e0 = "Liveman::Append"); ::ok $::_g0 eq $::_e0, 'ref $liveman_append     # => Liveman::Append' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

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
local ($::_g0 = do {-e "lib/Alt/The/Plan.md"}, $::_e0 = do {undef}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '-e "lib/Alt/The/Plan.md" # -> undef' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# Set the mocks:
*Liveman::Append::_git_user_name = sub {'Yaroslav O. Kosmina'};
*Liveman::Append::_git_user_email = sub {'dart@cpan.org'};
*Liveman::Append::_year = sub {2023};
*Liveman::Append::_license = sub {"Perl5"};
*Liveman::Append::_land = sub {"Rusland"};

my $liveman_append = Liveman::Append->new->append("lib/Alt/The/Plan.pm");
local ($::_g0 = do {$liveman_append->{count}}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$liveman_append->{count}	# -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$liveman_append->{added}}, $::_e0 = do {2}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$liveman_append->{added}	# -> 2' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {-e "lib/Alt/The/Plan.md"}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '-e "lib/Alt/The/Plan.md" # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# And again:
$liveman_append = Liveman::Append->new->append("lib/Alt/The/Plan.pm");
local ($::_g0 = do {$liveman_append->{count}}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$liveman_append->{count}	# -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$liveman_append->{added}}, $::_e0 = do {0}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$liveman_append->{added}	# -> 0' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# File lib/Alt/The/Plan.md is:
{ my $s = 'lib/Alt/The/Plan.md'; open my $__f__, '<:utf8', $s or die "Read $s: $!"; my $got = join '', <$__f__>; close $__f__; my $expected = '# NAME

Alt::The::Plan - 

# SYNOPSIS

```perl
use Alt::The::Plan;

my $plan = Alt::The::Plan->new;
```

# DESCRIPTION

.

# SUBROUTINES

## planner ()

.

```perl
my $plan = Alt::The::Plan->new;
$plan->planner  # -> .3
```

## miting ($meet, $man, $woman)

This is first!

```perl
my $plan = Alt::The::Plan->new;
$plan->miting($meet, $man, $woman)  # -> .3
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
'; ::ok $got eq $expected, 'File lib/Alt/The/Plan.md' or ::diag ::_string_diff($got, $expected) }
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
