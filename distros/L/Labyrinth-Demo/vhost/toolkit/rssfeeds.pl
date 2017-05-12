#!/usr/bin/perl -w
use strict;

=head1 NAME

rssfeeds - Provide the RSS feeds for the site

=head1 SYNOPSIS

  perl rssfeeds.pl

=head1 DESCRIPTION

This application provides all the RSS feeds for the website.

=cut

my $BASE;

# create images in pages
BEGIN {
    $BASE = '/var/www/demo';
}

#----------------------------------------------------------
# Additional Modules

use lib qw|../cgi-bin/lib|;
use Labyrinth::Globals;
use Labyrinth::RSS;
use Labyrinth::Variables;
use Labyrinth::Plugin::Articles;

use IO::File;

#----------------------------------------------------------
# Variables

my @types = (
#    { type => 'rss',  version => '0.9' },
#    { type => 'rss',  version => '1.0' },
    { type => 'rss',  version => '2.0' },
    { type => 'atom', version => '1.0' },
);

#----------------------------------------------------------
# Code

Labyrinth::Globals::LoadSettings("$BASE/cgi-bin/config/settings.ini");
Labyrinth::Globals::DBConnect();

# Diary Entries
$settings{perma} = $tvars{webpath} . '/diary/';
$cgiparams{sectionid} = 6;
$settings{limit} = 10;

my $arts = Labyrinth::Plugin::Articles->new();
$arts->List();


for my $item (@types) {
    my $rss = Labyrinth::RSS->new( %$item, perma => 'http://demo.example.com/' );
    my $xml = $rss->feed(@{$tvars{articles}});
    write_xml("rss/$item->{type}-$item->{version}.xml",$xml);
}

sub write_xml {
    my $file = shift;
    my $xml  = shift;
    my $fh = IO::File->new("$BASE/html/$file",'w')    or die "Cannot write to file [$BASE/html/$file]: $!";
    print $fh $xml;
    $fh->close;
}

__END__

=head1 AUTHOR

  Copyright (c) 2002-2014 Barbie <barbie@cpan.org> Miss Barbell Productions.

=head1 LICENSE

  This program is free software; you can redistribute it and/or modify it
  under the same terms as Perl itself.

  See http://www.perl.com/perl/misc/Artistic.html

=cut
