package JavaScript::Framework::jQuery;

use 5.008.000;
use warnings;
use strict;
use Carp;

use Moose;
use MooseX::Types::Moose qw( Bool CodeRef HashRef Int );
use MooseX::Params::Validate;
use JavaScript::Framework::jQuery::Subtypes qw( libraryAssets pluginAssets );

our $VERSION = '0.07';

has 'library' => (
    is => 'rw',
    isa => libraryAssets,
    required => 1,
);

has 'plugins' => (
    is => 'rw',
    isa => pluginAssets,
);

has 'xhtml' => (
    is => 'rw',
    isa => Bool,
    default => sub { 1 },
);

has 'transient_plugins' => (
    is => 'rw',
    isa => Bool,
    default => sub { 1 },
);

has 'rel2abs_uri_callback' => (
    is => 'rw',
    isa => CodeRef,
    default => sub { sub { shift } },
);

no Moose;

=head1 NAME

JavaScript::Framework::jQuery - Generate markup and code for jQuery JavaScript framework

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

 use JavaScript::Framework::jQuery;

 my $jquery = JavaScript::Framework::jQuery->new(
    library => {
        src => [ '/static/js/jquery.min.js' ],
        css => [
            { href => 'theme/ui.all.css', media => 'screen' },
        ],
    },
    plugins => [
         {
             name => mcDropdown,
             library => {
                 src => [
                     '/js/jquery.mcdropdown.js',
                     '/js/jquery.bgiframe.js',
                 ],
                 css => [
                     { href => '/css/jquery.mcdropdown.css', media => 'all' },
                 ],
             },
         },
    ],
 );

 # alternative to configuring the plugin's asset locations in the
 # constructor parameters:

 $jquery->config_plugin(
    name => 'mcDropdown',
    library => {
        src => [
            '/js/jquery.mcdropdown.js',
            '/js/jquery.bgiframe.js',
        ],
        css => [
            { href => '/css/jquery.mcdropdown.css', media => 'all' },
        ],
    },
 );

 # add JavaScript constructor for the plugin

 $jquery->construct_plugin(
    name => 'mcDropdown',
    target_selector => '#category',
    srl_ul => '#categorymenu',
    options =>      # JavaScript object literal, sans curly braces
 'minRows : 8,      # no validation, broken JavaScript will pass unnoticed
 maxRows : 25,
 openSpeed : 500'
 );

 print $jquery->link_elements;
 print $jquery->script_src_elements;
 print $jquery->document_ready;

 # output

 <link type="text/css" href="theme/ui.all.css" rel="stylesheet" media="screen" />
 <link type="text/css" href="/css/jquery.mcdropdown.css" rel="stylesheet" media="all" />
 <script type="text/javascript" src="/static/js/jquery.min.js" />
 <script type="text/javascript" src="/js/jquery.mcdropdown.js" />
 <script type="text/javascript" src="/js/jquery.bgiframe.js" />
 <script type="text/javascript">
 <![CDATA[
 $(document).ready(function (){
 $("#category").mcDropdown("#categorymenu",{
 minRows : 8,
 maxRows : 25,
 openSpeed : 500
 });
 });
 ]]>
 </script>

=cut

=head1 DESCRIPTION

Manage composition and insertion of C<link> and C<script> elements and the
jQuery C<ready> call into generated HTML. 

Plugin modules provide support for individual jQuery plugins.

Framework plugins verify that the correct number of arguments will be passed to
JavaScript plugin constructors but perform no validation beyond
that.

This module provides four methods for inserting content into an HTML (or XHTML)
document:

=over

=item link_elements( )

For the mcDropdown plugin, for example, would print the LINK elements for the
jQueryUI and mcDropdown stylesheets. The output from this method should be
inserted in the HEAD element of the document:

 <link type="text/css" href="ui.all.css" rel="stylesheet" media="screen" />
 <link type="text/css" href="jquery.mcdropdown.css" rel="stylesheet" media="all" />

=item script_src_elements( )

Prints all the SCRIPT elements with SRC attribute. The output from this method
should be inserted in the HEAD element or somewhere before any calls to
code in the JavaScript files:

 <script type="text/javascript" src="jquery.min.js" />
 <script type="text/javascript" src="jquery.mcdropdown.js" />
 <script type="text/javascript" src="jquery.bgiframe.js" />

=item document_ready( )

Prints the jQuery $.ready function call and deletes any plugin objects created
in this response cycle from the queue (otherwise they would accumulate with
each request).

 <![CDATA[
 $(document).ready(function (){
 $("#inputid").mcDropdown("#ulid");
 });
 ]]>

Set transient_plugins to 0 if you wish to be able to fetch script and link
elements and $.ready function calls more than once.

=item constructor_calls( )

Returns only the text of the constructor calls for insertion into existing
code text. Useful for including the constructor calls in a template.

Set transient_plugins to 0 if you wish to be able to fetch script and link
elements and $.ready function calls more than once.

=back

Other accessors:

=over

=item transient_plugins( )

Set or get the value of transient_plugins. Takes 1 or 0.

=back

The data structure passed to the constructor provides the module with locations
for all the script and style assets required to make the jQuery plugins work.

The 'src' and 'css' buckets can contain multiple list items.

=cut

=head1 SUPPORTED PLUGINS

The following jQuery plugins are supported in this version:

=over

=item Superfish

L<http://users.tpg.com.au/j_birch/plugins/superfish/>

The Supersubs jQuery plugin may be used in conjunction with Superfish to improve
rendering of sub menu items.

=item FileamentGrpMenu

The FileamentGrpMenu framework plugin implements the interface required to
generate a jQuery constructor for the Filament Group jQuery menu plugin.

L<http://www.filamentgroup.com/lab/jquery_ipod_style_and_flyout_menus/>

=item mcDropdown

L<http://www.givainc.com/labs/mcdropdown_jquery_plugin.htm>

=item funcliteral

Add literal text to document_ready method's output.

=back

Support for other jQuery plugins will be added as the need arises. Contributions
are welcome.

=cut

=head1 METHODS

=head2 new( %params )

Parameters

=over

=item library

A reference to a hash:

 {
     src => [ 'jquery.js' ],
     css => [
         { href => 'jquery-ui.css', media => 'all' }
     ]
 }

This argument specifies the locations of the jQuery source and any stylesheets that
should be included in your content.

These settings will be used to form script elements with the src attribute for any
files included in the 'src' bucket, and link elements with the href attribute
for any stylesheets included in the 'css' bucket. The C<script_src_elements> and
C<link_elements> methods return the text of these HTML elements.

=item plugins

A reference to a hash with an element for each jQuery plugin that you want to
manage with this module. Each element contains a C<library> type data structure.

=item xhtml

Default: true

A boolean indicating whether markup should try to conform to XHTML or not.

=item transient_plugins

Default: true

If true, calling the C<document_ready> or C<constructor_calls> method clears
the list of plugin constructors and assets (JavaScript and CSS files) returned
by the C<script_src_elements>, C<link_elements>, C<document_ready> and
C<constructor_calls> methods.

=item rel2abs_uri_callback

A reference to a subroutine that takes a (possibly) relative URI and returns
and absolute URI.

In a Catalyst application this parameter might be passed with a value like:

  rel2abs_uri_callback => sub { $c->uri_for(shift) }

=back

=cut

=head2 config_plugin( %params )

Params

=over

=item name

Required Str

Short name for the plugin module. JavaScript::Framework::jQuery::Plugin::Superfish's
short name would be Superfish. This module calls require() against a package name
formed by inserting C<name> into the string
"JavaScript::Framework::jQuery::Plugin::<name>".

=item no_library

Optional Bool

If true indicates that you are intentionally omitting the C<library> parameter
from the call to C<config_plugin>.

Passing no_library with a true value and a library param in the same call to
C<config_plugin> will cause an exception.

The effect of omitting the library data when configuring the plugin is to omit
the JavaScript and CSS assets from the html markup returned by the
C<link_elements> and C<script_src_elements> methods. The only use case for this
is the C<funcliteral> plugin which is used to add to the text output by
C<constructor_calls> and C<document_ready> and so has no assets associated with
it.

=back

Set static variables for a particular plugin type.

The plugin must be configured with C<config_plugin> before calling C<construct_plugin>
or an exception will be raised.

=cut

sub config_plugin {
    my $self = shift;
    my %param = validated_hash(
        \@_,
        name => { isa => 'Str' },
        library => { isa => libraryAssets, optional => 1 },
        no_library => { isa => Bool, default => 0 },
    );

    if ($param{no_library} && $param{library}) {
        croak("'no_library' is true but a 'library' parameter was passed "
                . 'with a true value.');
    }
    if (!$param{library} && !$param{no_library}) {
        croak("'library' parameter is required unless 'no_library' parameter is passed "
                . 'with a true value');
    }

    my $plugclass = _mk_plugin_class_name($param{name});

    eval qq(require $plugclass);
    if ($@) {
        (my $pmpath = $plugclass) =~ s!::!/!g;
        if ($@ =~ qr/Can't locate ${pmpath}\.pm in \@INC/) {
            croak("Unknown plugin cannot be configured: $plugclass");
        }
        else {
            $@ && croak($@);
        }
    }

    $self->_stash_plugin_config($param{name}, $param{library});
    $self->_set_plugin_is_configured($param{name});
}

=head2 construct_plugin( %params )

Append a new jQuery plugin wrapper object to the queue.

=cut

sub construct_plugin {
    my $self = shift;

    unless (@_ && 0 == @_ % 2) {
        croak 'usage: construct_plugin($self, '
                . 'name => <plugin>, '
                . 'target_selector => <jQuery selector string> '
                . '[@plugin_args])';
    }

    my %param = @_;

    my $plugclass = _mk_plugin_class_name($param{name});

    unless ($self->_plugin_is_configured($param{name})) {
        croak("attempt to instantiate unconfigured plugin: $param{name} ($plugclass)");
    }

    $self->_enqueue_plugin($plugclass->new( %param ));

    return;
}

# return requested plugin's class name
sub _mk_plugin_class_name {
    return join('::' => __PACKAGE__, 'Plugin', shift);
}

=head2 add_func_calls( @funccalls )

Add list of literal text containing function calls (technically you can add any
text you like here, the text is opaque to this module).

=cut

sub add_func_calls {
    my ( $self, @funccalls ) = @_;

    require JavaScript::Framework::jQuery::Plugin::funcliteral;

    $self->config_plugin(
        name => 'funcliteral',
        no_library => 1,
    );

    my $obj =
        JavaScript::Framework::jQuery::Plugin::funcliteral->new(
            funccalls => [ @funccalls ],
        );
    $self->_enqueue_plugin($obj);

    return;
}

=head2 link_elements( )

Return markup for HTML LINK elements.

=cut

sub link_elements {
    my ( $self ) = @_;

    my @css;

    push @css, $self->_library_css;

    for my $config ($self->_plugin_config_list) {
        next unless $self->_plugin_used($config->{name});
        next unless $config->{library};
        push @css, @{$config->{library}{css}};
    }

    my (@text, $end);

    if ($self->xhtml) {
        $end = ' />';
    }
    else {
        $end = '>';
    }

    my %seen;

    for (@css) {
        my $href = $_->{href};
        next if $seen{$href}++;
        $href = $self->rel2abs_uri_callback->($href);
        push @text,
            qq(<link type="text/css" href="${href}" rel="stylesheet" media="$_->{media}") . $end;
    }

    return join("\n" => @text);
}

=head2 script_src_elements( )

Return markup for HTML SCRIPT (with SRC attr) elements.

=cut

sub script_src_elements {
    my ( $self ) = @_;

    my @src;

    push @src, $self->_library_src;

    for my $config ($self->_plugin_config_list) {
        next unless $self->_plugin_used($config->{name});
        next unless $config->{library};
        push @src, @{$config->{library}{src}};
    }

    my (@text, $end);

    #if ($self->xhtml) {
    #    $end = ' />';
    #}
    #else {
    #    $end = '></script>';
    #}

    $end = '></script>';

    my %seen;

    for my $src (@src) {
        next if $seen{$src}++;
        $src = $self->rel2abs_uri_callback->($src);
        push @text,
            qq(<script type="text/javascript" src="${src}") . $end;
    }

    return join("\n" => @text);
}

=head2 document_ready( )

Return the jQuery $(document).ready(...) statement.

=cut

sub document_ready {
    my ( $self ) = @_;

    my $docready = $self->constructor_calls;
    return '' unless defined $docready;

    $docready = qq|\$(document).ready(function (){
$docready
});|;

    if ($self->xhtml) {
        $docready = qq|//<![CDATA[
$docready
//]]>|;
    }

    # don't forget the script tags
    $docready = qq|<script type="text/javascript">
$docready
</script>|;

    return $docready;
}

=head2 constructor_calls( )

Return the text of the jQuery plugin constructor calls for inclusion in an existing
$(document).ready() text.

=cut

sub constructor_calls {
    my ( $self ) = @_;

    my @plugins = $self->_plugin_queue;
    return unless @plugins;

    my @cons;

    for my $obj (@plugins) {
        push @cons, $obj->cons_statement;
    }

    if ($self->transient_plugins) {
        $self->_dequeue_plugins;
    }

    return join("\n" => @cons);
}

sub _set_plugin_is_configured {
    my ( $self, $name ) = @_;
    $self->{configured_plugin}{$name} = 1;
    return;
}

sub _plugin_is_configured {
    my ( $self, $name ) = @_;
    return $self->{configured_plugin}{$name};
}

sub _plugin_queue {
    my ( $self ) = @_;

    my $objs = $self->{plugin_objects};
    return unless $objs;
    return @$objs;
}

sub _enqueue_plugin {
    my ( $self, $pluginobj ) = @_;

    push @{$self->{plugin_objects}}, $pluginobj;

    $self->_register_used_plugin_name($pluginobj->name);

    return;
}

sub _register_used_plugin_name {
    my ( $self, $name ) = @_;

    $self->{used_plugin_name}{$name} = 1;

    return;
}

sub _deregister_used_plugin_name {
    my ( $self, $name ) = @_;

    delete $self->{used_plugin_name}{$name};

    return;
}

sub _plugin_used {
    my ( $self, $name ) = @_;

    return $self->{used_plugin_name}{$name};
}

sub _dequeue_plugins {
    my ( $self, $plugin ) = @_;

    if ($self->{plugin_objects}) {
        @{$self->{plugin_objects}} = ();
    }
    if ($self->{used_plugin_name}) {
        %{$self->{used_plugin_name}} = ();
    }

    return;
}

sub _library_css {
    my ( $self ) = @_;
    my $css = $self->library->{css};
    return unless $css;
    return @$css;
}

sub _library_src {
    my ( $self ) = @_;
    my $src = $self->library->{src};
    return unless $src;
    return @$src;
}

# stash a jQuery plugin's asset locations and HTML element attributes
sub _stash_plugin_config {
    my ( $self, $name, $library ) = @_;
    $self->{plugin_config}{$name} = $library;
    push @{ $self->{plugin_config_list} }, { name => $name, library => $library };
}

# fetch a stashed jQuery plugin configuration (asset locations)
sub _plugin_config {
    my ( $self, $plugclass ) = @_;
    $self->{plugin_config}{$plugclass};
}

sub _plugin_config_list {
    my ( $self, $plugclass ) = @_;

    my $list = $self->{plugin_config_list};
    return unless $list;
    return @$list;
}

# fetch the list of plugins' css hashes
sub _plugin_config_css {
    my ( $self, $plugclass ) = @_;
    my $css = $self->_plugin_config($plugclass)->{css};
    return unless $css;

    return @$css;
}

# fetch the list of plugins' src hashes
sub _plugin_config_src {
    my ( $self, $plugclass ) = @_;
    my $src = $self->_plugin_config($plugclass)->{src};
    return unless $src;

    return @$src;
}

=head2 BUILD( )

See L<Moose::Cookbook::Basics::Recipe11>

=cut

sub BUILD {
    my $self = shift;

    my $plugins = $self->plugins;
    return unless $plugins;

    for my $pi (@$plugins) {
        $self->config_plugin(
            name => $pi->{name},
            library => $pi->{library},
        );
    }
}


1;

__END__

=head1 AUTHOR

David P.C. Wollmann, C<< <converter42 at gmail.com> >>

=head1 BUGS

This is ALPHA code. The interface(s) may change or break.

Please report any bugs or feature requests to C<bug-javascript-framework-jquery at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=JavaScript-Framework-jQuery>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc JavaScript::Framework::jQuery


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=JavaScript-Framework-jQuery>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/JavaScript-Framework-jQuery>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/JavaScript-Framework-jQuery>

=item * Search CPAN

L<http://search.cpan.org/dist/JavaScript-Framework-jQuery/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 David P.C. Wollmann, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

