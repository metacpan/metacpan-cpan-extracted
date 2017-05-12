package Business::FedEx;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(set_err) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();
our $VERSION = '0.10';

sub new {
  my $proto = shift;
  my $class = ref $proto || $proto;
  my %args = (@_);
  return bless \%args, $class;
}

sub set_err {
  my $self = shift;
  my $err = shift;
  my $errstr = shift;

  $self->{'Err'} = $err;
  $self->{'Errstr'} = $errstr;

  #always return undef so you could do:
  # $object->whatever or return $object->set_error(0, "Error!");
  return undef;
}

sub errstr { return shift->{'Errstr'} }
sub err    { return shift->{'Err'}    }

1;

__END__

=head1 NAME

Fedex - Win32 API Extension for FedEx ShipAPI

=head1 SYNOPSIS

  use Fedex;

=head1 DESCRIPTION

Stub documentation for Fedex, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.  Yes he was.

=head2 EXPORT

None by default.


=head1 AUTHOR

Alex Schmelkin, alex@davanita.com

=head1 SEE ALSO

perl(1).

=cut
