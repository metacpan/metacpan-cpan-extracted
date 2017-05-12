#!/home/ben/software/install/bin/perl
use warnings;
use strict;
# Make a table.
use HTML::Make;
my $table = HTML::Make->new ('table');
# Can add elements as text
$table->add_text ('<tr><th>Item<th>Cost');
my %items = (
    compressor => 12800,
    heater => 'free',
    camera => 1080,
);
for my $k (sort keys %items) {
    # Add an element using "push". The return value is the new element.
    my $tr = $table->push ('tr');
    # Can add element to $tr using "push"
    $tr->push ('td', text => $k);
    # Can also make a new element then "push" it.
    my $td = HTML::Make->new ('td', text => $items{$k},
			      attr => {style => 'padding:1em'});
    $tr->push ($td);
}
# Get the output
print $table->text ();
