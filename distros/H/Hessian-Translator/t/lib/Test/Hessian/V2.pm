package  Test::Hessian::V2;

use strict;
use warnings;

use parent 'Test::Hessian';

use YAML;
use Test::More;
use Test::Deep;
use Test::Exception;
use Hessian::Translator::V2;

sub prep001_version : Test(startup) {    #{{{
    my $self = shift;
    $self->{version} = 2;
}

sub t006_compose_version : Test(1) {    #{{{
    my $self   = shift;
    my $client = $self->{client};
    lives_ok {
        Hessian::Translator::V2->meta()->apply($client);
    }
    'Version role has been composed.';

}

"one, but we're not the same";

__END__


=head1 NAME

Communication::v1Serialization - Test serialization of Hessian version 1
messages.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


