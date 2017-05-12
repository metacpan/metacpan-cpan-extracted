package HTTP::MobileAgent::Flash;
use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.20';
use 5.008001;

use HTTP::MobileAgent;
use HTTP::MobileAgent::Flash::DoCoMoFlashMap;
use HTTP::MobileAgent::Flash::EZWebFlashMap;
use HTTP::MobileAgent::Flash::SoftBankFlashMap;

use Carp;

use base qw(Class::Accessor);
__PACKAGE__->mk_ro_accessors(qw(max_file_size version width height));

sub import {
    my $class = shift;
    no strict 'refs';
    *{"HTTP\::MobileAgent\::flash"}       = \&_flash;
    *{"HTTP\::MobileAgent\::is_flash"}    = \&_is_flash;
}

sub _flash {
    my $self = shift;
    unless ($self->{flash}) {
        $self->{flash} = HTTP::MobileAgent::Flash->new($self);
    }
    return $self->{flash};
}

sub _is_flash {
    my $self = shift;
    return ($self->flash->version > 0)? 1 : 0;
}

sub new {
    my ($class, $agent) = @_;

    my $map;
    if ($agent->is_docomo) {
        $map = $HTTP::MobileAgent::Flash::DoCoMoFlashMap::FLASH_MAP->{uc($agent->model)};
    }
    elsif ($agent->is_ezweb) {
        $map = $HTTP::MobileAgent::Flash::EZWebFlashMap::FLASH_MAP->{uc($agent->model)};
    }
    elsif ($agent->is_softbank) {
        $map = $HTTP::MobileAgent::Flash::SoftBankFlashMap::FLASH_MAP->{uc($agent->model)};
    }

    if ($map) {
        return bless $map, $class;
    }
    else {
        return bless {
            max_file_size => -1,
            version       => -1,
            width         => -1,
            height        => -1,
        }, $class;
    }
}

sub is_supported {
    my $self = shift;
    my $version = shift || "";

    croak "You must set version before call is_supported()" if ($version eq "");

    $version =~ s/Lite//ig;
    return ($version <= $self->version)? 1 : 0;
}

1;
__END__

=head1 NAME

HTTP::MobileAgent::Flash - Flash information for HTTP::MobileAgent

=head1 SYNOPSIS

  use HTTP::MobileAgent;
  use HTTP::MobileAgent::Flash;


  my $agent = HTTP::MobileAgent->new;
  print "Flash Version : " . $agent->flash->version;

  if ($agent->is_flash )   { ...... }
  
  if ($agent->flash->is_supported('lite1.1') and $agent->flash->width <= 230) {
    :
  }
  if ($agent->flash->is_supported('lite1.0') and $agent->flash->max_file_size <= 48) {
    :
  }

=head1 DESCRIPTION

This module adds C<flash>, C<is_flash> method to HTTP::MobileAgent

=head1 METHODS

=head2 is_flash

=head2 flash

=item version

=item max_file_size

=item is_supported

  $agent->flash->is_supported('Lite1.1')
  $agent->flash->is_supported('Lite1.0')

=head1 AUTHOR

KIMURA, takefumi E<lt>takefumi@mobilefactory.jpE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 BUGS

This module does not support the Vodafone, yet.

=head1 SEE ALSO

L<HTTP::MobileAgent>,
L<http://www.nttdocomo.co.jp/service/imode/make/content/spec/flash/index.html>,
L<http://www.au.kddi.com/ezfactory/mm/flash01.html>,
L<http://creation.mb.softbank.jp/>

=cut
