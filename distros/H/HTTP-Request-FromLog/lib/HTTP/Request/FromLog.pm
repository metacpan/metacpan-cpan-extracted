package HTTP::Request::FromLog;

use strict;
use warnings;
use HTTP::Request;
use UNIVERSAL::require;

use 5.8.1;

our $VERSION = '0.00002';

sub new {
    my $class = shift;
    my %args  = @_;

    my $self = bless {}, $class;
    $self->_init( \%args );

    return $self;
}

sub _init {
    my $self = shift;
    my $args = shift;

    my $class = $args->{engine} ||= 'HTTP::Request::FromLog::Engine::Default';
    $class->require or die $@;

    my $engine_args = $args->{engine_args} ||= {};
    $engine_args->{scheme} = $args->{scheme} ||= 'http';
    $engine_args->{host} = $args->{host};

    $self->{engine} = $class->new(%$engine_args);

}

sub convert {
    my $self       = shift;
    my $log_record = shift;

    my $result = $self->{engine}->parse($log_record);
    return if ( !defined $result );

    my $request =
      HTTP::Request->new( $result->{method}, $result->{uri},
        $result->{header} );

    return $request;
}

1;

__END__

=head1 NAME

HTTP::Request::FromLog - convert to HTTP::Request object from Apache's access_log record.

=head1 SYNOPSIS

  use HTTP::Request::FromLog;

  my %args = (
    host   => '192.168.1.5',
  );

  my $log2hr = HTTP::Request::FromLog->new(%args);
  my $ua = LWP::UserAgent->new;
  open(LOG, "access_log");
  while( my $rec = <LOG> ){
    my $http_request  = $log2hr->convert($rec);
    my $http_response = $ua->request($http_request);
    # do something
  }
  close(LOG);

  ---
  # Default engine has a parser as `Parse::AccessLogEntry`.
  # You can change your custom engine instead of this.

  my %args = (
    host => '192.168.1.5',
    engine => 'My::Custom::Engine' 
    engine_args => { $key => $value, .... }
  );
  my $log2hr = HTTP::Request::FromLog->new(%args);

=head1 DESCRIPTION

This module converts Apache's access_log to an HTTP::Request object.

So that, it will be able to spread the http request to Develop Environment Server from Commercial Environment Server.

=head1 METHODS

=head2 new()

=head2 convert()

=head1 AUTHOR

Takeshi Miki E<lt>miki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
