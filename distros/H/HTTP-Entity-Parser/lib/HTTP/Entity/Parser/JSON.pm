package HTTP::Entity::Parser::JSON;

use strict;
use warnings;
use JSON::MaybeXS qw/decode_json/;
use Encode qw/encode_utf8/;

sub new {
    bless [''], $_[0];
}

sub add {
    my $self = shift;
    if (defined $_[0]) {
        $self->[0] .= $_[0];
    }
}

sub finalize {
    my $self = shift;

    my $p = decode_json($self->[0]);
    my @params;
    if (ref $p eq 'HASH') {
        while (my ($k, $v) = each %$p) {
            if (ref $v eq 'ARRAY') {
                for (@$v) {
                    push @params, encode_utf8($k), encode_utf8($_);
                }
            } else {
                push @params, encode_utf8($k), encode_utf8($v); 
            }
        }
    }
    return (\@params, []);
}

1;

__END__

=encoding utf-8

=head1 NAME

HTTP::Entity::Parser::JSON - parser for application/json

=head1 SYNOPSIS

    use HTTP::Entity::Parser;
    
    my $parser = HTTP::Entity::Parser->new;
    $parser->register('application/json','HTTP::Entity::Parser::JSON');

=head1 LICENSE

Copyright (C) Masahiro Nagano.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo@gmail.comE<gt>

Tokuhiro Matsuno E<lt>tokuhirom@gmail.comE<gt>

=cut


