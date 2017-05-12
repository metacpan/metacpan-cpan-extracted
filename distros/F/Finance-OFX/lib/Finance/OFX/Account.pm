# Filename: Account.pm
#
# Class interface for an OFX account
# http://www.ofx.net/
# 
# Created February 11, 2008  Brandon Fosdick <bfoz@bfoz.net>
#
# Copyright 2008 Brandon Fosdick <bfoz@bfoz.net> (BSD License)
#
# $Id: Account.pm,v 1.2 2008/03/04 04:22:27 bfoz Exp $

package Finance::OFX::Account;

use strict;
use warnings;

our $VERSION = '2';

sub new
{
    my ($this, %options) = @_;
    my $class = ref($this) || $this;
    my $self = {};
    bless $self, $class;

    # Initialization
    $self->{Type} = delete $options{Type};
    $self->{ID} = delete $options{ID};
    $self->{FID} = delete $options{FID};

    return $self;
}

sub type
{
    my $s = shift;
    $s->{Type} = shift if scalar @_;
    $s->{Type};
}

sub fid
{
    my $s = shift;
    $s->{FID} = shift if scalar @_; # Assign new value if an argument is given
    $s->{FID};			    # Return the stored value
}

sub id
{
    my $s = shift;
    $s->{ID} = shift if scalar @_;
    $s->{ID};
}

sub bankacctfrom
{
    my $s = shift;
    '<BANKACCTFROM><BANKID>'.$s->{FID}.
	'<ACCTID>'.$s->{ID}.
	'<ACCTTYPE>'.$s->{Type}.
    '</BANKACCTFROM>';
}

1;

__END__

=head1 NAME

Finance::OFX::Account - Object representation of an account at an Open 
Financial Exchange Financial Institution

=head1 SYNOPSIS

 use Finance::OFX::Account
 
 my $acct = OFX::Account->new(URL => $url);
 $acct->language($lang);
 $acct->org($org);

=head1 DESCRIPTION

C<Finance::OFX::Account> encapsulates information about an account held at an 
OFX Financial Institution. 

=head1 CONSTRUCTOR

=over

=item $acct = Finance::OFX::Account->new( %options )

Constructs a new C<Finance::OFX::Account> object and returns it.
Key/value pair arguments may be provided to set up the initial state.
The following options are recognized:

   Key			Default
   -----------		--------------------
   FID			undef
   ID			undef
   Type			undef

=back

=head1 ATTRIBUTES

=over

=item $acct->fid

=item $acct->fid( $fid )

Get/Set the Financial Institution's FID.

=item $acct->id

=item $acct->id( $id )

Get/Set the Account ID. Most people would call this an Account Number, but the 
OFX spec calls it an ID and treats it as a string.

=item $acct->type

=item $acct->type( $user )

Get/Set the account type.

=back

=head1 SEE ALSO

L<http://ofx.net>

=head1 WARNING

From C<Finance::Bank::LloydsTSB>:

This is code for B<online banking>, and that means B<your money>, and
that means B<BE CAREFUL>. You are encouraged, nay, expected, to audit
the source of this module yourself to reassure yourself that I am not
doing anything untoward with your banking data. This software is useful
to me, but is provided under B<NO GUARANTEE>, explicit or implied.

=head1 AUTHOR

Brandon Fosdick, E<lt>bfoz@bfoz.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Brandon Fosdick <bfoz@bfoz.net>

This software is provided under the terms of the BSD License.

=cut
