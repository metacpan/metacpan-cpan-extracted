package Marky::Generator;
$Marky::Generator::VERSION = '0.0602';
# ABSTRACT: Marky::Generator - generates boilerplate for marky webapp

use Mojo::Base 'Mojolicious::Command';

sub init {
    my $self = shift;
    $self->generate_config_file;
    $self->generate_web_app;
}

sub generate_config_file {
    shift->render_to_rel_file("marky.conf" => 'marky.conf');
}

sub generate_web_app {
    my $self = shift;
    $self->render_to_rel_file('webapp.pl' => 'webapp.pl');
    $self->chmod_rel_file('webapp.pl' => 0755);
}

1;

=pod

=encoding UTF-8

=head1 NAME

Marky::Generator - Marky::Generator - generates boilerplate for marky webapp

=head1 VERSION

version 0.0602

=head1 NAME

Marky::Generator - generates boilerplate for marky webapp

=head1 VERSION

version 0.0602

=head2 init

The init command generates boilerplate installation.

=head2 generate_config_file

Generates a config file.

=head2 generate_web_app

Generates a boilerplate webapp.pl file

=head1 AUTHOR

Kathryn Andersen <perlkat@katspace.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kathryn Andersen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__

@@ marky.conf
{
    defaults => {
        title => 'Marky',
        footer => 'Marky FOOT',
        db => 'bookmarks',
    },
    hypnotoad => {
        pid_file => '/var/www/marky/marky.pid',
        listen => ['http://*:3002'],
        proxy => 1,
    },
    foil => {
        "localhost:3000" => {
            name => "morbo",
            logo_dark_url => app->url_for("/css/logos/marky_dark.png"),
            logo_light_url => app->url_for("/css/logos/marky_light.png"),
            default_theme => 'gblue2',
            navbar_host => 'localhost:3000',
            navbar_links => [qw(
                /home/
                /marky/
                )],
        },
        "localhost:3002" => {
            name => "hypnotoad",
            logo_dark_url => app->url_for("/css/logos/marky_dark.png"),
            logo_light_url => app->url_for("/css/logos/marky_light.png"),
            default_theme => 'cnblue',
            navbar_host => 'localhost:3002',
            navbar_links => [qw(
                /home/
                /marky/
                )],
        },
    },
    tables => {
        bookmarks => {
            database => '/home/foo/bookmarks.sql',
            public_dir => '/home/foo/bookmarks/contents/',
            table => 'filetable',
            columns => [qw(title url description tags linkdate)],
            default_sort => ['linkdate DESC'],
            extra_cond => '(private = "0" AND url NOT NULL AND tags GLOB "*howto*")',
            row_template => '
<li>
{?thumburl <div class="thumbnail"><img style="height:150px;" src="/db/bookmarks/view[$thumburl]" alt="[$title]"/></div>}
<div class="linkcontainer">
<span class="linktitle"><a href="{$url}">{?title [$title]!![$url]}</a></span>
<div class="linkdescription">
{?description [$description:html]}
</div>
<div class="details">{$linkdate}</div>
{?all_tags <div class="linktaglist">[$all_tags]</div>}
</div>
</li>
',
        },
    },
}

@@ webapp.pl
#!/usr/bin/env perl
use strict;
use warnings;

# Start command line interface for application
require Mojolicious::Commands;
Mojolicious::Commands->start_app('Marky');

__END__
