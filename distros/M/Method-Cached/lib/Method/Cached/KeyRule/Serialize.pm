package Method::Cached::KeyRule::Serialize;

use strict;
use warnings;
use base qw/Method::Cached::KeyRule::Base/;
use Digest::SHA;
use JSON::XS;
use Storable;

__PACKAGE__->export_rule(qw/SELF_CODED SERIALIZE/);

sub SELF_CODED {
    my ($method_name, $args) = @_;
    our $ENCODER ||= JSON::XS->new->convert_blessed(1);
    local *UNIVERSAL::TO_JSON = sub { Storable::nfreeze \@_ };
    my $json = $ENCODER->encode($args->[0]);
    $args->[0] = Digest::SHA::sha1_base64($json);
    return;
}

sub SERIALIZE {
    my ($method_name, $args) = @_;
    our $ENCODER ||= JSON::XS->new->convert_blessed(1);
    local $^W = 0;
    local *UNIVERSAL::TO_JSON = sub { Storable::nfreeze \@_ };
    my $json = $ENCODER->encode($args);
    $method_name . Digest::SHA::sha1_base64($json);
}

1;

__END__

=head1 NAME

Method::Cached::KeyRule::Serialize - Generation rule of key to serialization

=head1 SYNOPSIS

  use Method::Cached;
  use Method::Cached::KeyRule::Serialize;
  
  sub some_code :Cached(1800, SERIALIZE) {
      my ($hash_ref) = @_;
  }
  
  sub some_code_class :Cached(1800, [SELF_CODED, HASH]) {
      my ($self, %args) = @_;
  }

=head1 DESCRIPTION

Generation rule of key to serialization

Warn: According to circumstances, the key becomes strict too much when
parameters are serialized and cache might be not effective at all. 

=head1 AUTHOR

Satoshi Ohkubo E<lt>s.ohkubo@gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
