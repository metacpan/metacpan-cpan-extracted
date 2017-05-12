package Message::SmartMerge::Test;
$Message::SmartMerge::Test::VERSION = '1.161240';
use strict;use warnings;
use Message::Match qw(mmatch);
use Message::SmartMerge;
use Test::More;

=head2 get_global_message
=cut
sub get_global_message {
    return shift @Message::SmartMerge::return_messages;
}

=head2 mergetest
=cut
sub mergetest {
    my %args = @_;
    eval {
        $args{run}->() or die "returned false\n";
    };
    ok not $@;
    foreach my $match_message (@{$args{match_messages}}) {
        my $return_message = shift @Message::SmartMerge::return_messages;
        ok $return_message;
        ok mmatch $return_message, $match_message;
    }
    ok not scalar @Message::SmartMerge::return_messages;

    @Message::SmartMerge::return_messages = ();
}
1;
