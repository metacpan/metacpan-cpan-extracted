package Kelp::Module::Bcrypt;

use Kelp::Base 'Kelp::Module';
use Crypt::Eksblowfish::Bcrypt qw(bcrypt_hash en_base64);

our $VERSION = 0.2;

sub build {
    my ( $self, %args ) = @_;

    if ( !$args{salt} ) {
        die "Must define salt for bcrypt";
    }

    $self->register(
        bcrypt => sub {
            my ( $app, $password ) = @_;
            my $hash = bcrypt_hash(
                {
                    key_nul => 1,
                    cost    => $args{cost} // 8,
                    salt    => $args{salt},
                },
                $password
            );
            return en_base64($hash);
        }
    );
}

1;

__END__

=pod

=head1 TITLE

Kelp::Module::Bcrypt - Bcrypt your passwords

=head1 SYNOPSIS

    # conf/config.pl
    {
        modules_init => {
            Bcrypt => {
                cost => 6,
                salt => 'secret salt passphrase'
            }
        };
    };

    # lib/MyApp.pm
    ...

      sub some_soute {
        my $self             = shift;
        my $crypted_password = $self->bcrypt($plain_password);
    }

    sub another_route {    # Maybe a bridge?
        my $self = shift;
        if ( $self->bcrypt($plain_password) eq $crypted_passwrod ) {
            ...;
        }
    }

=head1 TITLE

This module adds bcrypt to your Kelp app

=head1 REGISTERED METHODS

=head2 bcrypt( $text )

Returns the bcrypted C<$text>.

=head1 AUTHOR

Stefan G - mimimal E<lt>atE<lt> cpan.org


=head1 SEE ALSO

L<Kelp>, L<Crypt::Eksblowfish::Bcrypt>

=head1 LICENSE

Perl

=cut
