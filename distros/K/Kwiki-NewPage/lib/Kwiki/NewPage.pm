package Kwiki::NewPage;
use Kwiki::Plugin -Base;
use mixin 'Kwiki::Installer';
use Kwiki ':char_classes';
our $VERSION = '0.12';

const class_id => 'new_page';
const cgi_class => 'Kwiki::NewPage::CGI';

sub register {
    my $registry = shift;
    $registry->add(action => 'new_page');
    $registry->add(toolbar => 'new_page_button', 
                   template => 'new_page_button.html',
                  );
    $registry->add(prerequisite => 'edit');
}

sub new_page {
    my $error_msg = '';
    if ($self->cgi->button) {
        $error_msg = $self->check_page_name or do {
            my $page_uri =
              $self->pages->new_from_name($self->cgi->new_page_name)->uri;
            my $redirect = "action=edit&page_name=$page_uri";
            return $self->redirect($redirect);
        }
    }
    $self->render_screen(
        error_msg => $error_msg,
    );
}

sub check_page_name {
    my $page_name = $self->cgi->new_page_name;
    return "There is already a page named '$page_name'."
      if $self->pages->new_from_name($page_name)->exists;
    return "'$page_name' is an invalid page name. Can't contain spaces."
      if $page_name =~ /\s/;
    return "'$page_name' is an invalid page name. Invalid characters."
      unless $page_name =~ /^[$ALPHANUM]+$/;
    return;
}

package Kwiki::NewPage::CGI;
use Kwiki::CGI -base;

cgi new_page_name => -utf8;

package Kwiki::NewPage;
__DATA__

=head1 NAME 

Kwiki::NewPage - Kwiki New Page Plugin

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Brian Ingerson <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
__template/tt2/new_page_button.html__
<a href="[% script_name %]?action=new_page" accesskey="N" title="Create New Page">
[% INCLUDE new_page_button_icon.html %]
</a>
__template/tt2/new_page_button_icon.html__
New
__template/tt2/new_page_content.html__
[% screen_title = 'Create New Page' %]
<form method="post">
<p>Enter a new page name:</p>
<input type="text" size="20" maxlength="30" name="new_page_name" value="[% new_page_name %]" />
<input type="submit" name="button" value="CREATE" />
<br />
<br />
<span class="error">[% error_msg %]</span>
<input type="hidden" name="action" value="new_page">
</form>
<pre>


</pre>
