package JLogger::Filter::FieldRegexp;

use strict;
use warnings;

use base 'JLogger::Filter';

sub new {
    my ($class, %atrs) = @_;

    foreach my $regexp (values %{$atrs{fields}}) {
        $regexp = qr($regexp);
    }

    $class->SUPER::new(%atrs);
}

sub filter {
    my ($self, $message) = @_;

    foreach my $key (keys %{$self->{fields}}) {
        my $regexp = $self->{fields}->{$key};
        if (exists $message->{$key} && $message->{$key} =~ $regexp) {
            return 0;
        }
    }

    1;
}

1;
