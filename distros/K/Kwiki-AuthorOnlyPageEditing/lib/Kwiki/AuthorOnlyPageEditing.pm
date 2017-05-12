package Kwiki::AuthorOnlyPageEditing;
use Kwiki::Plugin -Base;
our $VERSION = '0.01';

const class_id => 'aope';
const cgi_class => 'Kwiki::AuthorOnlyPageEditing::CGI';

sub register {
    my $registry = shift;
    $registry->add(hook => 'page:store', pre => 'check_token');
    $registry->add(hook => 'edit:edit', post => 'modify_form');
}

sub modify_form {
    my $hook = pop;
    my $page_name = $self->cgi->page_name;
    my $edit = $self;
    $self = $edit->hub->load_class('aope');

    my $page = $self->pages->new_from_name($page_name);
    my ($king) = $hook->returned;
    unless(-f $page->file_path && !$self->token_path($page)->exists) {
        $king =~ s{(<textarea[^>]*?>)}
            {<span>Page token:</span><input name="token" /><br/>\n$1}i;
    }
    return $king;
}

sub check_token {
    my $hook = pop;
    my $page = $self;
    $self = $page->hub->load_class('aope');
    if(-f $page->file_path) {
        my $token = $self->find_token($page);
        return unless $token;
        $hook->code(undef) unless($self->cgi->token eq $token);
    } else {
        $self->associate($self->cgi->token,$page) if($self->cgi->token);
    }
}

sub token_path {
    my $page = shift;
    io->catfile($self->plugin_directory,$page->id);
}

sub associate {
    my ($token,$page) = @_;
    my $i = $self->token_path($page)->assert;
    $i->print($token);
}

sub find_token {
    my $page = shift;
    my $i = $self->token_path($page);
    return $i->getline if $i->exists;
}

package Kwiki::AuthorOnlyPageEditing::CGI;
use base 'Kwiki::CGI';
cgi token => qw(-utf8 -newlines);

package Kwiki::AuthorOnlyPageEditing;

__DATA__

=head1 NAME

Kwiki::AuthorOnlyPageEditing - Only the author of the page can edit it

=head1 INSTALLATION

This Kwiki Plugin is installed, as all other general plugins, by:

    kwiki -install Kwiki::AuthorOnlyPageEditing

No further setup would be required.

=head1 DESCRIPTION

Basiclly a Kwiki site lets all people and randomly edit any page they
want.  This plugin provide a simple mechanism to let people have their
own page, and no one else can edit.

The idea is simple: each new page have an associated token, if one
page is created with that token, then, upon editing, users will be
asked to input the token value. The modified content will be stored
only if the token is correct.

if you don't give a token upon new page creation, then this page will
be a token-less page, which would leave it just as a unprotected page,
and everone can modify it.

=head1 COPYRIGHT

Copyright 2004 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut

