package FormValidator::Simple::Plugin::Sample;
use strict;
use FormValidator::Simple::Constants;

sub SAMPLE {
    my ($class, $params, $args) = @_;
    my $data = $params->[0];
    return $data =~ /sample/ ? TRUE : FALSE;
}

1;
