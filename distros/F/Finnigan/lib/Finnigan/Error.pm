package Finnigan::Error;

use strict;
use warnings FATAL => qw( all );
our $VERSION = 0.0206;

use Finnigan;
use base 'Finnigan::Decoder';


sub decode {
  my ($class, $stream, $layout) = @_;

  my $fields = [
                "time"     =>  ['f<',     'Float32'],
                "message"  =>  ['varstr', 'PascalStringWin32'],
               ];

  my $self = bless Finnigan::Decoder->read($stream, $fields), $class;
  return $self;
}

sub time {
  shift->{data}->{"time"}->{value};
}

sub message {
  shift->{data}->{"message"}->{value};
}

1;
__END__

=head1 NAME

Finnigan::Error -- a decoder for Error, an error log record

=head1 SYNOPSIS

  use Finnigan;
  my $entry = Finnigan::Error->decode(\*INPUT);
  say $entry->time;
  say $entry->message;

=head1 DESCRIPTION

Error is a varibale-length structure containing timestamped error
messages. It implicitly links an error message to a scan using the
retention time.

=head2 METHODS

=over 4

=item decode($stream)

The constructor method

=item time

Get the entry's timestamp (retention time)

=item message

Get the text message

=back

=head1 SEE ALSO

L<uf-error>

=head1 AUTHOR

Gene Selkov, E<lt>selkovjr@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Gene Selkov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
