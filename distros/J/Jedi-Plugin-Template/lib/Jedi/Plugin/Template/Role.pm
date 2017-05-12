#
# This file is part of Jedi-Plugin-Template
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Jedi::Plugin::Template::Role;

# ABSTRACT: Role imported by Jedi::Plugin::Template

use strict;
use warnings;

our $VERSION = '1.001';    # VERSION
use Template;
use Path::Class;
use feature 'state';
use MIME::Types qw/by_suffix/;
use Carp;
use IO::Compress::Gzip qw(gzip);
use HTTP::Date qw/time2str/;
use Digest::SHA qw/sha1_base64/;
use File::ShareDir ':ALL';

sub _jedi_template_check_path {
    my ($path) = @_;

    return if !defined $path;

    return if ( !-d dir( $path, 'views' ) ) || ( !-d dir( $path, 'public' ) );

    return dir($path)->absolute;
}

sub _jedi_template_setup_path {
    my ($jedi_app) = @_;

    my $class = ref $jedi_app;
    my $dist  = $class;
    $dist =~ s/::/-/gx;

    my $template_dir =

        # config dir
        _jedi_template_check_path(
        $jedi_app->jedi_config->{$class}{template_dir} )
        //

        # dist_dir
        _jedi_template_check_path( eval { dist_dir($dist) } );

    croak "No template dir found, please setup one !"
        if !defined $template_dir;

    $jedi_app->jedi_config->{$class}{template_dir} = dir($template_dir);

    return;
}

sub _jedi_dispatch_public_files {
    my ( $jedi_app, $request, $response ) = @_;
    my $class      = ref $jedi_app;
    my $delta_path = substr( $request->env->{PATH_INFO},
        length( $jedi_app->jedi_base_route ) - 1 );
    my $file = file( $jedi_app->jedi_config->{$class}{template_dir},
        'public', $delta_path );
    return 1 if !-f $file;

    my ( $mime_type, $encoding ) = by_suffix($file);
    my $type    = $mime_type . '; charset=' . $encoding;
    my $content = $file->slurp();

    my $accept_encoding = $request->env->{HTTP_ACCEPT_ENCODING} // '';
    if ( $accept_encoding =~ /gzip/ ) {
        my $content_unpack = $content;
        gzip \$content_unpack => \$content;
        $response->set_header( 'Content-Encoding', 'gzip' );
        $response->set_header( 'Vary',             'Accept-Encoding' );
    }

    my $now         = time;
    my $last_change = $file->stat()->mtime;
    $response->set_header( 'Last-Modified', time2str($last_change) );
    $response->set_header( 'Expires',       time2str( $now + 86400 ) );
    $response->set_header( 'Cache-Control', 'max-age=86400' );
    $response->set_header( 'ETag',          sha1_base64($content) );

    $response->status(200);
    $response->set_header( 'Content-Type', $type );
    $response->set_header( 'Content-Length' => length($content) );
    $response->body($content);

    return;
}

use Moo::Role;

has 'jedi_template_default_layout' => ( is => 'rw' );

before 'jedi_app' => sub {
    my ($jedi_app) = @_;

    _jedi_template_setup_path($jedi_app);

    $jedi_app->get( qr{.*}x, \&_jedi_dispatch_public_files );

    return;
};

sub jedi_template {
    my ( $jedi_app, $file, $vars, $layout ) = @_;
    $layout //= $jedi_app->jedi_template_default_layout;
    $layout = 'none' if !defined $layout;
    my $class = ref $jedi_app;
    my $template_views
        = dir( $jedi_app->jedi_config->{$class}{template_dir}, 'views' );

    my $layout_file;
    if ( $layout ne 'none' ) {
        $layout_file = file( $template_views, 'layouts', $layout );
        if ( !-f $layout_file ) {
            $layout      = 'none';
            $layout_file = undef;
        }
    }

    state $cache = {};
    if ( !exists $cache->{$layout} ) {
        my @tpl_options = (
            INCLUDE_PATH => [ $template_views->absolute->stringify ],
            ABSOLUTE     => 1,
        );

        if ( $layout ne 'none' ) {
            push @tpl_options, WRAPPER => $layout_file->absolute->stringify;
        }

        $cache->{$layout} = Template->new(@tpl_options);
    }

    my $tpl_engine = $cache->{$layout};
    my $view_file = file( $template_views, $file );

    my $ret = "";
    $tpl_engine->process( $view_file->absolute->stringify, $vars, \$ret )
        or croak $tpl_engine->error();

    return $ret;
}

1;

__END__

=pod

=head1 NAME

Jedi::Plugin::Template::Role - Role imported by Jedi::Plugin::Template

=head1 VERSION

version 1.001

=head1 DESCRIPTION

Check L<Jedi::Plugin::Template> for documentation

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/celogeek/perl-jedi-plugin-template/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

celogeek <me@celogeek.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by celogeek <me@celogeek.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
