use strict;
use warnings;
use Test::More;
use Games::Sudoku::CLI;

plan tests => 2;

my @input;
my @output;

no warnings 'redefine';
sub Games::Sudoku::CLI::print_as_grid {
    my ($self) = @_;
    push @output, $self->{ctrl}->table->as_string;
}

sub Games::Sudoku::CLI::msg {
    my ($self, $msg) = @_;
    push @output, $msg;
}

sub Games::Sudoku::CLI::prompt {
    my ($self, $msg) = @_;
    push @output, $msg;
}


sub Games::Sudoku::CLI::get_input {
    my ($self) = @_;
    $self->{input} = shift @input;
}

my @expected_intro = (
    'Welcome to CLI Sudoku version 0.02',
    'Would you like to start a new game, load saved game, or exit?',
    'Type in "n NUMBER" to start a new game with NUMBER empty slots',
    'Type in "l FILENAME" to load the file called FILENAME',
    'Type x to exit',
);
my $prompt = 'Enter your choice (row, col, value) or [q-quit game, x-exit app, h-hint]: ';

subtest 'immediate exit' => sub {
    @input = (
        'x',
    );
    @output = ();

    Games::Sudoku::CLI->new->play;
    #diag explain \@output;

    is_deeply \@output, [
        @expected_intro,
        'BYE BYE',
    ];
};


subtest 'load and exit' => sub {
    @input = (
        'l t/files/a.txt',
        '1,2,x',
        '1,1,7',
        '1,3,3',
        '1,3,4',
        'x',
    );
    @output = ();

    Games::Sudoku::CLI->new->play;
    #diag explain \@output;

    my $sudo_a = slurp('t/files/a.txt');
    chomp $sudo_a;

    my $sudo_a2 = $sudo_a;
    substr $sudo_a2, 4, 1, 4;

    is_deeply \@output, [
        @expected_intro,
        $sudo_a,
        $prompt,
        "Invalid format: '1,2,x'",
        $prompt,
        'Value 7 is not allowed in (1, 1)',
        $prompt,
        'Value 3 is not allowed in (1, 3)',
        $prompt,
        $sudo_a2,
        $prompt,
        'BYE',
    ];
};

sub slurp {
    my $file = shift;
    open my $fh, '<', $file or die;
    local $/ = undef;
    return scalar <$fh>;
}

