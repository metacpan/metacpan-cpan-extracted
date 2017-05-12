package Kwiki::Edit::ContentionManagement;

use warnings;
use strict;
use Kwiki::Plugin '-Base';
use mixin 'Kwiki::Installer';
our $VERSION = '0.01';

const class_title => 'Contention Management';
const class_id => 'contention_management';

sub register {
	my $registry = shift;

	$registry->add(hook => 'edit:edit',
		pre => 'contention_check'
	);
}

sub contention_check {
	my $hook = pop;
	return if $self->cgi->button ne $self->config->edit_save_button_text;

	my $page = $self->pages->current;
	if ($page->modified_time != $self->cgi->page_time) {
		my $ret = $self->render_screen(
			page_time => $page->modified_time);
		my $warning = Kwiki::Edit::ContentionManagement::warning(
			$self, $page);
		$ret =~ s/\<textarea/\<div class\=\"warning\"\>$warning\<\/div\>\<textarea/i;
		$hook->cancel;
		return $ret;
	}
}

sub warning {
	my $page = shift;
	my $edituser = $page->metadata->edit_by || 'UnknownUser';
	my $edittime = $page->edit_time;

	return <<WARNING;
<h1>$edituser edited this file on $edittime!</h1>

<p>While you were editing this page $edituser saved changes to it. You can
continue with your save but you will overwrite the changes made by the
$edituser.</p>

<p>You may also get this message if you saved some changes and then used
your browser's back button to return to the Edit screen and make more
changes. Always use the Kwiki Edit button to get to the Edit screen.
</p>
WARNING
}

1; # End of Kwiki::Edit::ContentionManagement

__DATA__
=head1 NAME

Kwiki::Edit::ContentionManagement - Allows the user to do something when
contention occurs besides starting over!

=head1 SYNOPSIS

=over

=item

User 1 starts editing the page

=item

User 2 starts editing the page.

=item

User 1 saves their changes

=item

User 2 saves their changes

=item

User 2 changes don't get saved yet. Instead they get a message telling them
about the contention but their text box still exists and they can still edit
the content. The make a few edits incorporating the changes already on the page
and then hit save.

=item

User 2's changes squash any change that User 1 made (hope User 2 got all of
them from User 1).

=item

User 2 is not cursing Kwiki because it now lets them submit their changes
instead of simply displaying an error message and clearing out 3 hours of work
they just did because User 1 made a quick change while User 2 was editing the
stupid file!

=back

=head1 AUTHOR

Eric Anderson, C<< <eric at cordata.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2006 CorData, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

