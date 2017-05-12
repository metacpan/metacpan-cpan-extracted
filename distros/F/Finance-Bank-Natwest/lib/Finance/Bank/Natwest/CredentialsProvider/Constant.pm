package Finance::Bank::Natwest::CredentialsProvider::Constant;

use Carp;

use vars qw( $VERSION );
$VERSION = '0.03';

=head1 NAME

Finance::Bank::Natwest::CredentialsProvider::Constant - Static credentials provider

=head1 DESCRIPTION

CredentialsProvider module for static credentials.

=head1 SYNOPSIS

  my $credentials = Finance::Bank::Natwest::CredentialsProvider::Constant->new(
     dob => '010179', uid => '0001', password => 'Password', pin => '4321'
  );

=head1 METHODS

=over 4

=item B<new>

  my $credentials = Finance::Bank::Natwest::CredentialsProvider::Constant->new(
     dob => '010179', uid => '0001', password => 'Password', pin => '4321'
  );

  # Or we can combine the dob and uid together
  my $credentials = Finance::Bank::Natwest::CredentialsProvider::Constant->new(
     customer_no => '0101790001', password => 'Password', pin => '4321'
  );


All the parameters are mandatory in both forms of the constructor.

=cut

sub new{
    my ($class, %opts) = @_;
    my %creds;

    croak "Must not provide both a customer number and dob/uid combo, stopped" if
        exists $opts{customer_no} and (exists $opts{dob} or exists $opts{uid});

    if (exists $opts{customer_no}) {
        croak "Customer number must be 10 digits, stopped" unless
            $opts{customer_no} =~ /^\d{10}$/;
        ($opts{dob}, $opts{uid}) = $opts{customer_no} =~ /(\d{6})(\d{4})/;
    }

    croak "Must provide a customer number or dob/uid combo, stopped" unless
        exists $opts{dob} and exists $opts{uid};

    croak "The dob must be 6 digits, stopped" unless
        $opts{dob} =~ /^\d{6}$/;
    croak "The uid must be 4 digits, stopped" unless
        $opts{uid} =~ /^\d{4}$/;

    croak "Must provide a password, stopped" unless
        exists $opts{password};
    croak "Must provide a pin, stopped" unless
        exists $opts{pin};

    croak "Password must be between 6 and 20 characters inclusive, stopped" if
        length $opts{password} < 6 or length $opts{password} > 20;

    croak "The pin must be 4 digits, stopped" unless
        $opts{pin} =~ /^\d{4}$/;

    return bless { creds => { dob => $opts{dob},
                              uid => $opts{uid},
                              password => [split/ */, $opts{password}],
                              pin => [split/ */, $opts{pin}]
                            } 
                 }, $class;
}

sub get_start{}
sub get_stop{}

sub get_identity{
    my ($self) = @_;

    return { uid => $self->{creds}{uid}, dob => $self->{creds}{dob} };
}

sub get_pinpass{
    my ($self, $digits, $chars) = @_;

    croak "Must pass in a ref to an array with required password chars" unless
        ref $chars eq "ARRAY";

    croak "Must pass in a ref to an array with required pin digits" unless
        ref $digits eq "ARRAY";

    return { password => [@{$self->{creds}{password}}[@$chars]],
                  pin => [@{$self->{creds}{pin}}[@$digits]] };
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
