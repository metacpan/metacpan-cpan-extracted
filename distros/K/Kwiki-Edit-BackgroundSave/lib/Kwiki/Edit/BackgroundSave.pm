package Kwiki::Edit::BackgroundSave;

use warnings;
use strict;
use Kwiki::Plugin '-Base';
use mixin 'Kwiki::Installer';
our $VERSION = '0.02';

const class_title => 'Background Save';
const class_id => 'background_save';
const javascript_file => 'background_save.js';
const config_file => 'background_save.yaml';

sub register {
	my $registry = shift;

	$registry->add(prerequisite => 'prototype');
	$registry->add(preload => $self->class_id);
	$registry->add(action => 'background_save');
	$registry->add(hook => 'edit:edit',
		post => 'add_button'
	);
	$registry->add(hook => 'headers:value',
		post => 'add_x_json_header'
	);
}

sub background_save {
	my $page = $self->hub->pages->current;
	if( $page->modified_time != CGI::param('page_time') ) {
		my %info = (
			problem => 'contention',
			user => $page->metadata->edit_by || 'UnknownUser',
			edittime => $page->edit_time,
		);
		$self->hub->headers->json(%info);
		return $page->modified_time;
	}
	$page->content(CGI::param('content'));
	$page->update->store;
	return $page->modified_time;
}

sub add_button {
	my $hook = pop;

	my $background_save = $self->config->edit_save_background_button_text;
	my $page_name = $self->pages->current->title;
	$background_save = <<BUTTON;
<input id="background_save" type="button" value="$background_save"
	onClick="do_background_save('$page_name')"/>
BUTTON
	my $ret = $hook->returned;
	$ret =~ s/(\<form method\=\"POST\"\>)/$1$background_save/i;
	$ret =~ s/(name\=\"page_content\")/$1 id\=\"page_content\"/i;
	$ret =~ s/(name\=\"page_time\")/$1 id\=\"page_time\"/i;
	return $ret;
}

sub add_x_json_header {
	return defined $self->json
		? ('-X_JSON', '('.$self->json.')', $_[-1]->returned)
		: $_[-1]->returned;
}

{
	no warnings 'redefine';
	no strict 'refs';
	use JSON;
	my $_json;
	*Spoon::Headers::json = sub {
		my ( $class, %args ) = @_;
		$_json = objToJson(keys(%args) > 1 ? \%args : $_[1])
			if keys(%args) > 0;
		return $_json;
	}
}

package Kwiki::Edit::BackgroundSave;
1; # End of Kwiki::Edit::BackgroundSave
__DATA__
=head1 NAME

Kwiki::Edit::BackgroundSave - Will allow a user to save the current page they
are editing while contining to edit the page.

=head1 SYNOPSIS

=over

=item

Click "Edit" on a page

=item

Start editing

=item

Click "Background Save"

=item

Continue editing

=item

When finished click "Save"

=back

=head1 AUTHOR

Eric Anderson, C<< <eric at cordata.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2006 CorData, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
=cut
__javascript/background_save.js__
function do_background_save(page_name) {
	var old_value = $('background_save').value;
	$('background_save').value = 'Saving...';
	var arguments = $H({
		action:		'background_save',
		page_name:	page_name,
		content:	$('page_content').value,
		page_time:	$('page_time').value
	}).toQueryString();
	new Ajax.Request('index.cgi', {
		parameters:     arguments,
		method:         'get',
		onComplete:     function(transport, json) {
			$('background_save').value = old_value;
			$('page_time').value = transport.responseText;
			if( json != null && json.problem == 'contention' ) {
				alert(json.user+' edited this file on '+json.edittime+
					" while you were editing this file.\n"+
					'You can save again to override their '+
					'changes if you wish.');
			}
		},
		onFailure:	function(transport, json) {
			alert("Failed to save page for some reason:\n\n"+
				'Status Code: '+transport.status+"\n"+
				'Status Text: '+transport.statusText);
			$('background_save').value = old_value;
		}
	});
}
__config/background_save.yaml__
edit_save_background_button_text: SAVE BACKGROUND
