use v5.44;
use LibTmux::Filter;

# example: begin records
my $filter = LibTmux::Filter->new(
    entity => 'pane',
    where  => {
        active          => true,
        current_command => {-in  => [qw(perl vim)]},
        width           => {-gte => 80},
    },
);
my @records = (
    {id => '%1', active => true,  current_command => 'perl', width => 120},
    {id => '%2', active => false, current_command => 'perl', width => 120},
    {id => '%3', active => true,  current_command => 'vim',  width => 40},
);
my @matches = grep { $filter->matches($_) } @records;
say 'matching records: ', join ', ', map { $_->{id} } @matches;

# example: end records
die 'unexpected record matches' unless @matches == 1 && $matches[0]{id} eq '%1';
my $restored = LibTmux::Filter->from_json($filter->to_json);
die 'wire filter changed meaning' unless $restored->matches($records[0]);

# example: begin invalid
try {
    LibTmux::Filter->new(
        entity => 'pane',
        where  => {width => {-gte => 'wide'}}
    );
    die 'invalid numeric operand was accepted';
}
catch ($error) {
    die $error unless $error isa LibTmux::X::InvalidFilter;
    say 'invalid operand at ', $error->path;
    say 'expected: ',          $error->expected;
}

# example: end invalid
say 'filter records and wire: ok';
