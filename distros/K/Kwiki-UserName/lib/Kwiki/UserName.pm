package Kwiki::UserName;
use Kwiki::Plugin -Base;
use mixin 'Kwiki::Installer';
use Kwiki ':char_classes';
our $VERSION = '0.14';

const class_id => 'user_name';
const css_file => 'user_name.css';

sub register {
    my $registry = shift;
    $registry->add(preload => 'user_name');
    $registry->add(preference => $self->user_name);
}

sub user_name {
    my $p = $self->new_preference('user_name');
    $p->query('Enter a KwikiUserName to identify yourself.');
    $p->type('input');
    $p->size(15);
    $p->edit('check_user_name');
    $p->default('');
    return $p;
}

sub check_user_name {
    my $preference = shift;
    my $value = $preference->new_value;
    $self->utf8_decode($value);
    return unless length $value;
    return $preference->error('Must be all alphanumeric characters.')
      unless $value =~ /^[$ALPHANUM]+$/;
    return $preference->error('Must be less than 30 characters.')
      unless length($value) < 30;
    $self->users->current(undef);
    return 1;
}

__DATA__

=head1 NAME 

Kwiki::UserName - Kwiki User Name Plugin

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
__css/user_name.css__
div#user_name_title {
    font-size: small;
    float: right;
}
__template/tt2/user_name_title.html__
<div id="user_name_title">
<em>(You are 
<a href="[% script_name %]?action=user_preferences">
[%- hub.users.current.name || 'an UnknownUser' -%]
</a>)
</em>
</div>
