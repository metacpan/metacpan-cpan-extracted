package Marky;
$Marky::VERSION = '0.0602';
# ABSTRACT: web application for bookmark databases

use Mojo::Base 'Mojolicious';
use Path::Tiny;
use File::ShareDir;

# This method will run once at server start
sub startup {
    my $self = shift;

    # -------------------------------------------
    # Configuration
    # check:
    # * current working directory
    # * relative to the calling program
    # -------------------------------------------
    my $the_prog = path($0)->absolute;
    my $conf_basename = "marky.conf";
    my $conf_file = path(Path::Tiny->cwd, $conf_basename);
    if (! -f $conf_file)
    {
        $conf_file = path($the_prog->parent->stringify, $conf_basename);
        if (! -f $conf_file)
        {
            $conf_file = path($the_prog->parent->parent->stringify, $conf_basename);
        }
    }
    # the MARKY_CONFIG environment variable overrides the default
    if (defined $ENV{MARKY_CONFIG} and -f $ENV{MARKY_CONFIG})
    {
        $conf_file = $ENV{MARKY_CONFIG};
    }
    print STDERR "Marky::VERSION=$Marky::VERSION CONFIG: $conf_file\n";
    my $mojo_config = $self->plugin('Config' => { file => $conf_file });

    # -------------------------------------------
    # Application public directory
    #
    # For doing things like displaying images; the most portable method of
    # doing this is to have a "local" public directory which has softlinks to
    # the various desired directories.
    # -------------------------------------------
    if (defined $mojo_config->{public_dir}
            and $mojo_config->{public_dir}
            and -d $mojo_config->{public_dir})
    {
        push @{$self->static->paths}, $mojo_config->{public_dir};
    }

    # -------------------------------------------
    # Append Marky public directory
    # Find the Marky "public" directory
    # It could be relative to the CWD
    # It could be relative to the calling program
    # It could be in a FileShared location.
    my $pubdir = path(Path::Tiny->cwd, "public");
    if (!-d $pubdir)
    {
        $pubdir = path($the_prog->parent->stringify, "public");
        if (!-d $pubdir)
        {
            # use File::ShareDir with the distribution name
            my $dist = __PACKAGE__;
            $dist =~ s/::/-/g;
            my $dist_dir = path(File::ShareDir::dist_dir($dist));
            $pubdir = $dist_dir;
        }
    }
    if (-d $pubdir)
    {
        push @{$self->static->paths}, $pubdir;
    }
 
    # -------------------------------------------
    # DB Tables and Foil
    # -------------------------------------------
    $self->plugin('Marky::DbTableSet');

    my @db_routes = ();
    foreach my $db (@{$self->marky_table_array})
    {
        push @db_routes, "/db/$db";
    }
    $self->plugin('Foil' => { add_prefixes => \@db_routes});

    #$self->plugin(NYTProf => $mojo_config);

    # -------------------------------------------
    # Templates
    # -------------------------------------------
    push @{$self->renderer->classes}, __PACKAGE__;

    # -------------------------------------------
    # secrets, and defaults
    # -------------------------------------------
    $self->secrets([qw(AUygaywzatNJ9maaN3XY etunAvIlyiejUnnodwyk supernumary55)]);
    #$self->sessions->cookie_name('marky');
    #$self->sessions->default_expiration(60 * 60 * 24 * 3); # 3 days
    foreach my $key (keys %{$self->config->{defaults}})
    {
        $self->defaults($key, $self->config->{defaults}->{$key});
    }

    # -------------------------------------------

    # -------------------------------------------
    # Router
    # -------------------------------------------
    my $r = $self->routes;

    $r->get('/')->to('db#tables');
    $r->get('/db/')->to('db#tables');

    $r->get('/db/:db/taglist')->to('db#taglist');
    $r->get('/db/:db/tagcloud')->to('db#tagcloud');

    $r->get('/db/:db')->to('db#query');
    $r->get('/db/:db/tags/:tags')->to('db#tags');

    $r->get('/db/:db/add')->to('db#add_bookmark');
    $r->post('/db/:db/add')->to('db#save_bookmark');
}

1; # end of Marky

# Here come the TEMPLATES!

=pod

=encoding UTF-8

=head1 NAME

Marky - web application for bookmark databases

=head1 VERSION

version 0.0602

=head1 SYNOPSIS

    use Marky;

=head1 DESCRIPTION

Bookmarking and Tutorial Library application.
This uses
Mojolicious
Mojolicious::Plugin::Foil

Font Awesome by Dave Gandy - http://fontawesome.io

=head1 NAME

Marky - web application for bookmark databases

=head1 VERSION

version 0.0602

=head1 AUTHOR

Kathryn Andersen <perlkat@katspace.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kathryn Andersen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
@@ add_bookmark.html.ep
% layout 'foil';
% content_for 'head_extra' => begin
<link rel="stylesheet" href="<%= url_for('/css') %>/fa/css/font-awesome-min.css" type="text/css" />
<link rel="stylesheet" href="<%= url_for('/css') %>/marky.css" type="text/css" />
<link rel="stylesheet" href="<%= url_for('/css') %>/bookmark.css" type="text/css" />
% end
% content_for 'verso' => begin
<nav><%== marky_db_related_list %></nav>
% end
% content_for 'recto' => begin
<p class="total"><%= marky_total_records %> records in <%= param('db') %></p>
<%== marky_add_bookmark_bookmarklet %>
<%== foil_theme_selector %>
% end
<h1>Add Bookmark for <%= param('db') %></h1>
<%== marky_add_bookmark_form %>
 
@@ apperror.html.ep
% layout 'foil';
% content_for 'verso' => begin
<nav><%== marky_db_related_list %></nav>
% end
% content_for 'recto' => begin
<%== foil_theme_selector %>
% end
<h1>Error: <%= param('db') %></h1>
<%== $errormsg %>
 
@@ results.html.ep
% layout 'foil';
% content_for 'head_extra' => begin
<link rel="stylesheet" href="<%= url_for('/css') %>/fa/css/font-awesome-min.css" type="text/css" />
<link rel="stylesheet" href="<%= url_for('/css') %>/marky.css" type="text/css" />
<link rel="stylesheet" href="<%= url_for('/css') %>/results.css" type="text/css" />
% end
% content_for 'verso' => begin
<nav><%== marky_db_related_list %></nav>
<nav><%== $query_taglist %></nav>
% end
% content_for 'recto' => begin
<p class="total"><%= marky_total_records %> records in <%= param('db') %></p>
<%== foil_theme_selector %>
% end
<h1>Search <%= param('db') %></h1>
<%== $results %>
 
@@ save_bookmark.html.ep
% layout 'foil';
% content_for 'head_extra' => begin
<link rel="stylesheet" href="<%= url_for('/css') %>/fa/css/font-awesome-min.css" type="text/css" />
<link rel="stylesheet" href="<%= url_for('/css') %>/marky.css" type="text/css" />
<link rel="stylesheet" href="<%= url_for('/css') %>/bookmark.css" type="text/css" />
% end
% content_for 'verso' => begin
<nav><%== marky_db_related_list %></nav>
% end
% content_for 'recto' => begin
<p class="total"><%= marky_total_records %> records in <%= param('db') %></p>
<%== marky_add_bookmark_bookmarklet %>
<%== foil_theme_selector %>
% end
<h1>Bookmark for <%= param('db') %></h1>
<%== content 'results' %>
 
@@ settings.html.ep
% layout 'foil';
% content_for 'head_extra' => begin
<link rel="stylesheet" href="<%= url_for('/css') %>/fa/css/font-awesome-min.css" type="text/css" />
<link rel="stylesheet" href="<%= url_for('/css') %>/marky.css" type="text/css" />
% end
% content_for 'verso' => begin
<nav><%== marky_table_list %></nav>
% end
% content_for 'recto' => begin
<%== foil_theme_selector %>
% end
<h1>Settings</h1>
<%== marky_settings %>
 
@@ tables.html.ep
% layout 'foil';
% content_for 'head_extra' => begin
<link rel="stylesheet" href="<%= url_for('/css') %>/fa/css/font-awesome-min.css" type="text/css" />
<link rel="stylesheet" href="<%= url_for('/css') %>/marky.css" type="text/css" />
% end
% content_for 'verso' => begin
<nav><%== marky_table_list %></nav>
% end
% content_for 'recto' => begin
<%== foil_theme_selector %>
% end
<h1>Select What Table To Search</h1>
<%== marky_table_list %>
 
@@ tagcloud.html.ep
% layout 'foil';
% content_for 'head_extra' => begin
<link rel="stylesheet" href="<%= url_for('/css') %>/fa/css/font-awesome-min.css" type="text/css" />
<link rel="stylesheet" href="<%= url_for('/css') %>/marky.css" type="text/css" />
% end
% content_for 'verso' => begin
<nav><%== marky_db_related_list %></nav>
% end
% content_for 'recto' => begin
<p class="total"><%= marky_total_records %> records in <%= param('db') %></p>
<%== foil_theme_selector %>
% end
<h1>Tag Cloud: <%= param('db') %></h1>
<%== marky_tagcloud %>
 
@@ taglist.html.ep
% layout 'foil';
% content_for 'head_extra' => begin
<link rel="stylesheet" href="<%= url_for('/css') %>/fa/css/font-awesome-min.css" type="text/css" />
<link rel="stylesheet" href="<%= url_for('/css') %>/marky.css" type="text/css" />
<link rel="stylesheet" href="<%= url_for('/css') %>/taglist.css" type="text/css" />
% end
% content_for 'verso' => begin
<nav><%== marky_db_related_list %></nav>
% end
% content_for 'recto' => begin
<p class="total"><%= marky_total_records %> records in <%= param('db') %></p>
<%== foil_theme_selector %>
% end
<h1>Tag List: <%= param('db') %></h1>
<%== marky_taglist %>
 
