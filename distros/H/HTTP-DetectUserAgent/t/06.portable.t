use strict;
use warnings;
use Test::Base;
use HTTP::DetectUserAgent;
use YAML 0.83;

plan tests =>  (4 * blocks);

filters {
    input    => [qw(chomp)],
    expected => [qw(yaml)],
};

run {
    my $block = shift;
    my $ua = HTTP::DetectUserAgent->new($block->input);
    my $expected = $block->expected;
    is $ua->type, "Browser";
    is $ua->name, $expected->{name};
    is $ua->version, $expected->{version};
    is $ua->vendor, $expected->{vendor};
}

__END__

=== PSP
--- input
Mozilla/4.0 (PSP (PlayStation Portable); 2.00)
--- expected
name: "PSP"
version: "2.00"
vendor: "Sony"

=== PSP
--- input
Mozilla/4.0 (PSP (PlayStation Portable))
--- expected
name: "PSP"
version: "Unknown"
vendor: "Sony"

=== Playstation 3
--- input
Mozilla/5.0 (PLAYSTATION 3; 1.00)
--- expected
name: "Playstation 3"
version: "1.00"
vendor: "Sony"
