use v5.40;
use experimental 'class';

class Minima::View::HTML :isa(Minima::View);

use Carp;
use Path::Tiny;
use Template;
use Template::Constants qw/ :debug /;
use utf8;

field $app                  :param;
field $directory            = 'templates';
field $template;
field $default_data         = {};

field %settings = (
    block_indexing => 1,    # block robots with a <meta>
    name_as_class => 1,     # include template name in @classes
    theme_color => '',      # hex color for the <meta theme-color>
    include_extra => ['js'],# extra directories to use as include path
);

field %content = (
    title => undef,
    description => undef,
    header_scripts => [],   # scripts to be loaded in <head>
    header_css => [],       # CSS to be loaded in <head>
    pre => [],              # global partials before a template
    post => [],             # global partials after a template
    pre_body => [],         # used right before the opening of <body>
    scripts => [],          # scripts to be embedded directly in <body>
    classes => [],          # classes added to <main>
);

ADJUST {
    my $config = $app->config;

    $content{title} = $config->{default_title} // '';
    $settings{block_indexing} = $config->{block_indexing} // 1;
    $settings{theme_color} = $config->{theme_color} // '';
}

method set_title ($t, $d = undef)
{
    $content{title} = $t;
    $content{description} = $d;
}

method set_compound_title ($t, $d = undef)
{
    $self->set_title(
        ( $content{title} ? "$content{title} • $t" : $t ),
        $d
    );
}

method set_directory ($d)
{
    $directory = path($d)->absolute
}

method set_template ($t)
{
    $template = $self->_ext($t);
}

method add_include_path ($d)
{
    push @{ $settings{include_extra} }, path($d)->absolute;
}

method set_block_indexing ($n = 1) { $settings{block_indexing} = $n }
method set_name_as_class  ($n = 1) { $settings{name_as_class} = $n }

method set_default_data   ($d) { $default_data = $d }

method add_header_script  ($s) { push @{$content{header_scripts}}, $s }
method add_header_css     ($c) { push @{$content{header_css}}, $c }
method add_pre            ($p) { push @{$content{pre}}, $self->_ext($p) }
method add_post           ($p) { push @{$content{post}}, $self->_ext($p) }
method add_pre_body       ($p) { push @{$content{pre_body}}, $p }
method add_script         ($s) { push @{$content{scripts}}, $s }
method add_class          ($c) { push @{$content{classes}}, $c }

method prepare_response ($response)
{
    $response->content_type('text/html; charset=utf-8');
}

method render ($data = {})
{
    croak "No template set." unless $template;

    # Merge default data
    $data = { %$default_data, %$data };

    # Build vars to send to template
    my %vars = ( %content, settings => \%settings );
    $data->{view} = \%vars;

    # Format CSS classes
    my @classes = @{ $content{classes} };
    if ($settings{name_as_class}) {
        my $clean_name = $template;
        $clean_name =~ s/\.\w+$//;
        $clean_name =~ tr/./-/;
        push @classes, $clean_name;
    }
    $vars{classes} = "@classes";

    # If any var is undef, replace with empty string
    $vars{$_} //= '' for keys %vars;

    # Setup Template Toolkit:
    # Create a default and overwrite with user configuration.
    my %tt_default = (
        INCLUDE_PATH => [ $directory, @{ $settings{include_extra} } ],
        OUTLINE_TAG => '%%',
        ANYCASE => 1,
        ENCODING => 'utf8',
    );
    if ($app->development) {
        $tt_default{DEBUG} = DEBUG_UNDEF;
    }
    my $tt_app_config = $app->config->{tt} // {};
    my %tt_config = ( %tt_default, %$tt_app_config );
    my $tt = Template->new(\%tt_config);

    # Render
    my ( $body, $r );

    for my $t (@{ $content{pre} }, $template, @{ $content{post} }) {
        $r = $tt->process($t, $data, \$body);
        croak "Failed to load template `$t` (at `$directory`): ",
              $tt->error, "\n" unless $r;
    }

    utf8::encode($body);
    $body;
}

method _ext ($file)
{
    my $ext = $app->config->{template_ext} // 'ht';
    $file = "$file.$ext" unless $file =~ /\.\w+$/;
}

__END__

=encoding utf8

=head1 NAME

Minima::View::HTML - Render HTML views

=head1 SYNOPSIS

    use Minima::View::HTML;

    my $view = Minima::View::HTML->new(app => $app);

    $view->set_directory('templates'); # where templates resite
    $view->set_template('home');
    $view->set_title('Minima');
    $view->add_script('global.js');

    my $body = $view->render({ data => ... });

=head1 DESCRIPTION

Minima::View::HTML provides a way to render HTML templates using
L<Template Toolkit|Template> with ease and a versatile set of data
and settings.

This class holds a reference to a L<Minima::App> object, which is
primarily used to interact with the configuration hash, where defaults
may be set to customize its behaviour.

Its principle of operation is quite simple: after configuring the
directory where templates reside (with L<C<set_directory>> or the
default F<templates> directory) and selecting the template to be used
(with L<C<set_template>>), the view collects and formats data to pass to
the template. This final stage ultimately determines how the output is
structured.

B<Note:> Minima::View::HTML works with UTF-8 by default, and encodes the
body response.

=head1 DATA

=head2 Content

The following data is managed and made available to template in the
C<view> hash. Whether it's used for its original purpose or a custom one
is left to the template implementation itself.

=over 4

=item C<title>

Scalar used as the page title.

=item C<description>

Scalar used as the page description (C<E<lt>metaE<gt>> tag).

=item C<header_scripts>

A list of scripts to be included in the header.

=item C<header_css>

A list of linked CSS to be included in the header.

=item C<pre>

A list of templates to be included before the main template.

=item C<post>

A list of templates to be included after the main template.

=item C<pre_body>

A list of templates to be included right before the opening
C<E<lt>bodyE<gt>> tag.

=item C<scripts>

A list of scripts to be embeded directly at the end of
C<E<lt>bodyE<gt>>.

=item C<classes>

A list of CSS classes to be included in C<E<lt>mainE<gt>>. Before being
passed to the view, the class list will be converted into a scalar (with
classes separated by spaces). The template name is cleaned up, having
its extension removed and any dots replaced by dashes (C<tr/./-/>) to be
able to form valid CSS classes.

=back

=head2 Settings

The following data is managed and made available to the template in the
C<view.settings> hash.

=over 4

=item C<block_indexing>

A boolean scalar holding whether or not robots should be blocked from
indexing the page.

=item C<theme_color>

A color to be set on the C<E<lt>meta name="theme-color"E<gt>> tag.

=back

=head2 Default Data

A default data hash can be set using
L<C<set_default_data>|/set_default_data>. This hash serves as a base for
data passed to L<C<render>|/render>, allowing the data in C<render> to
overwrite default values as needed.

This is particularly useful for data available at the time of view
initialization, which does not depend on the specific controller that
ultimately renders the view.

=head1 CONFIGURATION

=head2 tt

The C<tt> key may be used in the main L<Minima::App> configuration hash
to customize L<Template Toolkit|Template>.

By default, the following configuration is used:

    {
        OUTLINE_TAG => '%%',
        ANYCASE => 1,
        ENCODING => 'utf8',
    }

These can be overwritten. Additionally, if the app is in development
mode (see L<Minima::App/development>), C<DEBUG> is set to
C<DEBUG_UNDEF>.

=head2 template_ext

The C<template_ext> key may be used to set a default file extension for
templates. By default, F<ht> will be used. This extension is added
automatically to template file names if none is provided.

=head1 METHODS

=head2 new

    method new (app)

Constructs a new object. Requires a L<Minima::App> reference.

=head2 add_class

    method add_class ($class)

Adds the passed class name to the list of C<E<lt>mainE<gt>> classes.

=head2 add_header_css

    method add_header_css ($css)

Adds the passed CSS file name to the header CSS list.

=head2 add_header_script

    method add_header_script ($script)

Adds the passed script to the header script list.

=head2 add_include_path

    method add_include_path ($directory)

Adds the passed directory as a include path in conjunction with the main
directory (set by L<C<set_directory>|/set_directory>). This method can
be called multiple times to add multiple paths.

=head2 add_post

    method add_post ($post)

Adds the passed template name to the post-template list.

=head2 add_pre

    method add_pre ($pre)

Adds the passed template name to the pre-template list.

=head2 add_pre_body

    method add_pre_body ($pre)

Adds the passed template name to the pre-body template list.

=head2 add_script

    method add_script ($script)

Adds the passed script name to the list of scripts embedded in the body.

=head2 prepare_response

    method prepare_response ($response)

Sets the appropriate I<Content-Type> header on the provided
L<Plack::Response> object.

=head2 render

    method render ($data = {})

Renders the template with the passed data made available to it, as well
as the standard data (described in L<"Data"|/DATA>) and returns it.

To configure L<Template Toolkit|Template>, visit the
L<"Configuration"/CONFIGURATION> section. See also
L<C<set_default_data>|/set_default_data>.

=head2 set_block_indexing

    method set_block_indexing ($bool = 1)

Sets a boolean scalar to indicate if robots should be blocked from
indexing the page. Defaults to true.

=head2 set_compound_title

    method set_compound_title ($title, $description = undef)

Sets a secondary title, using the main title as primary, as well as
description.

    $v->set_title('Title');
    $v->set_compound_title('Page');
    # Results in: Title • Page

If no primaty title is already set, calling this method produces the
same effect as L<C<set_title>|/set_title>.

=head2 set_default_data

    method set_default_data ($data)

Sets a default data hash that will be used in rendering pages. The hash
provided in L<C<render>|/render> is merged with this default data hash.

=head2 set_directory

    method set_directory ($directory)

Sets the main directory where templates reside. If this method is not
called, the default F<templates> directory will be used.

=head2 set_name_as_class

    method set_name_as_class ($bool = 1)

Sets a boolean scalar to indicate whether the template name should be
added to the C<E<lt>mainE<gt>> CSS class list. This is particularly
useful to target a page on a CSS file by simply using C<.main.template>.
Defaults to true.

=head2 set_template

    method set_template ($title)

Sets the template name to be used. If no extension is present, the
extension set by the L<C<template_ext>|/template_ext> configuration key
(F<ht> by default) will be added. The template file name must not
contain a dot (C<.>), except for the one used in the extension.

=head2 set_title

    method set_title ($title, $description = undef)

Sets the title and description (optional).

=head1 SEE ALSO

L<Minima>, L<Minima::Controller>, L<Minima::View>, L<perlclass>.

=head1 AUTHOR

Cesar Tessarin, <cesar@tessarin.com.br>.

Written in September 2024.
