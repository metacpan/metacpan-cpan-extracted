package HTTP::MobileAgent::Plugin::Charset;
use strict;
use warnings;
use 5.00800;
our $VERSION = '0.04';

sub HTTP::MobileAgent::can_display_utf8 {
    my $self = shift;
    $self->encoding =~ /utf-?8/ ? 1 : 0;
}

sub HTTP::MobileAgent::encoding {
    my $self = shift;
    if ($self->is_non_mobile) {
        return 'utf-8';
    } elsif ($self->is_airh_phone) {
        return 'x-sjis-airh';
    } elsif ($self->is_ezweb) {
        # ezweb canot display utf8 in https.
        return 'x-sjis-ezweb-auto';
    } elsif ($self->is_vodafone) {
        if ($self->is_type_3gc) {
            return 'x-utf8-vodafone';
        } else {
            return 'x-sjis-vodafone';
        }
    } else {
        my $charset = $self->xhtml_compliant ? 'utf8' : 'sjis';
        return join '-', 'x', $charset, lc($self->carrier_longname);
    }
}

1;
__END__

=encoding utf8

=for stopwords aaaatttt dotottto gmail SSL au utf8

=head1 NAME

HTTP::MobileAgent::Plugin::Charset - Encode::JP::Mobile friendly

=head1 SYNOPSIS

  use HTTP::MobileAgent;
  use HTTP::MobileAgent::Plugin::Charset;

  my $agent = HTTP::MobileAgent->new;
  $agent->can_display_utf8; # => 1 or 0

  use Encode::JP::Mobile;
  encode($agent->encoding, "\x{223e}");

=head1 DESCRIPTION

HTTP::MobileAgent::Plugin::Charset is a plugin of HTTP::MobileAgent.

You can detect encoding. The result can use with Encode::JP::Mobile.

=head1 KNOWLEDGE

au phone can display utf8, but cannot display when SSL.

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom aaaatttt gmail dotottto commmmmE<gt>

=head1 SEE ALSO

L<HTTP::MobileAgent>, L<Encode::JP::Mobile>

L<http://www.au.kddi.com/ezfactory/tec/spec/wap_rule.html>
L<http://www.nttdocomo.co.jp/service/imode/make/content/xhtml/about/>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
