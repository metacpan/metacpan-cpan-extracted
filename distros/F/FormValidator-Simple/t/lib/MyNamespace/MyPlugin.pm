package MyNamespace::MyPlugin;
use strict;
use FormValidator::Simple::Constants;

sub MYPLUGIN {
    my ($class, $params, $args) = @_;
    my $data = $params->[0];
    return $data =~ /myplugin/ ? TRUE : FALSE;
}

1;
