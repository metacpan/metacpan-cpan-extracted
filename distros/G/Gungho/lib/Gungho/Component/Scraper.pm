# $Id: /mirror/gungho/lib/Gungho/Component/Scraper.pm 4037 2007-10-25T14:20:48.994833Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Component::Scraper;
use strict;
use warnings;
use base qw(Gungho::Component);
use Web::Scraper::Config;

__PACKAGE__->mk_classdata(_scrapers => {});

sub scrape
{
    my ($c, $response, $arg) = @_;
    my $scraper = $c->_load_scraper($arg);
    $scraper->scrape($response->content);
}

sub _load_scraper
{
    my ($c, $config) = @_;

    my $name;
    if (! ref $config) {
        $name = $config;
    } else {
        $name = do {
            require Data::Dumper;
            require Digest::MD5;
            local $Data::Dumper::Indent  = 1;
            local $Data::Dumper::Sorkeys = 1;
            local $Data::Dumper::Terse   = 1;
            Digest::MD5::md5_hex( Data::Dumper::Dumper( $config ) );
        };
        die if $@;
    }

    $c->_scrapers->{ $name } ||= Web::Scraper::Config->new($config);
}

1;

__END__

=head1 NAME

Gungho::Component::Scraper - Web::Scraper From Within Gungho

=head1 SYNOPSIS

  # Either setup $name in config, or call
  # $c->register_scraper_config($name, $config);
  $c->scrape($response, $name);

  $c->scrape($response, $config);

=head1 DESCRIPTION

This component allows you to use Web::Scraper (via Web::Scraper::Config) from
within Gungho.

=head1 METHODS

=head2 scrape ($response, $config)

=cut