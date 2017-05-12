package Message::Passing::Filter::Regexp::Log;

use strict;
use warnings;
use Config::Tiny;

use base qw( Regexp::Log );
use vars qw( $VERSION %DEFAULT %FORMAT %REGEXP );

$VERSION = 0.01;

sub _read_config {
    Config::Tiny->read(shift);
};

sub new {
    my $class = shift;
    my $args = { @_ };
    my $regexfile = delete $args->{'regexfile'};
    my $cfg = &_read_config($regexfile);
    %DEFAULT = ( default => '', capture => [] );
    %FORMAT = %{ $cfg->{FORMAT} };
    %REGEXP = %{ $cfg->{REGEXP} };
    my $self = $class->SUPER::new(%$args);
    bless $self, $class;
    return $self;
};

1;
__END__
=head1 NAME

Message::Passing::Filter::Regexp::Log - Extension for Regexp::Log with Config::Tiny

=head1 SYNOPSIS

  use Message::Passing::Filter::Regexp::Log;
  my $regex = Message::Passing::Filter::Regexp::Log->new(
      regexfile => "./regexfile",
      format => ":syslog",
      capture => [qw(pri host msg time)]
  );
  my @fields = $foo->capture;

  my $re = $foo->regexp;

  while (<>) {
      my %data;
      @data{@fields} = /$re/;    # no need for /o, it's a compiled regexp
  };
     
=head1 DESCRIPTION

=head1 SEE ALSO

C<Regexp::Log::Common>

=head1 AUTHOR

chenryn, E<lt>rao.chenlin@gmail.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by chenryn

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
