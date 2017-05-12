package Finance::Bank::Natwest::CredentialsProvider::Callback;

use Carp;
use Finance::Bank::Natwest::CredentialsProvider::Constant;

use vars qw( $VERSION );
$VERSION = '0.03';

=head1 NAME

Finance::Bank::Natwest::CredentialsProvider::Callback - Credentials provider that uses a callback to gather the required information

=head1 DESCRIPTION

CredentialsProvider module that uses a callback to retrieve the credentials.

=head1 SYNOPSIS

  my $credentials = Finance::Bank::Natwest::CredentialsProvider::Callback->new(
     callback => \&credentials_callback
  );

=head1 METHODS

=over 4

=item B<new>

  my $credentials = Finance::Bank::Natwest::CredentialsProvider::Callback->new(
     callback => \&credentials_callback
  );

  # Or we can also provide an ID to pass into the callback routine
  my $credentials = Finance::Bank::Natwest::CredentialsProvider::Callback->new(
     callback => \&credentials_callback, id => 1
  );

If C<id> is provided then it must be a simple scalar, and not a reference.

=cut

sub new{
    my ($class, %opts) = @_;

    my $self = bless {}, $class;

    croak "Must provide a callback, stopped" unless
        exists $opts{callback};

    croak "Callback must be a code ref, stopped" unless
        ref $opts{callback} eq "CODE";

    $self->{callback} = $opts{callback};
    $self->{cache} = $opts{cache} || 0;

    croak "ID must be a simple scalar, stopped" if
        ref $opts{id};

    $self->{id} = $opts{id};

    return $self;
}

sub get_start{
    my ($self, %opts) = @_;

    croak "ID must be a simple scalar, stopped" if
        exists $opts{id} and ref $opts{id};
 
    $self->{id} = $opts{id} if
        exists $opts{id};

    { 
        no warnings 'uninitialized';
        local $Carp::CarpLevel = $Carp::CarpLevel + 1;
        if (!exists $self->{my_cache}{$self->{id}}) {
            $self->{my_cache}{$self->{id}} = 
                Finance::Bank::Natwest::CredentialsProvider::Constant->new(
                    %{$self->{callback}->($self->{id})});
        };
    }
}

sub get_stop{
    my ($self) = @_;

    { 
        no warnings 'uninitialized';
        local $Carp::CarpLevel = $Carp::CarpLevel + 1;
        delete $self->{my_cache}{$self->{id}} unless
            $self->{cache};
    };
}

sub get_identity{
    my ($self) = @_;

    {
        no warnings 'uninitialized';
        local $Carp::CarpLevel = $Carp::CarpLevel + 1;
        return $self->{my_cache}{$self->{id}}->get_identity();
    };
}

sub get_pinpass{
    my ($self, $chars, $digits) = @_;

    {
        no warnings 'uninitialized';
        local $Carp::CarpLevel = $Carp::CarpLevel + 1;
        return $self->{my_cache}{$self->{id}}->get_pinpass($chars, $digits);
    };
}

1;
__END__

=back

=head1 AUTHOR

Jody Belka C<knew@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Jody Belka

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
