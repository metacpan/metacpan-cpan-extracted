package Kwiki::CoolURI;
use strict;
use warnings;
use Kwiki::Plugin -Base;
use mixin 'Kwiki::Installer';

our $VERSION = '0.04';

const class_id => 'cool_uri';
const class_title => "Cool URIs don't change";

sub init {
    super;
    $self->hub->template->add_path('plugin/cool_uri/template/tt2');
    my $formatter = $self->hub->load_class('formatter');
    $formatter->table->{forced} = 'Kwiki::CoolURI::ForcedLink';
}

sub register {
    my $registry = shift;
    $registry->add(preload => 'cool_uri');
    $registry->add(hook => 'page:kwiki_link', pre => 'uri_hook');
}

sub uri_hook {
    my $hook = pop;
    $hook->code(undef);
    my ($label) = @_;
    my $page_uri = $self->uri;
    $label = $self->title
      unless defined $label;
    my $class = $self->active
      ? '' : ' class="empty"';
    qq(<a href="$page_uri"$class>$label</a>);
}

package Kwiki::CoolURI::ForcedLink;
use base 'Kwiki::Formatter::ForcedLink';

sub html {
    $self->matched =~ $self->pattern_start;
    my $target = $1;
    my $text = $self->escape_html($target);
    my $class = $self->hub->pages->new_from_name($target)->exists
      ? '' : ' class="empty"';
    return qq(<a href="$target"$class>$target</a>);
}

package Kwiki::CoolURI;
__DATA__

=head1 NAME 

Kwiki::CoolURI - makes the Kwiki url cleaner

=head1 SYNOPSIS

 $ cd /path/to/kwiki
 $ kwiki -add Kwiki::CoolURI

=head1 DESCRIPTION

Changes the internal links that Kwiki create. Instead of
/index.cgi?SandBox, it will just be /SandBox.

It only changes the url for the display plugin. Edit will still look
like /index.cgi?action=edit&page_name=SandBox.

=head2 Configuration

Kwiki needs to be able to read request on the form /SandBox. With
Apache this can be solved by putting the following mod_rewrite config
in a .htaccess file in the directory where index.cgi is located.

 RewriteEngine  on
 RewriteCond    $1 !(css/|icons/|index.cgi|local/|palm90.png|plugin/|theme/)
 RewriteRule    ^(.*)$ index.cgi?action=display&page_name=$1 [L]

If you add new top directories, or files, that you still want to be
readable, you have to add them in the RewriteCond.

=head1 BUGS

Does not currently fix the redirect that for instance happens after an
edit.

Should use new Kwiki 0.37 hooks.

The mod_rewrite config could probably be better.

The code is just copied from the original methods and slightly changed
to output different urls. If Kwiki had a way to configure what the
link urls should look like, this plugin wouldn't be needed.

=head1 AUTHOR

Jon Åslund

=head1 COPYRIGHT

Copyright (c) 2005. Jon Åslund. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

Cool URIs don't change L<http://www.w3.org/Provider/Style/URI.html>

=cut
__plugin/cool_uri/template/tt2/home_button.html__
<a href="[% main_page %]" accesskey="h" title="Home Page">
[% INCLUDE home_button_icon.html %]
</a>
