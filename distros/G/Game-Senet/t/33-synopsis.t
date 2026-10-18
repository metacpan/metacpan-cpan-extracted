use strict;
use warnings;
use Test::More;

my $exited;
BEGIN { *CORE::GLOBAL::exit = sub { $exited = $_[0] // 0; die "exit was called\n" } }

use Game::Senet;
use Game::Senet::Bot;
use Game::Senet::Engine;
use Game::Senet::Terminal;

# THE SYNOPSIS OF EVERY MODULE RUNS, plan_game_senet/09. Each is taken out of
# the documentation of the module that was loaded and run as it is written.
# A synopsis that is a fragment, using a $game or a $board the prose around it
# has, is given that variable and nothing else. A comment on a print, or on the
# line after one, is a claim: each is read out of the synopsis and found among
# the lines printed, in order. What the table below adds is checked as well.
{
    package Local::Capture;
    sub TIEHANDLE { my $text = ''; return bless \$text, shift }
    sub PRINT     { my $self = shift; $$self .= join '', @_; return 1 }
    sub PRINTF    { my $self = shift; $$self .= sprintf shift, @_; return 1 }
}

sub synopsis_of {
    my ($module) = @_;
    (my $path = "$module.pm") =~ s{::}{/}g;
    my $file = $INC{$path} or return undef;
    open my $in, '<', $file or die "cannot read $file: $!";
    my $pod = do { local $/; <$in> };
    close $in;
    my ($section) = $pod =~ /^=head1 SYNOPSIS\n(.*?)^=head1 /ms or return undef;
    return join '', grep { /\A(?:    |\n)/ } split /^/m, $section;
}

my $n = 0;
sub run_capturing {
    my ($code) = @_;
    my $printed = tie *CAPTURE, 'Local::Capture';
    my $previous = select CAPTURE;
    $n++;
    my $ok = eval "package Local::Synopsis$n; no strict 'vars'; $code; 1";
    my $error = $@;
    select $previous;
    my $text = $$printed;
    undef $printed;
    untie *CAPTURE;
    return ($ok, $error, $text);
}

sub claims_in {
    my ($code) = @_;
    my (@claims, $printing);
    for my $line (split /\n/, $code) {
        my ($said) = $line =~ /\s#\s+(.*?)\s*\z/;
        if ($line =~ /\A\s*print\b/) {
            $printing = !defined $said;
            push @claims, $said if defined $said;
        }
        elsif ($printing && defined $said && $line =~ /\A\s*#/) {
            push @claims, $said;
            $printing = 0;
        }
        else {
            $printing = 0;
        }
    }
    return @claims;
}

sub in_order {
    my ($said, @claims) = @_;
    my @lines = split /\n/, $said;
    for my $claim (@claims) {
        shift @lines while @lines && $lines[0] ne $claim;
        return $claim unless @lines;
        shift @lines;
    }
    return undef;
}

my $START = 'dldldldldl/........../.......... l 5';
my $OVER = 'my $game = Game::Senet->new(seed => \'any bytes at all\'); '
         . '$game->play(($game->legal)[0]) until $game->is_over;';

my %CLAIMS = ('Game::Senet::Engine' => 3, 'Game::Senet::Notation' => 3, 'Game::Senet::Variant' => 3);

my @SYNOPSES = (
    [ 'Game::Senet', '', '',
        [ qr/^light threw [01]{4}, worth [1-5]$/m, qr/^(?:light|dark) won$/m ] ],
    [ 'Game::Senet::Bot', '', 'print "over, @levels\n" if $game->is_over;',
        [ qr/^over, 1 2 3$/m ] ],
    [ 'Game::Senet::Engine', '', 'print "$h\n", defined $other ? "parsed\n" : "not parsed: $err\n";',
        [ "$START\n0000000000066666\nmarked\noff\n20\nparsed\n" ] ],
    [ 'Game::Senet::Error', 'my $game = Game::Senet->new(seed => \'any bytes at all\');', '',
        [ qr/\Ano_piece: \S.*\n\z/ ] ],
    [ 'Game::Senet::Move', "my \$board = Game::Senet::Engine->new(position => '$START');", '',
        [ qr/\A(?:light from \d+ to \d+(?:, swapping)?\n)+\z/ ] ],
    [ 'Game::Senet::Notation', 'my $text = Game::Senet->new(seed => \'any bytes at all\')->to_text;',
        'print "$move->{from} $move->{to}\n";',
        [ qr/\A12-15\n2: 22-20<x\n4: -\+\n\[variant kendall [^\n]*\]\n.*^12 15\n\z/ms ] ],
    [ 'Game::Senet::Result', $OVER, '',
        [ qr/\A(?:light|dark) won by \w+\n\z/ ] ],
    [ 'Game::Senet::Rules', '', '',
        [ qr/\A(?:light|dark) to move\n\z/ ] ],
    [ 'Game::Senet::Sticks', '', 'print "@$sticks $throw $roll $again\n";',
        [ "1 1 1 0 3 3 3\n" ] ],
    [ 'Game::Senet::Variant', '', '',
        [ "kendall\nkendall pieces=7\nwalk\n" ] ],
);

for my $row (@SYNOPSES) {
    my ($module, $before, $after, $wants) = @$row;
    subtest $module => sub {
        my $code = synopsis_of($module);
        ok(defined $code && $code =~ /\S/, 'it has a synopsis');
        my ($ok, $error, $said) = run_capturing("$before\n$code\n$after");
        ok($ok, 'the synopsis runs, as it is written') or diag($error);
        my @claims = claims_in($code);
        my $missing = in_order($said, @claims);
        ok(!defined $missing, scalar(@claims) . ' values its comments promise, printed in order')
            or diag("never printed: $missing");
        cmp_ok(scalar @claims, '==', $CLAIMS{$module} // 0, '  as many as the synopsis has');
        for my $want (@$wants) {
            ref $want ? like($said, $want, 'it prints what it says it does')
                      : is($said, $want, 'it prints this and nothing else');
        }
        my (undef, undef, $again) = run_capturing("$before\n$code\n$after");
        is($again, $said, 'and run twice it prints the same: the seed is in it');
    };
}

subtest 'Game::Senet::Terminal' => sub {
    my $code = synopsis_of('Game::Senet::Terminal');
    ok(defined $code && $code =~ /->run\(\@ARGV\)/, 'it has a synopsis, and it runs the program');
    local @ARGV = ('--version');
    $exited = undef;
    my ($ok, $error, $said) = run_capturing($code);
    is($error, "exit was called\n", 'the first line runs and leaves through exit, as a program does');
    is($exited, 0, '  with 0');
    like($said, qr/\Asenet \d+\.\d+\n\z/, '  having done what --version asks');
    ok(eval("package Local::Compiled; no strict 'vars'; my \$compiled = sub { $code }; 1"), 'and the whole of it compiles')
        or diag($@);
};

done_testing();
