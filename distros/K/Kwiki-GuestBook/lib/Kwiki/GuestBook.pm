package Kwiki::GuestBook;
use Kwiki::Plugin -Base;
use mixin 'Kwiki::Installer';
our $VERSION = '0.13';

const class_id => 'guest_book';
const css_file => 'css/guest_book.css';

sub register {
    my $registry = shift;
    $registry->add(action => 'guest_book');
    $registry->add(prerequisite => 'user_name');
    $registry->add(hook => 'user_name:check_user_name', post => 'update');
    $registry->add(toolbar => 'guest_book_button', 
                   template => 'guest_book_button.html',
                  );
}

sub guest_book {
    my $user_db = $self->user_db->rdonly;
    my @pages = map {
        $self->pages->new_page($_);
    } sort {lc($a) cmp lc($b)} keys %{$user_db};
    $user_db->close;
    $self->render_screen(pages => \@pages);
}

sub update {
    my $hook = pop;
    my ($returned) = $hook->returned;
    return $returned unless $returned eq '1';
    $self = $self->hub->guest_book;
    my $preference = shift;
    $self->remove_guest($preference->value);
    $self->add_guest($preference->new_value);
}

sub add_guest {
    $self->user_db->rdwr->{(shift || return)} = 1;
}

sub remove_guest {
    delete $self->user_db->rdwr->{(shift)};
}

sub user_db {
    my $db = io($self->plugin_directory . '/user_name.db');
    $db->utf8->dbm('DB_File::Lock');
}

__DATA__

=head1 NAME 

Kwiki::GuestBook - Kwiki Guest Book Plugin

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
__template/tt2/guest_book_button.html__
<a href="[% script_name %]?action=guest_book" accesskey="g" title="Guest Book">
[% INCLUDE guest_book_button_icon.html %]
</a>
__template/tt2/guest_book_button_icon.html__
Guests
__template/tt2/guest_book_content.html__
[% screen_title = "Guest Book" %]
<div class="guest_book">
<p>
[% pages.size || 0 %] Guests:
</p>
<ul>
[% FOR page = pages %]
<li>[% page.kwiki_link %]
[% END %]
</ul>
<em>Set your user name in <a href="[% script_name %]?action=user_preferences">Preferences</a></em>
</div>
