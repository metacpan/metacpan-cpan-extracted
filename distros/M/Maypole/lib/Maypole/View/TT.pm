package Maypole::View::TT;
use base 'Maypole::View::Base';
use Maypole::Constants;
use Template;
use File::Spec::Functions qw(catdir tmpdir);
use Template::Constants qw( :all );

our $error_template;
{ local $/; $error_template = <DATA>; }

our $VERSION = '2.12';

my $debug_flags = DEBUG_ON;

use strict;

sub template {
  my ( $self, $r ) = @_;
  unless ($self->{tt}) {
    my $view_options = $r->config->view_options || {};
    if ($r->debug) {
      $view_options->{DEBUG} = $debug_flags;
    }

    $view_options->{POST_CHOMP} = 1 unless (exists $view_options->{POST_CHOMP});
    $self->{provider} = Template::Provider->new($view_options);
    $self->{tt}       = Template->new({
				       %$view_options,
				       LOAD_TEMPLATES => [ $self->{provider} ],
				      });
  }

  $self->{provider}->include_path([ $self->paths($r) ]);

  my $template_file = $r->template;

  my $ext = $r->config->template_extension;
  $template_file .= $ext if defined $ext;

  my $output;
  my $processed_ok = eval{$self->{tt}->process($template_file, { $self->vars($r) }, \$output );};
  if ($processed_ok) {
    $r->{output} = $output;
    return OK;
  } else {
    if ($@) {
      my $error = "fatal error in template '$template_file' : $@\nTT paths : " . join(', ',$self->paths($r)) . "\n";
      $r->warn($error);
      $r->{error} = $error;
    } else {
      my $error = "TT error for template '$template_file'\n" . $self->{tt}->error . "\nTT paths : " . join(', ',$self->paths($r)) . "\n";
      $r->warn($error);
      $r->{error} = $error;
    }
    return ERROR;
  }
}


sub report_error {
    my ($self, $r, $error, $type) = @_;
    my $output;

    # Need to be very careful here.
    my $tt = Template->new;
    unless (ref $r->{config}) {
      $r->warn("no config for this request");
      $error .= '<br> There was a problem finding configuration for this request';
      $r->{config} ||= {};
    }

    $r->warn("report_error - reporting error to user : $error\n");

    if ($tt->process(\$error_template,
		     { err_type => $type, error => $error,
		       config => $r->{config},
		       request => $r,
		       paths => [ $self->paths($r) ],
		       eval{$self->vars($r)} }, \$output )) {
        $r->{output} = $output;
        if ($tt->error) { $r->{output} = "<html><body>Even the error template
        errored - ".$tt->error."</body></html>"; }
        $r->{content_type}      ||= "text/html";
        $r->{document_encoding} ||= "utf-8";
        return OK;
    }
    return ERROR;
}


=head1 NAME

Maypole::View::TT - A Template Toolkit view class for Maypole

=head1 SYNOPSIS

    BeerDB->config->view("Maypole::View::TT"); # The default anyway

    # Set some Template Toolkit options
    BeerDB->config->view_options( {
        TRIM        => 1,
        COMPILE_DIR => '/var/tmp/mysite/templates',
    } );

    .....

    [% PROCESS macros %]

    [% pager %]

    [% link %]

    [% maybe_link_view %]

=head1 DESCRIPTION

This is the default view class for Maypole; it uses the Template Toolkit to fill
in templates with the objects produced by Maypole's model classes. Please see
the L<Maypole manual|Maypole::Manual>, and in particular, the
L<view|Maypole::Manual::View> chapter for the template variables available and
for a refresher on how template components are resolved.

The underlying Template toolkit object is configured through
C<$r-E<gt>config-E<gt>view_options>. See L<Template|Template> for available
options.

=over 4

=item template

Processes the template and sets the output. See L<Maypole::View::Base>

=item report_error

Reports the details of an error, current state and parameters

=back

=head1 TEMPLATE TOOLKIT INTRODUCTION

The Template Toolkit uses it's own mini language described in
L<Template::Manual::Directives>.

A simple example would be :

=over 4

re:[% subject %]

Dear [% title %] [% surname %],
Thank you for your letter dated [% your.date %]. This is to
confirm that we have received it and will respond with a more
detailed response as soon as possible. In the mean time, we
enclose more details of ...

=back

TT uses '[%' and '%]' (by default) to delimit directives within a template, and
the simple directives above just display the value of variable named within
those delimiters -- [% title %] will be replaced inline with the value of the
'title' variable passed in the 'stash' to the template when it is processed.

You can access nested data through the dot ('.') operator, which will
dereference array or hash elements, but can also be used to call methods on
objects, i.e. '[% name.salutation("Dear %s,") %]'. The other main operator is
underscore ('_'), which will concatonate strings or variables.

The value returned by a directive replaces the directive inline when the
template is processes, you can also SET a value which will not return anything,
or CALL a method or operation which will also not return anything.

You can specify expressions using the logical (and, or, not, ?:) and mathematic
operators (+ - * / % mod div).

Results of TT commands are interpolated in the place of the template tags, unless
using SET or CALL, i.e. [% SET foo = 1 %], [% GET foo.bar('quz'); %]

=over 4

[% template.title or default.title %]

[% score * 100 %]

[% order.nitems ? checkout(order.total) : 'no items' %]

=back

TT allows you to include or re-use templates through it's INCLUDE, PROCESS and
INSERT directives, which are fairly self explainatory. You can also re-use parts
of template with the BLOCK or MACRO directives.

Conditional and Looping constructs are simple and powerful, and TT provides an
inbuilt iterator and helper functions and classes that make life sweet.

Conditional directives are IF, UNLESS, ELSIF, ELSE and behave as they would in
perl :

=over 4

[% IF age < 10 %]
  Hello [% name %], does your mother know you're  using her AOL account?
[% ELSIF age < 18 %]
  Sorry, you're not old enough to enter (and too dumb to lie about your age)
[% ELSE %]
  Welcome [% name %].
[% END %]

[% UNLESS text_mode %] [% INCLUDE biglogo %] [% END %]

=back

Looping directives are FOREACH, LAST and BREAK.

FOREACH loops through a HASH or ARRAY processing the enclosed block for each
element.

Looping through an array

 [% FOREACH i = items %]
 [% i %]
 [% END %]

Looping through a hash

 [% FOREACH u IN users %]
 * [% u.key %] : [% u.value %]
 [% END %]

Looping through an array of hashes

 [% FOREACH user IN userlist %]
 * [% user.id %] [% user.name %]
 [% END %]

The LAST and BREAK directive can be used to exit the loop.

The FOREACH directive is implemented using the Template::Iterator module. A
reference to the iterator object for a FOREACH directive is implicitly available
in the 'loop' variable. The loop iterator object provides a selection of methods
including size(), max(), first(), last(), count(), etc

=over 4

  [% FOREACH item IN [ 'foo', 'bar', 'baz' ] -%]
    [%- "<ul>\n" IF loop.first %]
      <li>[% loop.count %]/[% loop.size %]: [% item %]
    [%- "</ul>\n" IF loop.last %]
  [% END %]

=back

See Template::Iterator for further details on looping and the Iterator.

You might notice the minus ('-') operator in the example above, it is used to
remove a newline before or after a directive so that you can layout the Template
logic as above but the resulting output will look exactly how you require it.

You will also frequently see comments and multi-line directives, # at the start
of a directive marks it as a comment, i.e. '[%# this is a comment %]'. A
multiline directive looks like :

 [% do.this;
    do.that;
    do.the_other %]

You can see that lines are terminated with a semi-colon (';') unless the
delimter ('%]') closes the directive.

For full details of the Template Toolkit see Template::Manual and
Template::Manual::Directives, you can also check the website, mailing list or
the Template Toolkit book published by O Reilly.

=head1 TEMPLATE PLUGINS, FILTERS AND MACROS

The Template Toolkit has a popular and powerful selection of Plugins and
Filters.

TT Plugins provide additional functionality within Templates, from accessing CGI
and databases directly, handling paging or simple integration with Class::DBI
(for those rare occasions where you don't actually need Maypole). See
L<Template::Manual::Plugins>.

One plugin that is indispensible when using Maypole and the Template View is
C<Template::Plugin::Class> -- This allows you to import and use any class
installed within a template. For example :

=over 4

[% USE foo = Class('Foo') %]
[% foo.bar %]

=back

Would do the equivilent of 'use Foo; Foo->bar;' in perl. See
L<Template::Plugin::Class> for details.

TT Filters process strings or blocks within a template, allowing you to
truncate, format, escape or encode trivially. A useful selection is included
with Template Toolkit and they can also be found on CPAN or can be written
easily. See L<Template::Manual::Filters>.

TT provides stderr and stdout filters, which allow you to write handy macros
like this one to output debug information to your web server log, etc :

=over 4

[% MACRO debug_msg(text)
    FILTER stderr; "[TT debug_msg] $text\n"; END;
%]

=back


TT Macros allow you to reuse small blocks of content, directives, etc. The MACRO
directive allows you to define a directive or directive block which is then
evaluated each time the macro is called. Macros can be passed named parameters
when called.

Once a MACRO is defined within a template or 'include'd template it can be used
as if it were a native TT directive. Maypole provides a selection of powerful
and useful macros in the templates/ directory of the package and these are used
in the beerdb and default templates. See the MACRO section of the
L<Template::Manual::Directives> documentation.

=head1 ACCESSING MAYPOLE VALUES

=head2 request

You can access the request in your templates in order to see the action, table, etc as well
as parameters passed through forms :

for example

Hello [% request.params.forename %] [% request.params.surname %] !

or 

Are you want to [% request.action %] in the [% request.table %] ?

=head2 config

You can access your maypole application configuration through the config variable :

<link base="[% config.uri_base %]"/>

=head2 object and objects

Objects are passed to the request using r->objects($arrayref) and are accessed in the templates
as an array called objects.

[% FOR objects %] <a href="[% config.uri_base %]/[% request.table %]/view/[% object.id %]"> [% object %] </a> [% END %]

=head1 MAYPOLE MACROS AND FILTERS

Maypole provides a collection of useful and powerful macros in the templates/factory/macros
 and other templates. These can be used in any template with [% PROCESS templatename %].

=head2 link

This creates an <A HREF="..."> to a command in the Apache::MVC system by
catenating the base URL, table, command, and any arguments.

=head2 maybe_link_view

C<maybe_link_view> takes something returned from the database - either
some ordinary data, or an object in a related class expanded by a
has-a relationship. If it is an object, it constructs a link to the view
command for that object. Otherwise, it just displays the data.

=head2 pager

This is an include template rather than a macro, and it controls the pager
display at the bottom (by default) of the factory list and search views/template.
It expects a C<pager> template argument which responds to the L<Data::Page> interface.

This macro is in the pager template and used as :

[% PROCESS pager %]

Maypole provides a pager for list and search actions, otherwise you can
provide a pager in the template using Template::Plugin::Pagination.

[% USE pager = Pagination(objects, page.current, page.rows) %]
...
[% PROCESS pager %]

The pager will use a the request action  as the action in the url unless the
pager_action variable is set, which it will use instead if available.

=head2 other macros

=head1 AUTHOR

Simon Cozens

=cut

1;

__DATA__
<html><head><title>Maypole error page</title>
<style type="text/css">
body { background-color:#7d95b5; font-family: sans-serif}
p { background-color: #fff; padding: 5px; }
pre { background-color: #fff; padding: 5px; border: 1px dotted black }
h1 { color: #fff }
h2 { color: #fff }
.lhs {background-color: #ffd; }
.rhs {background-color: #dff; }
</style>
</head> <body>
<h1> Maypole application error </h1>

<p> This application living at <code>[%request.config.uri_base%]</code>, 
[%request.config.application_name || "which is unnamed" %], has
produced an error. The adminstrator should be able to understand
this error message and fix the problem.</p>

<h2> Some basic facts </h2>

<p> The error was found in the [% err_type %] stage of processing
the path "[% request.path %]". The error text returned was:
</p>
<pre>
    [% error %]
</pre>

<h2> Request details </h2>

<table width="85%" cellspacing="2" cellpadding="1">
    [% FOR attribute = ["model_class", "table", "template", "path",
    "content_type", "document_encoding", "action", "args", "objects"] %]
    <tr> <td class="lhs" width="35%"> <b>[% attribute %]</b> </td> <td class="rhs" width="65%"> [%
    request.$attribute.list.join(" , ") %] </td></tr>
    [% END %]
    <tr><td colspan="2"></tr>
    <tr><td class="lhs" colspan="2"><b>CGI Parameters</b> </td></tr>
    [% FOREACH param IN request.params %]
    <tr> <td class="lhs" width="35%">[% param.key %]</td> <td class="rhs" width="65%"> [% param.value %] </td></tr>
    [% END %]
</table>

<h2> Website / Template Paths </h2>
<table width="85%" cellspacing="2" cellpadding="1">
<tr><td class="lhs" width="35%"> <b>Base URI</b> </td><td class="rhs" width="65%">[% request.config.uri_base %]</td></tr>
<tr><td class="lhs" width="35%"> <b>Paths</b> </td><td class="rhs" width="65%"> [% paths %] </td></tr>
</table>

<h2> Application configuration </h2>
<table width="85%" cellspacing="2" cellpadding="1">
    <tr><td class="lhs"  width="35%"> <b>Model </b> </td><td class="rhs" width="65%"> [% request.config.model %] </td></tr>
    <tr><td class="lhs"  width="35%"> <b>View </b> </td><td class="rhs" width="65%"> [% request.config.view %] </td></tr>
    <tr><td class="lhs" width="35%"> <b>Classes</b> </td><td class="rhs" width="65%"> [% request.config.classes.list.join(" , ") %] </td></tr>
    <tr><td class="lhs" width="35%"> <b>Tables</b> </td><td class="rhs" width="65%"> [% request.config.display_tables.list.join(" , ") %] </td></tr>
</table>

</body>
</html>
