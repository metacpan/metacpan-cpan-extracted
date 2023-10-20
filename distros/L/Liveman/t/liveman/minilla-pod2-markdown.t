use common::sense; use open qw/:std :utf8/; use Test::More 0.98; sub _mkpath_ { my ($p) = @_; length($`) && !-e $`? mkdir($`, 0755) || die "mkdir $`: $!": () while $p =~ m!/!g; $p } BEGIN { use Scalar::Util qw//; use Carp qw//; $SIG{__DIE__} = sub { my ($s) = @_; if(ref $s) { $s->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $s; die $s } else {die Carp::longmess defined($s)? $s: "undef" }}; my $t = `pwd`; chop $t; $t .= '/' . __FILE__; my $s = '/tmp/.liveman/perl-liveman!liveman!minilla-pod2-markdown/'; `rm -fr '$s'` if -e $s; chdir _mkpath_($s) or die "chdir $s: $!"; open my $__f__, "<:utf8", $t or die "Read $t: $!"; read $__f__, $s, -s $__f__; close $__f__; while($s =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { my ($file, $code) = ($1, $2); $code =~ s/^#>> //mg; open my $__f__, ">:utf8", _mkpath_($file) or die "Write $file: $!"; print $__f__ $code; close $__f__; } } # # NAME
# 
# Liveman::MinillaPod2Markdown - bung for Minilla. It not make README.md
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
# Add `markdown_maker = "Liveman::MinillaPod2Markdown"` to `minil.toml`, and Minilla do'nt make README.md.
# 
# # SUBROUTINES
# 
# ## as_markdown ()
# 
# The bung.
# 
# ## new ()
# 
# The constructor.
# 
# ## parse_from_file ($path)
# 
# The bung.
# 
# # INSTALL
# 
# For install this module in your system run next [command](https://metacpan.org/pod/App::cpm):
# 

# sudo cpm install -gvv Liveman::MinillaPod2Markdown

# 
# # AUTHOR
# 
# Yaroslav O. Kosmina [dart@cpan.org](dart@cpan.org)
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
