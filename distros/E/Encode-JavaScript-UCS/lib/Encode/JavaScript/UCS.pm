package Encode::JavaScript::UCS;
use strict;
use 5.8.1;
our $VERSION = '0.01';

use base qw(Encode::Encoding);
use Encode 2.12 (); # for callbacks

__PACKAGE__->Define('JavaScript-UCS');

sub decode($$;$){
    my ($obj, $buf, $chk) = @_;
    $buf =~ s/\\u([0-9a-f]{4})/chr(hex($1))/eig;
    $_[1] = '' if $chk; # this is what in-place edit means
    return $buf;
}

sub encode($$;$){
    my ($obj, $str, $chk) = @_;
    $str = Encode::encode("ascii", $str, sub { sprintf("\\u%04x", $_[0]) });
    $_[1] = '' if $chk; # this is what in-place edit means
    return $str;
}

1;
__END__

=head1 NAME

Encode::JavaScript::UCS - JavaScript unicode character encoding

=head1 SYNOPSIS

  use Encode::JavaScript::UCS;

  my $name = "\x{5BAE}\x{5DDD}\x{9054}\x{5F66}";
  my $escaped = encode("JavaScript-UCS", $name); # \u5bar\u5ddd\u9054\u5f66

=head1 DESCRIPTION

Encode::JavaScript::UCS is an Encoding module to represent JavaScript
unicode characters like "\u5bae".

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Encode>

=cut
