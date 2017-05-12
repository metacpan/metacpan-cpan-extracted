package HTTP::Request::FromLog::Engine::Default;

use strict;
use warnings;
use base qw(HTTP::Request::FromLog::Engine::Base);
use Parse::AccessLogEntry;
use HTTP::Headers;
use List::MoreUtils qw(all);

sub new {
    my $class = shift;
    my %args  = @_;

    $args{parser} = Parse::AccessLogEntry->new();

    return $class->SUPER::new(%args);
}

sub parse {
    my $self       = shift;
    my $log_record = shift;

    my $record = $self->{parser}->parse($log_record);

    return undef if all { !defined $_ } values %$record;

    my $method = $record->{rtype};
    my $uri    = $self->{scheme} . '://' . $self->{host} . $record->{file};
    my $header = HTTP::Headers->new();
    $header->header( host       => $self->{host} );
    $header->header( user_agent => $record->{agent} ) if $record->{agent};
    $header->header( referer    => $record->{refer} ) if $record->{refer};

    return ( { method => $method, uri => $uri, header => $header } );
}

1;

__END__

=head1 NAME

HTTP::Request::FromLog::Engine::Default - Default engine 

=head1 SYNOPSIS

  use HTTP::Request::FromLog;

  my $log2hr = HTTP::Request::FromLog->new( ... );
  # this module is called on backend as default engine

=head1 DESCRIPTION

HTTP::Request::FromLog::Default::Engine adopts log parser `Parse::AccessLogEntry` inside.

Every engine has to override `parse()` method.

=head1 METHODS

=head2 new()

=head2 parse()

=head1 AUTHOR

Takeshi Miki E<lt>miki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
