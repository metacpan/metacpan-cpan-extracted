package Log::Saftpresse::Plugin::Role::Tracking;

use Moose::Role;

our $VERSION = '1.6'; # VERSION
# ABSTRACT: role for plugins to implement transaction tracking

use Log::Saftpresse::Log4perl;
use UUID;

sub set_tracking_id {
  my ( $self, $by, $stash, $notes, $key ) = @_;
  if( ! defined $key ) {
    $key = $stash->{$by};
  }
  if( ! defined $key ) { return; }
  my $id = $stash->{'tracking_id'};
  if( ! defined $id ) { return; }

  $notes->set("tracking-$by-$key", $id);
  $log->debug("assigned existing tracking_id for $by-$key");

  return;
}

sub get_tracking_id {
  my ( $self, $by, $stash, $notes, $key ) = @_;
  if( ! defined $key ) {
    $key = $stash->{$by};
  }
  if( ! defined $key ) { return; }

  my $id = $notes->get("tracking-$by-$key");
  if( defined $id ) {
    $stash->{'tracking_id'} = $id;
    $log->debug("found existing tracking_id found for $by-$key");
  } else {
    $log->debug("no tracking_id found for $by-$key");
  }

  return;
}

sub clear_tracking_id {
  my ( $self, $by, $stash, $notes ) = @_;
  my $key = $stash->{$by};
  if( ! defined $key ) { return; }

  $notes->remove("tracking-$by-$key");
  $log->debug("cleared tracking_id for $by-$key");
  return;
}

sub new_tracking_id {
  my ( $self, $stash, $notes ) = @_;

  if( defined $stash->{'pid'} ) {
    # rt.cpan.org #114390
    # requires UUID >=0.06:
    # my $id = UUID::uuid;
    # this will work with UUID < 0.06:
    my ( $uuid, $id );
    UUID::generate( $uuid ); UUID::unparse( $uuid, $id );

    $stash->{'tracking_id'} = $id;
    $notes->set('tracking-pid-'.$stash->{'pid'}, $id);
    $log->debug('generated tracking_id for pid-'.$stash->{'pid'});
  }

  return;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Saftpresse::Plugin::Role::Tracking - role for plugins to implement transaction tracking

=head1 VERSION

version 1.6

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998 by James S. Seymour, 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
