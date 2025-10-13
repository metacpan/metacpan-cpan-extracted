use v5.40;
use experimental 'class';

class Minima::View::HTML :isa(Minima::View);

use Carp;
use Path::Tiny;
use Template;
use Template::Constants qw/ :debug /;
use utf8;

field $app                  :param;
field @include;
field $template;
field @before_template;
field @after_template;
field $default_data         = {};

field %settings = (
    block_indexing => 1,    # block robots with a <meta>
    name_as_class => 1,     # include template name in @classes
    theme_color => '',      # hex color for the <meta theme-color>
);

field %content = (
    title => undef,
    description => undef,
    header_scripts => [],   # scripts to be loaded in <head>
    header_css => [],       # CSS to be loaded in <head>
    body_open => [],        # used right after the opening of <body>
    body_close => [],       # used right before the closing of </body>
    scripts => [],          # scripts to be embedded directly in <body>
    classes => [],          # classes added to <main> or <body>
);

ADJUST {
    my $config = $app->config;

    $content{title} = $config->{default_title} // '';

    $settings{block_indexing} = $config->{block_indexing} // 1;
    $settings{name_as_class} = $config->{name_as_class} // 1;
    $settings{theme_color} = $config->{theme_color} // '';

    if (exists $config->{templates_dir}) {
        if (ref $config->{templates_dir} eq ref []) {
            $self->add_directory($_)
                for reverse @{ $config->{templates_dir} };
        }
    } else {
        $self->add_directory('js');
        $self->add_directory('templates');
    }
}

method add_directory        ($d) { unshift @include, $app->path($d) }
method clear_directories         { @include = () }
method set_template         ($t) { $template = $self->_ext($t) }
method add_before_template  ($p) { push @before_template, $self->_ext($p) }
method add_after_template   ($p) { push @after_template, $self->_ext($p) }
method set_default_data     ($d) { $default_data = $d }

method set_block_indexing   ($n = 1) { $settings{block_indexing} = $n }
method set_name_as_class    ($n = 1) { $settings{name_as_class} = $n }
method set_theme_color      ($c) { $settings{theme_color} = $c }

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

method set_description      ($d) { $content{description} = $d }
method add_header_script    ($s) { push @{$content{header_scripts}}, $s }
method add_header_css       ($c) { push @{$content{header_css}}, $c }
method add_script           ($s) { push @{$content{scripts}}, $s }
method add_class            ($c) { push @{$content{classes}}, $c }

method add_body_open ($p)
{
    push @{$content{body_open}}, $self->_ext($p)
}

method add_body_close ($p)
{
    push @{$content{body_close}}, $self->_ext($p)
}

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
        INCLUDE_PATH => \@include,
        OUTLINE_TAG => '%%',
        ANYCASE => 1,
        ENCODING => 'utf8',
    );
    my $tt_app_config = $app->config->{tt} // {};
    my %tt_config = ( %tt_default, %$tt_app_config );
    my $tt = Template->new(\%tt_config);

    # Render
    my ( $body, $r );

    for my $t (@before_template, $template, @after_template) {
        $r = $tt->process($t, $data, \$body);
        croak "Failed to load template `$t` (include path: `@include`): ",
              $tt->error, "\n" unless $r;
    }

    utf8::encode($body);
    $body;
}

method _ext ($file)
{
    my $ext = $app->config->{template_ext} // 'ht';
    $file = "$file.$ext" unless $file =~ /\.\w+$/;
    $file;
}

__END__

=encoding utf8

=head1 NAME

Minima::View::HTML - Render HTML views

=head1 SYNOPSIS

    use Minima::View::HTML;

    my $view = Minima::View::HTML->new(app => $app);

    $view->add_directory('templates'); # where templates reside
    $view->set_template('home');
    $view->set_title('Minima');
    $view->add_script('global.js');

    my $body = $view->render({ data => ... });

=head1 DESCRIPTION

Minima::View::HTML renders HTML templates with
L<Template Toolkit|Template>, providing a simple interface and a
versatile set of data and settings.

It holds a reference to a L<Minima::App> object, mainly to access the
configuration hash, where defaults may be defined to customize its
behaviour.

=head2 Principle of Operation

In short, Minima::View::HTML manages data and assembles a sequence of
templates. This data can be maintained directly by the view (page title,
scripts to include, etc. — see L<"Data"|/DATA>) or passed right at the
L<C<render>|/render> call (commonly model or database data — see
L</Custom Data>).

The sequence always contains a single main template (set with
L<C<set_template>|/set_template>) and two optional sets to be included
before and after the main template (set with
L<C<add_before_template>|/add_before_template> and
L<C<add_after_template>|/add_after_template>). A typical use is to
render a header before and a footer after the main content.

Template names are resolved against the include paths, which by default
contain F<template> and F<js>. This list can be managed with
L<C<add_directory>|/add_directory>,
L<C<clear_directories>|/clear_directories> and the
L<C<templates_dir>|/templates_dir> configuration key. Extensions may be
omitted, as L<C<template_ext>|/template_ext> is automatically applied.

B<Note:> Minima::View::HTML works in UTF-8 and encodes the body response
accordingly.

=head1 DATA

Data handled by Minima::View::HTML is grouped as content and settings.
How this data is used ultimately depends on the template. See the
templates generated by L<minima(1)|minima> for examples.

Each item has at least one method to manipulate it (see
L<"Methods"|/METHODS>).

=head2 Content

The following data is managed and made available to template in the
C<view> hash.

=over 4

=item C<title>

Scalar containing the page title.

=item C<description>

Scalar containing the page description (used in the C<E<lt>metaE<gt>>
tag).

=item C<header_scripts>

A list of scripts to be included in the header.

=item C<header_css>

A list of linked CSS to be included in the header.

=item C<body_open>

A list of templates to be included immediately after the opening
C<E<lt>bodyE<gt>> tag, providing a useful insertion point.

=item C<body_close>

A list of templates to be included immediately before the closing
C<E<lt>bodyE<gt>> tag, providing a useful insertion point.

=item C<scripts>

A list of scripts to be embeded directly at the end of
C<E<lt>bodyE<gt>>.

=item C<classes>

A list of CSS classes to be included in C<E<lt>mainE<gt>> or
C<E<lt>bodyE<gt>>. Before being passed to the view, the class list
will be converted into a scalar (with classes separated by spaces).

This list may include the template name, if
L<C<name_as_class>|/name_as_class> is set. In this case, the template
name is cleaned up, having its extension removed and any dots replaced
by dashes (C<tr/./-/>) to be able to form valid CSS classes.

=back

=head2 Settings

The following data is managed and made available to the template in the
C<view.settings> hash. Each of these keys can also be set directly in
the L<Minima::App> configuration hash.

=over 4

=item C<block_indexing>

A boolean scalar holding whether or not robots should be blocked from
indexing the page. Defaults to true.

=item C<name_as_class>

A boolean scalar holding whether or not the template name should be
included in L<C<classes>|/classes>. Defaults to true.

=item C<theme_color>

A color to be set on the C<E<lt>meta name="theme-color"E<gt>> tag.

=back

=head2 Custom Data

Custom data can also be passed directly at the L<C<render>|/render>
call, which accepts a hash where keys will become variables available to
the templates.

A default data hash can also be set using
L<C<set_default_data>|/set_default_data>. This hash serves as a base for
data passed to L<C<render>|/render>, allowing the data in
L<C<render>|/render> to overwrite default values as needed.

This is particularly useful for data available at the time of view
initialization, which does not depend on the specific controller method
that ultimately renders the view (i.e. user data applicable for all
methods of the controller).

=head1 CONFIGURATION

In addition to the L<settings|/Settings> keys, the following options are
available in the main L<Minima::App> configuration hash.

=head2 default_title

Sets a default title, avoiding the need to call
L<C<set_title>|/set_title> on each page, and enabling the practical use
of L<C<set_compound_title>|/set_compound_title>.

=head2 tt

The C<tt> key may be used to customize L<Template Toolkit|Template>. By
default, the following configuration is used:

    {
        OUTLINE_TAG => '%%',
        ANYCASE => 1,
        ENCODING => 'utf8',
    }

Any of these may be overwritten.

=head2 template_ext

The C<template_ext> key may be used to set a default file extension for
templates. By default, F<ht> will be used. This extension is added
automatically to template file names if none is provided.

=head2 templates_dir

List of directories forming the template include path. If this key
exists but is not a valid list reference, the include path remains
empty. If this key does not exist, the include path list will contain
F<templates> and F<js> by default.

See also: L<C<add_directory>|/add_directory> and
L<C<clear_directories>|/clear_directories>.

=head1 METHODS

=head2 new

    method new (app)

Constructs a new object. Requires a L<Minima::App> reference.

=head2 add_after_template

    method add_after_template ($template)

Adds the passed template name to the post-template list.

=head2 add_before_template

    method add_before_template ($template)

Adds the passed template name to the pre-template list.

=head2 add_body_close

    method add_body_close ($template)

Adds the passed template name to the template list for the insertion
point immediatelly before the closing C<E<lt>/bodyE<gt>> tag.

If no file extension is provided, the one defined by the
L<C<template_ext>|/template_ext> configuration key is automatically
added.

=head2 add_body_open

    method add_body_open ($template)

Adds the passed template name to the template list for the insertion
point immediatelly after the opening C<E<lt>bodyE<gt>> tag.

If no file extension is provided, the one defined by the
L<C<template_ext>|/template_ext> configuration key is automatically
added.

=head2 add_class

    method add_class ($class)

Adds the passed class name to the list of L<C<classes>|/classes>.

=head2 add_directory

    method add_directory ($directory)

Adds the given directory to the include path, giving it precedence over
previously added ones. This method can be called multiple times to build
a search path where the most recently added directory is checked first.
The include list can be emptied with
L<C<clear_directories>|/clear_directories>.

See also: L<C<templates_dir>|/templates_dir>.

=head2 add_header_css

    method add_header_css ($css)

Adds the passed CSS file name to the header CSS list.

=head2 add_header_script

    method add_header_script ($script)

Adds the passed script to the header script list.

=head2 add_script

    method add_script ($script)

Adds the passed script name to the list of scripts embedded in the body.

=head2 clear_directories

    method clear_directories

Empties the template include path list.

See also: L<C<add_directory>|/add_directory> and
L<C<templates_dir>|/templates_dir>.

=head2 prepare_response

    method prepare_response ($response)

Sets the appropriate I<Content-Type> header on the provided
L<Plack::Response> object.

=head2 render

    method render ($data = {})

Renders the template with the passed data made available to it, as well
as the standard data (described in L<"Data"|/DATA>) and returns it. Keys
in the data hash become variables at the template.

To configure L<Template Toolkit|Template>, see the
L<"Configuration"|/CONFIGURATION> section. See also
L<C<set_default_data>|/set_default_data>.

=head2 set_block_indexing

    method set_block_indexing ($bool = 1)

Sets the boolean scalar L<C</block_indexing>> to indicate if robots
should be blocked from indexing the page. Defaults to true.

=head2 set_compound_title

    method set_compound_title ($title, $description = undef)

Appends a secondary title to the main title, separated by a middle dot
(C<•>). Optionally sets the description.

    $v->set_title('Title');
    $v->set_compound_title('Page');
    # Results in: Title • Page

If no primary title is set, this behaves like
L<C<set_title>|/set_title>. This method is particularly useful in
combination with L<C<default_title>|/default_title>.

=head2 set_default_data

    method set_default_data ($data)

Sets a default data hash that will be used in rendering pages. The hash
provided in L<C<render>|/render> is merged over this default data hash.

=head2 set_description

    method set_description ($description)

Sets the L<C</description>> of the page.

=head2 set_name_as_class

    method set_name_as_class ($bool = 1)

Sets the boolean scalar L<C</name_as_class>> to indicate whether the
template name should be added to the L<C</classes>> list. Useful to
target a page on a CSS file by simply using i.e. C<.main.template>.
Defaults to true.

=head2 set_template

    method set_template ($name)

Sets the template name to be used. If no extension is present, the
extension set by the L<C<template_ext>|/template_ext> configuration key
(F<ht> by default) will be added. The template file name must not
contain a dot (C<.>), except for the one used in the extension.

=head2 set_title

    method set_title ($title, $description = undef)

Sets the L<C<title>|/title> and L<C<description>|/description>
(optional). The title may also be set with
L<C<default_title>|/default_title>. See also
L<C<set_compound_title>|/set_compound_title>.

=head2 set_theme_color

    method set_theme_color ($color)

Sets the L<C<theme_color>|/theme_color>.

=head1 SEE ALSO

L<Minima>, L<Minima::Controller>, L<Minima::View>, L<perlclass>.

=head1 AUTHOR

Cesar Tessarin, <cesar@tessarin.com.br>.

Written in September 2024.
