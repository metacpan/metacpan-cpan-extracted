
=head1 NAME

JSON::Streaming::Reader::TestUtil - Utility functions for the JSON::Streaming::Reader test suite

=head1 DESCRIPTION

This package contains some utility functions for use in the test suite for L<JSON::Streaming::Reader>.
It's not useful outside of this context.

=cut

package JSON::Streaming::Reader::TestUtil;

use JSON::Streaming::Reader;
use Test::More;

use base qw(Exporter);
our @EXPORT = qw(test_parse compare_event_parse);

sub test_parse {
    my ($name, $input, $expected_tokens) = @_;

    my $jsonw = JSON::Streaming::Reader->for_string($input);
    my @tokens = ();

    while (my $token = $jsonw->get_token()) {
        push @tokens, $token;
    }

    is_deeply(\@tokens, $expected_tokens, $name);
}

sub compare_event_parse {
    my (@chunks) = @_;

    # First do a normal callback-based parse
    # to tell us what the result should be.
    # This assumes that the callback API is
    # functioning correctly, but we test that
    # separately so we can be reasonably sure
    # that it is.

    my ($callback_callbacks, $callback_tokens) = test_callbacks();
    my $jsonw = JSON::Streaming::Reader->for_string(join('', @chunks));

    $jsonw->process_tokens(%$callback_callbacks);

    # Now we do an event-driven parse.

    my ($event_callbacks, $event_tokens) = test_callbacks();
    $jsonw = JSON::Streaming::Reader->event_based(%$event_callbacks);

    foreach my $chunk (@chunks) {
        $jsonw->feed_buffer(\$chunk);
    }
    $jsonw->signal_eof();

    my $name = join('|', '', @chunks, '');

    #use Data::Dumper;
    #print STDERR Data::Dumper::Dumper($callback_tokens, $event_tokens);

    is_deeply($callback_tokens, $event_tokens, $name);
}

sub test_callbacks {

    my %callbacks = ();
    my @tokens = ();

    foreach my $callback_name (qw(start_object end_object start_array end_array start_property end_property add_string add_number add_boolean add_null error)) {
        $callbacks{$callback_name} = sub {
            push @tokens, [ $callback_name, @_ ];
        };
    }

    $callbacks{eof} = sub {};

    return \%callbacks, \@tokens;
}

1;
