###############################################################################
# The receiver class can reshape the data at any given rule match.
###############################################################################
package JSONY::Receiver;
use base 'Pegex::Tree';
use boolean;

sub got_top_seq_entry { $_[1][0][0] }
sub got_top_map { $_[0]->got_map([$_[1]]) }
sub got_seq { $_[1]->[0] }
sub got_map { +{ map {($_->[0], $_->[1])} @{$_[1]->[0]} } }
sub got_string {"$_[1]"}
sub got_bare {
    $_ = pop;
    /^true$/ ? true :
    /^false$/ ? false :
    /^null$/ ? undef :
    /^(
        -?
        (?: 0 | [1-9] [0-9]* )
        (?: \. [0-9]* )?
        (?: [eE] [\-\+]? [0-9]+ )?
    )$/x ? ($_ + 0) :
    "$_"
}

1;
