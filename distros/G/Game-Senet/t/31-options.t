use strict;
use warnings;
use Test::More;
use Symbol qw(gensym);

use Game::Senet::Terminal;
use Game::Senet::Variant;
use Game::Senet::Bot;
use Game::Terminal::Kit::Options;

{
    package Local::Out;
    sub TIEHANDLE { my $text = ''; return bless \$text, shift }
    sub PRINT     { my $self = shift; $$self .= join '', @_; return 1 }
    sub PRINTF    { my $self = shift; $$self .= sprintf shift, @_; return 1 }
    sub BINMODE   { 1 }
    sub FILENO    { -1 }
    sub CLOSE     { 1 }

    package Local::In;
    sub TIEHANDLE { my ($class, @lines) = @_; return bless [@lines], $class }
    sub READLINE  { my $self = shift; return @$self ? shift(@$self) . "\n" : undef }
    sub EOF       { !@{ $_[0] } }
    sub BINMODE   { 1 }
    sub FILENO    { -1 }
    sub CLOSE     { 1 }
}

# THE LAUNCHER'S MENU, plan_game_senet/08: every field options() offers is one
# run() accepts, through the kit's argv_for, and each changes what is played.

my $fields = Game::Senet::Terminal->options;
my %field = map { $_->{name} => $_ } @$fields;

is_deeply([ map { $_->{name} } @$fields ], [ qw(mode rules pieces level side first seed) ], 'the fields, in order');
is_deeply($field{rules}{choices}, [ Game::Senet::Variant->names ], 'rules are the names Variant reports');
my ($top) = sort { $b <=> $a } map { (Game::Senet::Bot->levels($_))[-1] } Game::Senet::Variant->names;
is($field{level}{max}, $top, "level goes to $top, the largest ladder's top");
is_deeply([ Game::Terminal::Kit::Options::validate($fields) ], [], 'and the kit finds nothing wrong with the list');

sub screen_for {
    my (%values) = @_;
    my @argv = Game::Terminal::Kit::Options::argv_for($fields, \%values);
    local *STDIN;
    local *STDOUT;
    tie *STDIN, 'Local::In', 'quit';
    my $written = tie *STDOUT, 'Local::Out';
    my $status = Game::Senet::Terminal->run(@argv, '--pace', '0', '--no-pick', '--ascii', '--no-colour');
    my $said = $$written;
    undef $written;
    untie *STDOUT;
    untie *STDIN;
    return ($status, $said, "@argv");
}

my %base = (seed => '736565642031', mode => 'hotseat');
my (undef, $plain) = screen_for(%base);
my %change = (
    mode   => 'watch',
    rules  => 'skyruk',
    pieces => 7,
    level  => 1,
    side   => 'dark',
    first  => 'dark',
    seed   => '6f74686572',
);
for my $name (map { $_->{name} } @$fields) {
    my %values = (%base, $name => $change{$name});
    $values{mode} = 'bot' if $name eq 'side' || $name eq 'level';
    my ($status, $said, $argv) = screen_for(%values);
    is($status, 0, "$name: $argv is accepted");
    isnt($said, $plain, "  and changes what is played");
}

done_testing();
