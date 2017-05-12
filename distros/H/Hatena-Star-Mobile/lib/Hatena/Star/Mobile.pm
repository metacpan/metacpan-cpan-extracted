package Hatena::Star::Mobile;
use strict;
use warnings;
use URI::Escape;
use LWP::UserAgent;
use HTTP::Request;
use JSON::Syck;

our $VERSION = '0.01';

my $add_template =
    '<a href="%sstar.add?sid=%s&rks=%s&uri=%s&location=%s">' .
    '<img src="http://s.hatena.com/images/add_%s.gif" alt="Add Star" align="middle" /></a>';

sub get_star_entries {
    my $class = shift;
    my %args = @_;
    my $entries = $args{entries} or return;
    my $hatena_domain = $args{hatena_domain} || 'hatena.com';
    my $sbase = sprintf('http://s.%s/', $hatena_domain);
    my $suri = $sbase . 'entries.json?';
    if ($args{sid}) {
        $suri .= sprintf('sid=%s&', $args{sid});
    }
    my $count = 0;
    for my $e (@$entries) {
        next unless $e->{uri};
        $suri .= 'uri=' . URI::Escape::uri_escape($e->{uri}) . '&';
        $count++;
    }
    my $sentries = [];
    if ($count) {
        my $ua = LWP::UserAgent->new;
        my $req = HTTP::Request->new(GET => $suri);
        my $res = $ua->request($req);
        $res->is_success or return;
        my $data = JSON::Syck::Load($res->content);
        $sentries = $data->{entries};
    }
    for my $se (@$sentries) {
        next unless ($se && $se->{uri});
        my $html = sprintf(
            $add_template,
            $sbase, $args{sid} || '', $args{rks} || '',
            URI::Escape::uri_escape($se->{uri}),
            URI::Escape::uri_escape($args{location} || ''),
            $args{color} || 'de'
        );
        for my $s (@{$se->{stars}}) {
            if (ref $s eq 'HASH') {
                $html .= sprintf('<img src="%simages/star.gif" alt="%s" align="middle" />',
                                 $sbase, $s->{name});
            } else {
                $html .= sprintf('<font color="#f4b128">%d</font>',$s);
            }
        }
        $se->{star_html} = $html;
    }
    return $sentries;
}

1;
__END__

=head1 NAME

Hatena::Star::Mobile - Perl extension for embedding Hatena Star into mobile sites.

=head1 SYNOPSIS

  use Hatena::Star::Mobile;

  my $entries = [
    {uri => 'http://d.hatena.ne.jp/jkondo/20080123/1201040123'},
    {uri => 'http://d.hatena.ne.jp/jkondo/20080122/1200947996'},
    {uri => 'http://d.hatena.ne.jp/jkondo/20080121/1200906620'},
  ];

  my $star_entries = Hatena::Star::Mobile->get_star_entries(
    entries => $entries,
    location => 'http://d.hatena.ne.jp/jkondo/mobile', # return url for add button
    color => 'gr', # color for add button
    hatena_domain => 'hatena.ne.jp', # base domain name of Hatena
    sid => 'abced', # (mobile session id)
    rks => '12345', # (Hatena::User->rks)
  );

  for my $se (@$star_entries) {
    print $se->{star_html}; # html string for add button and stars
    print $se->{uri}; # entry's uri
  }

=head1 DESCRIPTION

=head1 AUTHOR

Junya Kondo, E<lt>http://d.hatena.ne.jp/jkondo/E<gt>,

=head1 COPYRIGHT AND LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=cut
