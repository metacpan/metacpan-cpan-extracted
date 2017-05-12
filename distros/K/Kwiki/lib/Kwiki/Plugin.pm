package Kwiki::Plugin;
use Spoon::Plugin -Base;

stub 'class_id';
const cgi_class => '';
const config_file => '';
const css_file => '';
const javascript_file => '';
const screen_template => 'theme_screen.html';
const class_title_prefix => 'Kwiki';
const config_class => 'Kwiki::Config';

field cgi      => -init => '$self->hub->cgi';
field config   => -init => '$self->hub->config';
field users    => -init => '$self->hub->users';
field pages    => -init => '$self->hub->pages';
field template => -init => '$self->hub->template';
field preferences => 
      -init => '$self->users->current->preferences';

sub new {
    return $self if ref $self;
    super;
}

sub init {
    $self->init_cgi;
    $self->config->add_file($self->config_file);
    $self->hub->css->add_file($self->css_file);
    $self->hub->javascript->add_file($self->javascript_file);
}

sub init_cgi {
    my $class = $self->cgi_class
      or return;
    eval qq{require $class} unless $class->can('new');
    my $package = ref($self);
    field -package => $package, 'cgi';
    my $object = $class->new;
    $object->init;
    $self->cgi($object);
}

sub render_screen {
    $self->template_process($self->screen_template, 
        content_pane => $self->class_id . '_content.html',
        @_,
    );
}

sub template_process {
    $self->hub->css->add_file($self->css_file)
      if $self->css_file;
    my $template = shift;
    $self->template->process($template, 
        self => $self,
        $self->pages->current->all,
        $self->cgi->all, 
        @_,
    );
}

sub redirect {
    $self->hub->headers->redirect($self->redirect_url(@_));
    return '';
}

sub redirect_url {
    my $target = shift;
    return $target 
      if $target =~ /^(https?:|\/)/i or 
         $target =~ /\?/;
    CGI::url(-full => 1) . '?' . $target;
}

sub new_preference {
    $self->hub->preferences->new_preference(scalar(caller), @_);
}

__DATA__

=head1 NAME

Kwiki::Plugin - Kwiki Plugin Base Class

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
