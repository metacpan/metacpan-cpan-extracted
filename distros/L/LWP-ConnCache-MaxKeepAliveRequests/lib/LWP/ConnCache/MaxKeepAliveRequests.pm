package LWP::ConnCache::MaxKeepAliveRequests;
use Moose;
our $VERSION = '0.33';

extends 'LWP::ConnCache';

sub new {
    my ( $class, %args ) = @_;
    my $max_keep_alive_requests = $args{max_keep_alive_requests} || 100;
    delete $args{max_keep_alive_requests};
    my $self = LWP::ConnCache->new(%args);
    $self->{max_keep_alive_requests} = $max_keep_alive_requests;
    bless $self, $class;
    return $self;
}

around 'deposit' => sub {
    my ( $coderef, $self, $type, $key, $conn ) = @_;
    my $max_keep_alive_requests = $self->{max_keep_alive_requests};

    my $keep_alive_requests = ${*$conn}{'myhttp_response_count'};
    if ( $keep_alive_requests < $max_keep_alive_requests ) {
        $coderef->( $self, $type, $key, $conn );
    }
};

1;

__END__

=head1 NAME

LWP::ConnCache::MaxKeepAliveRequests - A connection cache that enforces a max keep alive limit

=head1 SYNOPSIS

  use LWP;
  use LWP::ConnCache::MaxKeepAliveRequests;
  my $ua = LWP::UserAgent->new;
  $ua->conn_cache(
      LWP::ConnCache::MaxKeepAliveRequests->new(
          total_capacity          => 10,
          max_keep_alive_requests => 100,
      )
  );

=head1 DESCRIPTION

L<LWP::UserAgent> is the default module for issuing HTTP requests from
Perl. It has a keep_alive setting which by default allows unlimited
requests to the same server. Some servers will disconnect you after
a limited number of requests (in Apache 2 this is achieved with the
MaxKeepAliveRequests directive). This module allows you to limit
the maximum number of keep alive requests to a server. 

=head1 AUTHOR

Leon Brocard <acme@astray.com>.

=head1 COPYRIGHT

Copyright (C) 2008, Leon Brocard

=head1 LICENSE

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.
