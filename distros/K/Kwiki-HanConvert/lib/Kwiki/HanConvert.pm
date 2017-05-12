package Kwiki::HanConvert;
use Kwiki::Plugin -Base;
use mixin 'Kwiki::Installer';
use Encode::HanConvert qw(simple trad);
our $VERSION = '0.01';

const class_id => 'han_convert';
const cgi_class => 'Kwiki::HanConvert::CGI';

sub register {
    my $registry = shift;
    $registry->add(hook => 'display:display', post => 'convert');
    $registry->add(toolbar => 'han_convert_button',
                   template => 'han_convert_button.html');
}

sub convert {
    my $hook = pop;
    my $display = $self;
    $self = $display->hub->load_class('han_convert');
    my ($page_content) = $hook->returned;
    my $ret;
    if($self->cgi->mode eq 'trad') {
        $ret = trad($page_content);
    } elsif($self->cgi->mode eq 'simp') {
        $ret = simple($page_content);
    } else {
        $ret = $page_content;
    }
    return $ret;
}

package Kwiki::HanConvert::CGI;
use base 'Kwiki::CGI';
cgi mode => qw(-utf8);

package Kwiki::HanConvert;

__DATA__

=head1 NAME

  Kwiki::HanConvert - Trad./Simp. Chinese convertor

=head1 INSTALLATION

    kwiki -install Kwiki::HanConvert

=head1 DESCRIPTION

This Kwiki plugin adds [Simp] and [Trad] on your toolbar, which conver
your page display to Simplified Chinese or Traditional Chinese on the
fly. The conversion is accomplished after page rendering, so the page
content is not changed.

=head1 COPYRIGHT

Copyright 2004 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut

__template/tt2/han_convert_button.html__
<a href="[% script_name %]?[% page_uri %]&mode=simp" title="Convert To Simplified Chinese">Simp</a>,
<a href="[% script_name %]?[% page_uri %]&mode=trad" title="Convert To Traditional Chinese">Trad</a>
