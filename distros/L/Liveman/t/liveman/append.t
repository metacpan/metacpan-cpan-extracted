use common::sense; use open qw/:std :utf8/; use Test::More 0.98; sub _mkpath_ { my ($p) = @_; length($`) && !-e $`? mkdir($`, 0755) || die "mkdir $`: $!": () while $p =~ m!/!g; $p } BEGIN { use Scalar::Util qw//; use Carp qw//; $SIG{__DIE__} = sub { my ($s) = @_; if(ref $s) { $s->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $s; die $s } else {die Carp::longmess defined($s)? $s: "undef" }}; my $t = `pwd`; chop $t; $t .= '/' . __FILE__; my $s = '/tmp/.liveman/perl-liveman!liveman!append/'; `rm -fr '$s'` if -e $s; chdir _mkpath_($s) or die "chdir $s: $!"; open my $__f__, "<:utf8", $t or die "Read $t: $!"; read $__f__, $s, -s $__f__; close $__f__; while($s =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { my ($file, $code) = ($1, $2); $code =~ s/^#>> //mg; open my $__f__, ">:utf8", _mkpath_($file) or die "Write $file: $!"; print $__f__ $code; close $__f__; } } # # NAME
# 
# Liveman::Append - append manual by methods from `lib/**.pm` to `lib/**.md`
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
# It append manual by methods and features from modules (`lib/**.pm`) to their manuals (`lib/**.md`).
# 
# 1. Methods is perl-subroutine starting with keyword `sub`.
# 1. Features is class property maked OOP-frameworks as `Aion`, `Moose`, `Moo`, `Mo`, and starting with keyword `has`.
# 
# # SUBROUTINES
# 
# ## new (@params)
# 
# The constructor.
# 
# ## mkmd ($md)
# 
# It make md-file.
# 
# ## appends ()
# 
# Append to `lib/**.md` from `lib/**.pm` subroutines and features.
# 
# ## append ($path)
# 
# Append subroutines and features from the module with `$path` into its documentation in the its sections.
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
done_testing; }; subtest 'append ($path)' => sub { 
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

Yaroslav O. Kosmina [dart@cpan.org](mailto:dart@cpan.org)

# LICENSE

⚖ **Perl5**

# COPYRIGHT

The Alt::The::Plan module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
', "File $s"; }
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
# The Liveman::Append module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.

	done_testing;
};

done_testing;
