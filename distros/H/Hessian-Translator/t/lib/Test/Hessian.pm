package  Test::Hessian;

use strict;
use warnings;

use parent 'Test::Class';

use Test::More;
use Contextual::Return;
use Hessian::Translator;

__PACKAGE__->SKIP_CLASS(1);

sub compare_date {    #{{{
    my ( $self, $original_date, $processed_time ) = @_;
    my $cmp = DateTime->compare( $original_date, $processed_time );
    is( $cmp, 0, "Hessian date as expected." );
}

sub prep005_initialize_client : Test(startup) {    #{{{
    my $self = shift;
    my $version = $self->{version};
    my $client = Hessian::Translator->new( version => $version );
    $self->{client} = $client;
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


