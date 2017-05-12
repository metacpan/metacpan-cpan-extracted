=head1 NAME

DynGig::RCE::Access - Process access policy for RCE server

=cut
package DynGig::RCE::Access;

use warnings;
use strict;
use Carp;

use YAML::XS;

=head1 SYNOPSIS

 use DynGig::RCE::Access;

 my $access = DynGig::RCE::Access->new( $access_file );

 my @code_names = $access->names();

 my $id = $access->getid( $code_name, $user_name );

=cut
sub new
{
    my ( $class, $file ) = @_;
    my $error = 'invalid definition';
    my $this = eval { YAML::XS::LoadFile( $file ) };
    my ( %id, %uid, %gid );

    croak $@ || $error unless $this && ref $this eq 'HASH' && %$this;

    for my $name ( keys %$this )
    {
        my $user = $this->{$name};

        croak "$error '$name'" unless $user && ref $user eq 'ARRAY' && @$user;

        for my $user ( @$user )
        {
            next if defined $id{$user};

            my @user = split ':', $user, 2;

            croak "invalid user '$user[0]'" unless defined $uid{ $user[0] }
                || defined ( $uid{ $user[0] } = getpwnam $user[0] );

            croak "invalid group '$user[1]'"
                unless @user == 1 || ( defined $gid{ $user[1] }
                    || defined ( $gid{ $user[1] } = getgrnam $user[1] ) );

            $id{$user}[0] = $uid{ shift @user }; 
            $id{$user}[1] = $gid{ shift @user } if @user;
        }

        $this->{$name} = +{ map { $_ => $id{$_} } @$user };
    }

    bless $this, ref $class || $class;
}

sub names
{
    my $this = shift;
    my @name = keys %$this;

    return wantarray ? @name : \@name;
}

sub getid
{
    my ( $this, $name, $user ) = @_;

    return defined $name && defined $user && $this->{$name}
        ? $this->{$name}{$user} : undef;
}

=head1 NOTE

See DynGig::RCE

=cut

1;

__END__
