package Finance::Bank::FI::ReferenceNumber;
BEGIN {
  $Finance::Bank::FI::ReferenceNumber::AUTHORITY = 'cpan:OKKO';
}
$Finance::Bank::FI::ReferenceNumber::VERSION = '0.004';
use Moose;
use namespace::autoclean;
use utf8;

has '_reference_number' => (is => 'rw', isa => 'Int');

=head1 NAME

Finance::Bank::FI::ReferenceNumber - Calculate Finnish bank payment reference number (viitenumero)

=head1 DESCRIPTION

Calculate Finnish bank payment reference number.
Laskee suomalaisen maksun viitenumeron.

=head1 SYNOPSIS

    #The number given in the argument must have a length of 3..19.
    my $ref = Finance::Bank::FI::ReferenceNumber->new('123');

    print "The reference number is " . $ref->get();

=cut

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    if ( @_ == 1 && !ref $_[0] ) {
	return $class->$orig( number => $_[0] );
    }
    else {
	return $class->$orig(@_);
    }
};

sub BUILD {
    my $self = shift;
    my $args = shift;

    # Number is remittance info identifier, viitenumeron runko-osa in Finnish. 
    my $ref = $args->{number};

    my $refsum = 0;
    my $reffactor = 7;
    for(my $i=length($ref)-1; $i >= 0; $i--) {
	$_ = substr($ref,$i,1);
	$refsum += $_ * $reffactor;
	$reffactor = ($reffactor==7)?3:($reffactor==3)?1:7;
    }
    my $refcheck = ((10 - ($refsum % 10)) % 10);
    $ref .= $refcheck;

    $self->_reference_number($ref);
}

=head1 METHODS

=head2 get

    Returns the reference number consisting of the number given for new()
    concatenated with the calculated checksum number.

=cut

sub get {
    my $self = shift;
    return $self->_reference_number();
}

=head1 BUGS

Accepts numbers shorter than 3 digits in new().
Accepts numbers longer than 19 digits in new().

=head1 AUTHOR

Panu Ervamaa <pnu@cpan.org>

Oskari Ojala <okko@cpan.org>

=head1 COPYRIGHT & LICENSE

Copyright 2011-2012 the above author(s).

This sofware is free software, and is licensed under the same terms as perl itself.

=cut


__PACKAGE__->meta->make_immutable;

1;
