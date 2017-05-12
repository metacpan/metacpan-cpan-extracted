package FormValidator::Nested::Filter;
use Any::Moose;
use namespace::clean -except => 'meta';

use FormValidator::Nested::ProfileProvider;

use Class::Param;
use Carp;

has 'profile_provider' => (
    is       => 'ro',
    isa      => 'FormValidator::Nested::ProfileProvider',
    required => 1,
    handles  => [qw/get_profile/],
);
__PACKAGE__->meta->make_immutable;

sub filter {
    my $self         = shift;
    my $req          = shift;
    my $profile_key  = shift;

    my $hash = 0;
    if ( blessed($req) ) {
        if ( !$req->can('param') ) {
            croak("req cannot call param method.");
        }
    }
    elsif ( ref $req eq 'HASH' ) {
        $req = Class::Param->new($req);
        $hash = 1;
    }

    my $profile = $self->get_profile($profile_key);

    foreach my $param ( $profile->get_params ) {
        foreach my $filter ( $param->get_filters ) {
            my $values_ref = $param->get_values($req);
            $filter->process($req, $values_ref);
        }
    }

    if ( $hash ) {
        return $req->as_hash;
    }

    return $req;
}

1;
__END__
=head1 NAME

FormValidator::Nested::Filter - form filter

=head1 SYNOPSIS

    use FormValidator::Nested::Filter;
    use Class::Param;

    my $req = Class::Param->new({ ... });
    my $fvt = FormValidator::Nested::Filter->new({
        profile_provider => FormValidator::Nested::ProfileProvider::YAML->new({
            dir => 't/var/profile',
        }),
    });
    $req = $fvt->filter($req, 'login');

=head1 DESCRIPTION

FormValidator::Nested is form filter.

=head1 AUTHOR

Masahiro Chiba E<lt>nihen@megabbs.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
