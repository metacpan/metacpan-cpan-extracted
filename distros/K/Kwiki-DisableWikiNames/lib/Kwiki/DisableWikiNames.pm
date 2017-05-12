package Kwiki::DisableWikiNames;

use 5.008005;
use strict;
use warnings;

use Kwiki::Plugin -Base;
use mixin 'Kwiki::Installer';

our $VERSION = '0.02';

const class_id => 'disable_wiki_names';
const class_title => "Disable WikiNames auto markup";

sub init {
    super;
}

sub register {
    my $registry = shift;
    $registry->add(preload => 'disable_wiki_names');
    $registry->add(hook => 'page:kwiki_link', pre => 'dwn_uri_hook');
}

sub dwn_uri_hook {   ## Adopted from Kwiki::CoolURI
    my $hook = pop;
    $hook->code(undef);
    my ($label) = @_;
    my $page_uri = $self->uri;
    if(!defined $label) {
      qq($page_uri);
    } else {
      my $class = $self->active? '' : ' class="empty"';
      qq(<a href="$page_uri"$class>$label</a>);
    }
}

1;
__END__
=head1 NAME

Kwiki::DisableWikiNames - Disable Kwiki WikiNames auto markup

=head1 SYNOPSIS

 $ cd /path/to/kwiki
 $ kwiki -add Kwiki::DisableWikiNames

=head1 DESCRIPTION

Disables automatic internal link creation for WikiNames

=head1 AUTHOR

Pavel V. Kaygorodov <pasha@inasan.ru>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by root

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
