use strict;
use warnings;

use Geo::BUFR;

# Versions before 1.39 had 3 more tests for reusing current ahl

Geo::BUFR->set_tablepath('t/bt');

my $bufr = Geo::BUFR->new();
$bufr->fopen('t/set_filter.bufr');

print "Filtering CCCC=TEST, data category not 2\n";
$bufr->set_filter_cb(\&callback,2,qw(TEST));
decode($bufr);

print "\nFiltering CCCC=TEST, data category not 0\n";
$bufr->rewind();
$bufr->set_filter_cb(\&callback,0,qw(TEST));
decode($bufr);

print "\nFiltering CCCC=TEST|SVVS, data category not 0\n";
$bufr->rewind();
$bufr->set_filter_cb(\&callback,0,qw(TEST SVVS));
decode($bufr);

sub decode {
    my $bufr = shift;

    while (not $bufr->eof()) {
        my ($data, $descriptors);
        eval {
            ($data, $descriptors) = $bufr->next_observation();
        };
        if ($@) {
            my $current_message_number = $bufr->get_current_message_number();
            my $current_ahl = $bufr->get_current_ahl() || '';
            print "  Error at message $current_message_number with AHL [$current_ahl]\n";
            next;
        } else {
            my $current_message_number = $bufr->get_current_message_number();
            my $current_subset_number = $bufr->get_current_subset_number();
            my $current_ahl = $bufr->get_current_ahl() || '';
            # Use 'next', not 'last' since message could be a 0 subset
            # message that is filtered
            next if $current_subset_number == 0;
            if ($bufr->is_filtered()) {
                print "  is_filtered $current_message_number $current_ahl\n";
            }

            next if !$data;
#           my $decoded_msg = $bufr->dumpsections($data, $descriptors, {width => 20});
            print "  $current_message_number $current_ahl\n";
        }
    }
}

sub callback {
    my $obj = shift;
    my $data_category_to_keep = shift;
    my @CCCC_to_avoid = @_;

    return 1 if $obj->get_data_category != $data_category_to_keep;

    my $ahl = $obj->get_current_ahl();
    my $CCCC = defined $ahl ? substr($ahl,7,4) : '';
    return 1 if $CCCC && grep { $_ eq $CCCC } @CCCC_to_avoid;

    return;
}
