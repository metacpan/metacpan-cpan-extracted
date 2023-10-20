use common::sense; use open qw/:std :utf8/; use Test::More 0.98; sub _mkpath_ { my ($p) = @_; length($`) && !-e $`? mkdir($`, 0755) || die "mkdir $`: $!": () while $p =~ m!/!g; $p } BEGIN { use Scalar::Util qw//; use Carp qw//; $SIG{__DIE__} = sub { my ($s) = @_; if(ref $s) { $s->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $s; die $s } else {die Carp::longmess defined($s)? $s: "undef" }}; my $t = `pwd`; chop $t; $t .= '/' . __FILE__; my $s = '/tmp/.liveman/perl-liveman!liveman!project/'; `rm -fr '$s'` if -e $s; chdir _mkpath_($s) or die "chdir $s: $!"; open my $__f__, "<:utf8", $t or die "Read $t: $!"; read $__f__, $s, -s $__f__; close $__f__; while($s =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { my ($file, $code) = ($1, $2); $code =~ s/^#>> //mg; open my $__f__, ">:utf8", _mkpath_($file) or die "Write $file: $!"; print $__f__ $code; close $__f__; } } # # NAME
# 
# Liveman::Project - maker new perl-repository
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
# Creates a new perl-repository.
# 
# # SUBROUTINES/METHODS
# 
# ## new (@params)
# 
# The constructor.
# 
# ## make ()
# 
# Creates a new project.
# 
# ## minil_toml ()
# 
# Creates a file `minil.toml`.
# 
# ## cpanfile ()
# 
# Creates a cpanfile.
# 
# ## mkpm ()
# 
# Creates a main module.
# 
# ## license ()
# 
# Creates a license.
# 
# # AUTHOR
# 
# Yaroslav O. Kosmina [darviarush@mail.ru](mailto:darviarush@mail.ru)
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
