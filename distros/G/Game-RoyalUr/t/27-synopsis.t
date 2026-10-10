use strict;
use warnings;
use Test::More;

use Game::RoyalUr;

# THE SYNOPSIS RUNS. The first code a reader sees is taken out of the
# documentation of the module that was loaded, and run as it is written. If
# it does not compile, or dies, or the game it plays does not end, this file
# says so; a synopsis that only looks right is the commonest lie a README
# tells.
{
    package Local::Capture;
    sub TIEHANDLE { my $text = ''; return bless \$text, shift }
    sub PRINT     { my $self = shift; $$self .= join '', @_; return 1 }
    sub PRINTF    { my $self = shift; $$self .= sprintf shift, @_; return 1 }
}

sub synopsis_of {
    my ($file) = @_;
    open my $in, '<', $file or die "cannot read $file: $!";
    my $pod = do { local $/; <$in> };
    close $in;
    my ($section) = $pod =~ /^=head1 SYNOPSIS\n(.*?)^=head1 /ms or return undef;
    return join '', grep { /\A(?:    |\n)/ } split /^/m, $section;
}

sub run_capturing {
    my ($code) = @_;
    my $printed = tie *CAPTURE, 'Local::Capture';
    my $previous = select CAPTURE;
    my $ok = eval "package Local::Synopsis; $code; 1";
    my $error = $@;
    select $previous;
    my $text = $$printed;
    undef $printed;
    untie *CAPTURE;
    return ($ok, $error, $text);
}

my $file = $INC{'Game/RoyalUr.pm'};
ok(defined $file && -f $file, 'the module that was loaded is a file that can be read');

my $code = synopsis_of($file);
ok(defined $code && $code =~ /Game::RoyalUr->new/, 'it has a synopsis, and the synopsis makes a game');

my ($ok, $error, $said) = run_capturing($code);
ok($ok, 'the synopsis runs, as it is written') or diag($error);
like($said, qr/^(?:light|dark) rolled [1-4]$/m, 'it says who rolled what');
like($said, qr/^(?:light|dark) wins by home$/m, 'it plays a whole game and says who won');
like($said, qr/\[rules finkel\]\n\[first (?:light|dark)\]\n\[seed [0-9a-f]+\]/, 'and it prints the record of it');

my ($again_ok, undef, $again) = run_capturing($code);
is($again, $said, 'run twice, it is the same game: the seed is in the synopsis');

done_testing();
