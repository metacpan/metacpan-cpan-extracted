package Kwiki::Edit::AdvisoryLock;

use warnings;
use strict;
use Kwiki::Plugin '-Base';
use mixin 'Kwiki::Installer';
use URI::Escape;
our $VERSION = '0.01';

const class_title => 'Advisory Lock';
const class_id => 'advisory_lock';

sub register {
	my $registry = shift;
	$registry->add(action => 'unlock');
	$registry->add(hook => 'edit:edit',
		pre => 'lock_page',
		post => 'rewrite_links',
	);
	$registry->add(hook => 'edit:edit',
		post => 'add_warning'
	);
	$registry->add(hook => 'edit:edit',
		post => 'unlock_after_save',
	);
}

sub unlock {
	my $page_name = CGI::param('page_name');
	my $redirect = CGI::param('redirect');

	io->catfile($self->plugin_base_directory, 'edit', 'lock',
		$page_name)->unlink;
	$self->redirect($redirect);
}

sub unlock_after_save {
	if( $self->cgi->button eq $self->config->edit_save_button_text ) {
		io->catfile($self->plugin_directory, 'lock',
			$self->pages->current->title)->unlink;
	}
	return $_[-1]->returned;
}

sub lock_page {
	my $user = $self->hub->users->current->name;
	return if $self->cgi->button ne '' ||
		!$self->pages->current->is_writable ||
		$user eq $self->config->user_default_name;

	my $path = io->catdir($self->plugin_directory, 'lock')->mkpath;
	$path = io->catfile($path, $self->pages->current->title);
	$user > $path unless $path->exists;
}

sub rewrite_links {
	my $hook = pop;
	my $page_name = $self->pages->current->title;
	my $ret = $hook->returned;
	return $ret
		unless Kwiki::Edit::AdvisoryLock::own_lock($self, $page_name);
	$ret =~ s/(\<a.*?href\s*=\s*\")([^\"]+)(\"[^\>]*\>)/"$1?action=unlock;page_name=$page_name;redirect=".uri_escape($2).$3/gei;
	return $ret;
}

sub own_lock {
	my $page_name = shift;
	my $lock = io->catfile($self->plugin_base_directory, 'edit', 'lock',
		$page_name);
	$lock->exists ? $self->hub->users->current->name eq $lock->slurp : 0;
}

sub add_warning {
	my $hook = pop;
	my $page_name = $self->pages->current->title;
	my $ret = $hook->returned;
	return $ret if Kwiki::Edit::AdvisoryLock::own_lock($self, $page_name);
	return $ret unless io->catfile($self->plugin_base_directory, 'edit',
		'lock', $page_name)->exists;
	my $warning = Kwiki::Edit::AdvisoryLock::warning($self, $page_name);
	$ret =~ s/\<textarea/\<div class\=\"warning\"\>$warning\<\/div\>\<textarea/i;
	return $ret;
}

sub warning {
	my $page_name = shift;
	my $lock_file = io->catfile($self->plugin_base_directory, 'edit',
		'lock', $page_name);
	my $user = $lock_file->slurp;
	my $locktime = $self->hub->have_plugin('time_zone')
		? $self->hub->time_zone->format($lock_file->mtime)
		: $self->format_time($lock_file->mtime);

	return <<WARNING;
<h1>Another user may be editing this file!</h1>

<p>User $user started editing this page on $locktime. $user has yet to save
his/her edits. You can continue editing this page if you wish but a conflict
may occur if $user is still editing the page and plans to submit his/her
changes.</p>
WARNING
}

sub format_time {
	my $unix_time = shift;
	my $formatted = scalar gmtime $unix_time;
	$formatted .= ' GMT'
		unless $formatted =~ /GMT$/;
	return $formatted;
}

1; # End of Kwiki::Edit::AdvisoryLock
__DATA__

=head1 NAME

Kwiki::Edit::AdvisoryLock - Will warn the user if someone else might be editing
this page.

=head1 AUTHOR

Eric Anderson, C<< <eric at cordata.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2006 Eric Anderson, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

