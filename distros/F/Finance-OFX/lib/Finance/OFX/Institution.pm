# Filename: Institution.pm
#
# Class interface for an OFX financial institution
# http://www.ofx.net/
# 
# Created January 30, 2008  Brandon Fosdick <bfoz@bfoz.net>
#
# Copyright 2008 Brandon Fosdick <bfoz@bfoz.net> (BSD License)
#
# $Id: Institution.pm,v 1.2 2008/03/04 04:22:27 bfoz Exp $

package Finance::OFX::Institution;

use strict;
use warnings;

our $VERSION = '2';

use constant DEFAULT_OPTIONS =>
{
    'language'	    => 'ENG',
    'Date'	    => 28800,	# 1970-01-01
};

sub new
{
    my ($this, %options) = @_;
    my $class = ref($this) || $this;
    my $self = {};
    bless $self, $class;

    # Initialization
    $self->{ORG} = delete $options{ORG};
    $self->{FID} = delete $options{FID};
    $self->{URL} = delete $options{URL};
    $self->{Date} = delete $options{Date};
    $self->{language} = delete $options{language};

    # Defaults
    for( keys %{DEFAULT_OPTIONS()} )
    {
	$self->{$_} = DEFAULT_OPTIONS()->{$_} unless defined $self->{$_};
    }

    return $self;
}

sub date
{
    my $s = shift;
    $s->{Date} = shift if scalar @_;
    $s->{Date};
}

sub fid
{
    my $s = shift;
    $s->{FID} = shift if scalar @_; # Assign new value if an argument is given
    $s->{FID};			    # Return the stored value
}

sub language
{
    my $s = shift;
    $s->{language} = shift if scalar @_;
    $s->{language};
}

sub org
{
    my $s = shift;
    $s->{ORG} = shift if scalar @_; # Assign new value if an argument is given
    $s->{ORG};			    # Return the stored value
}

sub url
{
    my $s = shift;
    $s->{URL} = shift if scalar @_; # Assign new value if an argument is given
    $s->{URL};			    # Return the stored value
}

1;

__END__

=head1 NAME

Finance::OFX::Institution - Object representation of an Open Financial Exchange 
Financial Institution

=head1 SYNOPSIS

 use Finance::OFX::Institution
 
 my $fi = OFX::Institution->new(URL => $url);
 $fi->language($lang);
 $fi->org($org);

=head1 DESCRIPTION

C<Finance::OFX::Institution> encapsulates information about an OFX Financial 
Institution. 

=head1 CONSTRUCTOR

=over

=item $fi = Finance::OFX::Institution->new( %options )

Constructs a new C<Finance::OFX::Institution> object and returns it.
Key/value pair arguments may be provided to set up the initial state.
The following options are recognized:

   Key			Default
   -----------		--------------------
   Date			28800 (UNIX time for 1970-01-01)
   FID			undef
   language		ENG
   ORG			undef
   URL			undef

=back

=head1 ATTRIBUTES

=over

=item $fi->date

=item $fi->date( $fi )

Get/Set the last-update date of the Financial Institution information.

=item $fi->fid

=item $fi->fid( $fid )

Get/Set the Financial Institution's FID.

=item $fi->language

=item $fi->language( $user )

Get/Set the OFX language code.

=item $fi->org

=item $fi->org( $pass )

Get/Set the OFX organizaton code.

=item $fi->url

=item $fi->url( $pass )

Get/Set the URL for the Institution's OFX server.

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
