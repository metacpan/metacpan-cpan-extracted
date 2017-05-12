package FormValidator::Nested;
use Any::Moose;
use namespace::clean -except => 'meta';
our $VERSION = '0.07';

use FormValidator::Nested::ProfileProvider;
use FormValidator::Nested::Messages::ja;

our $MESSAGES    = $FormValidator::Nested::Messages::ja::MESSAGES;

has 'profile_provider' => (
    is       => 'ro',
    isa      => 'FormValidator::Nested::ProfileProvider',
    required => 1,
    handles  => [qw/get_profile/],
);
__PACKAGE__->meta->make_immutable;

sub validate {
    my $self         = shift;
    my $req          = shift;
    my $profile_key  = shift;


    my $profile = $self->get_profile($profile_key);
    if ( !$profile ) {
        die("not found profile " . $profile_key);
    }
    return $profile->validate($req);
}

1;
__END__

=head1 NAME

FormValidator::Nested - form validation

=head1 SYNOPSIS

    use FormValidator::Nested;
    use Class::Param;

    my $req = Class::Param->new({ ... });
    my $fvt = FormValidator::Nested->new({
        profile_provider => FormValidator::Nested::ProfileProvider::YAML->new({
            dir => 't/var/profile',
        }),
    });
    my $res = $fvt->validate($req, 'login');
    if ( $res->has_error ) {
        my $error_param_ref = $res->error_params;
        while ( my ( $key, $error_params ) = %{$error_param_ref} ) {
            foreach my $error_param ( @{$error_params} ) {
                warn $error_param->msg;
            }
        }
    }

=head1 DESCRIPTION

FormValidator::Nested is form validation support nested parameter.

=head1 AUTHOR

Masahiro Chiba E<lt>nihen@megabbs.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
