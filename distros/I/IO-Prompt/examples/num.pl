use IO::Prompt;

# You can constrain input to be numeric, or even integral...

my $how_many = prompt -number => 'How many? ';
print "You asked for $how_many\n";

$how_many = prompt -i => 'How many? ';
print "You asked for $how_many\n";
