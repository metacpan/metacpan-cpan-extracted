use 5.010;
use warnings;
use Test::More;

use IO::Prompter;

# Should we test at all???
if (!-t *STDIN || !-t *STDERR) {
    plan('skip_all' => 'Non-interactive test environment');
    exit;
}
elsif ($^O =~ /Win/) {
    plan('skip_all' => 'Skipping interactive tests under Windows');
}
elsif (!eval { require Term::ReadKey }) {
    plan('skip_all' => 'Term::ReadKey not available');
    exit;
}
else {
    plan('no_plan');
}
select *STDERR;
say {STDERR} q{};

# Remember the test results...
my %ok;

# Load sample display styles to test...
chomp(my @styles = <DATA>);

# Test styled prompts...
for my $style_spec (@styles) {
    # Show the styled text and ask if it's correct...
    my $result = prompt "\tIs this $style_spec?",
                        -yn1,
                        -style=>[$style_spec],
                        -echo=>sub{ /y/i ? 'yes, it is' : "no, it isn't" };

    # Record the result...
    push @results, {test=>$style_spec, outcome=>$result};
}

# Test styled responses...
{
    # Ask for an initial response...
    my $last_style = $styles[0];
    scalar prompt -echostyle=>$last_style, "\tType in something:";

    # Check the colour of the previous response...
    for my $style_spec (@styles[1..$#styles], q{}) {
        my $result = prompt -yn1, -echostyle=>$style_spec,
                            -echo=>sub{ /y/i ? 'yes, it was' : "no, it wasn't"; },
                            "\tWas your previous input displayed in $last_style?";
        push @results, {test=>$last_style, outcome=>$result};
        $last_style = $style_spec;
    }
}

# Test the "yes" half of yes/no shortcuts...
scalar prompt -yn1, -echo=>'yes/no', -echostyle=>'cyan/red', "Is 1 an odd number?";
my $result = prompt -yn1, 'Was the previous "yes" input echoed in cyan?';
push @results, {test=>'Yes --> cyan', outcome=>$result};

# Test the "no" half of the yes/no shortcuts...
scalar prompt -yn1, -echo=>'yes/no', -echostyle=>'cyan/red', "Is 2 an odd number?";
$result = prompt -yn1, 'Was the previous "no" input echoed in red?';
push @results, {test=>'No --> red', outcome=>$result};

# Report the results...
for my $result (@results) {
    ok $result->{outcome} => $result->{test};
}

__DATA__
red
murky green
blue
black on cyan
bold green
inverse
underscored yellow
blinking purple
strong crimson on a background of gold
