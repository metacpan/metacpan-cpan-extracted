package Ekahau::License;
use Ekahau::Base; our $VERSION=$Ekahau::Base::VERSION;
use base 'Ekahau::ErrHandler';

# Written by Scott Gifford <gifford@umich.edu>
# Copyright (C) 2004 The Regents of the University of Michigan.
# See the file LICENSE included with the distribution for license
# information.

use strict;
use warnings;

=head1 NAME

Ekahau::License - Internal module used to parse and handle Ekahau license files.

=head1 SYNOPSIS

This module is used internally by the L<Ekahau::Base|Ekahau::Base> class; you
shouldn't need to use it directly.  It provides an interface to handle
Ekahau license files, and perform a few simple operations that are
necessary for a licensed authentication to an Ekahau server.

=head1 DESCRIPTION

=cut

use XML::Simple;
use Digest::MD5 qw(md5_hex);

=head2 Constructor

=head3 new ( %params )

Creates a new object with the given parameters, in a C<Param => Value>
style list.  The only parameter recognized is C<LicenseFile>, which
gives the path to an Ekahau license file.

=cut

sub new
{
    my $class = shift;
    my(%p)=@_;

    my $self = {};
    bless $self, $class;
    $self->{_errhandler} = Ekahau::ErrHandler->errhandler_new($class,%p);
    
    $self->{LicenseFile}=$p{LicenseFile}
        or return $self->reterr("No LicenseFile specified");
    $self->{_license} = XMLin($self->{LicenseFile})
	or return $self->reterr("Couldn't parse license file");

    $self->errhandler_constructed();
}

sub ERROBJ
{
    my $self = shift;
    $self->{_errhandler};
}

=head2 Methods

=head3 hello_str

Generate a string suitable for an Ekahau YAX C<HELLO> authentication
step.

=cut

sub hello_str
{
  my $self = shift;

  join(" ", map { "$_=$self->{_license}{mandate}{claim}{$_}{value}" } keys %{$self->{_license}{mandate}{claim}});
}

=head3 talk_str ( %params )

Generating a string suitable for an Ekahau YAX C<TALK> authentication
command.  This method accepts three parameters, in a C<Param => Value>
style list:

=over 4

=item Password

Password to connect to Ekahau server

=item HelloStr

String received from the YAX server in a C<HELLO> message.

=back

C<HelloStr> is required; C<Password> defaults to the default Ekahau
password.

=cut

sub talk_str
{
  my $self = shift;
  my(%p)=@_;

  
  defined($p{HelloStr})
      or return $self->reterr("talk_str method requires HelloStr argument");
  defined($self->{_license}{mandate}{checksum})
      or return $self->reterr("Couldn't find mandate checksum in Ekahau license");
  defined($p{Password}) or $p{Password} = 'Llama';

  my $str = join("",$p{HelloStr},$p{Password},$self->{_license}{mandate}{checksum});
  my $digest = md5_hex($str);
  $digest;
}

=head1 AUTHOR

Scott Gifford E<lt>gifford@umich.eduE<gt>, E<lt>sgifford@suspectclass.comE<gt>

Copyright (C) 2005 The Regents of the University of Michigan.

See the file LICENSE included with the distribution for license
information.


=head1 SEE ALSO

L<XML::Simple|XML::Simple>, L<Digest::MD5|Digest::MD5>, L<Ekahau::Base|Ekahau::Base>.

=cut

1;

