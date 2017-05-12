package HTML::MobileJp;
use strict;
use warnings;
use 5.00800;
our $VERSION = '0.08';
use base qw/Exporter/;

my @modules = map { __PACKAGE__ . "::Plugin::$_" } qw/
  GPS
  EZweb::Object
  /;

our @EXPORT;

for my $module (@modules) {
    eval "use $module"; ## no critic.
    die $@ if $@;

    $module->import;

    no strict 'refs';
    push @EXPORT, @{ "${module}::EXPORT"};
}

1;
__END__

=for stopwords mobile-jp html TODO CGI ezweb

=head1 NAME

HTML::MobileJp - generate mobile-jp html tags

=head1 SYNOPSIS

    use HTML::MobileJp qw/gps_a/;
    gps_a(
        callback_url => "http://example.com/gps/jLKJFJDSL",
        carrier      => 'I',
        is_gps       => 1,
    );
    # => <a href="http://example.com/gps/jLKJFJDSL" lcs="lcs">

    gps_a(
        callback_url => "http://example.com/gps/jLKJFJDSL",
        carrier      => 'I',
        is_gps       => 0,
    );
    # => <a href="http://w1m.docomo.ne.jp/cp/iarea?ecode=OPENAREACODE&amp;msn=OPENAREAKEY&amp;posinfo=1&amp;nl=http%3A%2F%2Fexample.com%2Fgps%2FjLKJFJDSL">

=head1 DESCRIPTION

HTML::MobileJp is html tag generator for Japanese mobile phone.

=head1 TODO

    http://www.au.kddi.com/ezfactory/tec/dlcgi/download_1.html

download CGI for ezweb.

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom aaaatttt gmail dotottto commmmmE<gt>

=head1 SEE ALSO

L<HTML::MobileJp::Plugin::GPS>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
