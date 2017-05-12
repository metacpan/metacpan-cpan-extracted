package Kwiki::BreadCrumbs;
use Kwiki::Plugin -Base;
use mixin 'Kwiki::Installer';
our $VERSION = '0.12';

const class_id => 'bread_crumbs';

field trail => [];

sub init {
    return unless $self->is_in_cgi;
    super;
    my $bread_crumbs = $self->hub->cookie->jar->{bread_crumbs} || [];
    if ($self->hub->action eq 'display') {
        my $page_id = $self->pages->current->id;
        @$bread_crumbs = grep { $_ ne $page_id } @$bread_crumbs;
        unshift @$bread_crumbs, $page_id;
    }
    splice @$bread_crumbs, 10
      if @$bread_crumbs > 10;
    $self->trail($bread_crumbs);
    $self->hub->cookie->jar->{bread_crumbs} = $bread_crumbs;
}

sub register {
    my $registry = shift;
    $registry->add(status => 'bread_crumbs',
                   template => 'bread_crumbs.html',
                   show_if_preference => 'show_bread_crumbs',
                  );
    $registry->add(preference => $self->show_bread_crumbs);
}

sub show_bread_crumbs {
    my $p = $self->new_preference('show_bread_crumbs');
    $p->query('Show How Many Bread Crumbs?');
    $p->type('pulldown');
    my $choices = [
        0 => 0,
        4 => 4,
        6 => 6,
        8 => 8,
        10 => 10,
    ];
    $p->choices($choices);
    $p->default(0);
    return $p;
}

sub html {
    my @trail = @{$self->trail};
    my $show = $self->preferences->show_bread_crumbs->value;
    splice @trail, $show
      if @trail > $show;
    my $script_name = $self->config->script_name;
    my $pages = $self->hub->pages;
    "<hr />" . join ' &lt; ',
    map {
        my $page = $pages->new_page($_);
        sprintf "<a href=\"%s?%s\">%s</a>\n",
          $script_name,
          $page->uri,
          $page->title;
    } @trail;
}

__DATA__

=head1 NAME 

Kwiki::BreadCrumbs - Kwiki Bread Crumbs Plugin

=head1 SYNOPSIS

Show a trail of the last 5 pages viewed.

=head1 DESCRIPTION

=head1 AUTHOR

Brian Ingerson <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
__template/tt2/bread_crumbs.html__
<style>
div#bread_crumb_trail {
    font-size: small;
}
</style>
<div id="bread_crumb_trail">
[% hub.bread_crumbs.html %]
</div>
