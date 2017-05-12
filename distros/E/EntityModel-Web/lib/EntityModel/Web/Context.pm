package EntityModel::Web::Context;
{
  $EntityModel::Web::Context::VERSION = '0.004';
}
use EntityModel::Class {
	request		=> { type => 'EntityModel::Web::Request' },
	response	=> { type => 'EntityModel::Web::Response' },
	site		=> { type => 'EntityModel::Web::Site' },
	page		=> { type => 'EntityModel::Web::Page' },
	user		=> { type => 'EntityModel::Web::User' },
	session		=> { type => 'EntityModel::Web::Session' },
	data		=> { type => 'hash', subclass => 'data' },
	template	=> { type => 'EntityModel::Template' },
};

=head1 NAME

EntityModel::Web::Context - handle context for a web request

=head1 VERSION

version 0.004

=head1 SYNOPSIS

 my $web = EntityModel::Web->new;
 my $req = EntityModel::Web::Request->new;
 my $ctx = EntityModel::Web::Context->new(
 	request => $req
 );
 $ctx->find_page_and_data($web);
 $ctx->resolve_data;
 $ctx->process;
 $ctx->save_session;
 return $ctx->response;

=head1 DESCRIPTION

=cut

use EntityModel::Template;

=head1 METHODS

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new;
	my %args = @_;
	if(defined(my $req = delete $args{request})) {
		$self->request($req);
	}
	if(defined(my $tmpl = delete $args{template})) {
		$self->template($tmpl);
	} else {
		$self->{template} = EntityModel::Template->new;
	}
	return $self;
}

=head2 find_page_and_data

Locate the page and populate any initial data from the path information.

=cut

sub find_page_and_data {
	my $self = shift;
	my $web = shift;
	my $host = $self->request->uri->host;
	# my ($site) = grep { warn "have " . $_->host; $_->host eq $host } $web->site->list;
	my ($site) = $web->site->list;
	# grep(sub { $_[0] eq $host })->first;
	logDebug("Check for site [%s]", $host);
	return EntityModel::Error->new($self, "No site") unless $site;
	$self->site($site);

# If we have a regex match, return the remaining entries
	my ($page, @data) = $site->page_from_uri($self->request->uri);
	unless($page) {
		logWarning("Failed to find page for URI [%s]", $self->request->uri);
		logInfo("Page [%s]", $_->path) for $site->page->list;
	}
	return EntityModel::Error->new($self, "No page") unless $page;

# Pick up the page entry first
	$self->page($page);
	logDebug("Page is [%s]", $page->name);

# Get all page entries in order from first to last
	my @pages = $page;
	while($page->parent) {
		$page = $page->parent;
		unshift @pages, $page;
	}

# Apply data for any entries that have regex captures
	my %page_data;
	foreach my $p (@pages) {
		my %page_data = $p->extract_data(\@data);
		$self->data->set($_, $page_data{$_}) for keys %page_data;
	}

	return $self;
}

=head2 data_missing

Returns number of missing dependencies for the given L<EntityModel::Web::Page::Data> entry.

=cut

sub data_missing {
	my ($self, $entry) = @_;
	return 0 unless $entry;

	my @missing = grep {
		defined($_->data) && !$self->data->exists($_->data)
	} $entry->parameter->list;
	push @missing, $entry if $entry->data && !$self->data->exists($entry->data);

	logDebug("Data $entry requires " . join(', ', map { $_->value } @missing) . " items which are not ready yet") if @missing;
	return scalar(@missing);
}

=head2 resolve_data

Process all data for this page, handling initial population and then going through each item in
turn, adding it back to the queue if the dependencies aren't ready.

Chained method.

=cut

sub resolve_data {
	my $self = shift;
	return EntityModel::Error->new($self, 'No page') unless $self->page;

# Get list of required items for this page
	my @dataList = $self->page->data->list;

# Iterate through them until we no longer have any entries to resolve (or all existing entries are
# failing).
	my $failed = 0;
	DATA:
	while(@dataList) {
		my $entry = shift(@dataList) or next DATA;

		logDebug("Resolve data for " . ($entry->key // 'undef'));
		if($self->resolve_data_item($entry)) {
			# Successful resolution means we should reset the failure counter
			$failed = 0;
		} else {
			++$failed;
			push @dataList, $entry;
		}

# If all entries in the queue are failing, raise an error here
		return EntityModel::Error->new($self, sub { "Could not resolve items [%s], population failed", join ',', map { $_->key // 'undef' } @dataList }) if $failed && $failed >= @dataList;
	}

	return $self;
}

=head2 find_data_value

Retrieve data value for given L<EntityModel::Web::Page::Data> entry.

=cut

sub find_data_value {
	my $self = shift;
	my $entry = shift;

	my $v;

	if(defined $entry->value) {
# Simple value, used for constants
		$v = $entry->value;
	} elsif($entry->class) {
# Class method
		$v = $self->data_from_class_method($entry);
	} elsif ($entry->instance) {
# Instance method
		$v = $self->data_from_instance_method($entry);
	} elsif ($entry->data) {
# Data value from somewhere else
		$v = $self->data->get($entry->data);
	} else {
# Default case - probably an error
		logDebug(" * $_ => " . $entry->{$_}) foreach keys %$entry;
		logError({ %$entry });
		$v = EntityModel::Error->new($self, 'Unknown data type');
	}
	return $v;
}

=head2 resolve_data_item

Resolve a single data item if we can.

Returns undef on failure, original entry on success.

=cut

sub resolve_data_item {
	my $self = shift;
	my $entry = shift;
	my $k = $entry->key;

	if($self->data_missing($entry)) {
		logDebug("Deferring " . $k);
		return undef;
	}

	my $v = $self->find_data_value($entry);
	$self->data->{$k} = $v unless eval { $v->isa('EntityModel::Error') };

	logDebug("Data [$k] is now " . ($self->data->{$k} // 'undef'));
	return $entry;
}

=head2 args_for_data

Generate list of arguments for a method call.

=cut

sub args_for_data {
	my $self = shift;
	my $entry = shift;

	my @param;
	$entry->parameter->each($self->sap(sub {
		my ($self, $item) = @_;
		push @param, $self->find_data_value($item);
	}));
	return @param;
}

=head2 data_from_class_method

Call class method to obtain new data value.

=cut

sub data_from_class_method {
	my $self = shift;
	my $entry = shift;
	my $class = $entry->class;
	my $method = $entry->method;

	return EntityModel::Error->new($self, 'No class provided') unless $class;
	return EntityModel::Error->new($self, 'Invalid method %s for %s', $method, $class) unless $class->can($method);

	return try {
		$class->$method($self->args_for_data($entry));
	} catch {
		EntityModel::Error->new($self, "Failed in %s->%s for %s: %s", $class, $method, $entry->key, $_);
	};
}

=head2 data_from_instance_method

Instance method, in which case hopefully we already set this one up

=cut

sub data_from_instance_method {
	my $self = shift;
	my $entry = shift;
	logDebug("Look up [%s]", $entry->instance);

	my $obj = $self->data->get($entry->instance);
	$obj ||= $self->site if $entry->instance eq 'site';
	$obj ||= $self->page if $entry->instance eq 'page';
	$obj ||= $self if $entry->instance eq 'context';
	logDebug("Got [%s]", $obj);
	my $method = $entry->method;
	my $v = try {
		logDebug("Call $method");
		my @args = $self->args_for_data($entry);
		$obj->$method(@args);
	} catch {
		logError("Method [%s] not valid for class %s on key %s, error %s", $method, $obj, $entry->key, $_);
	};
	logDebug("Had [%s]", $v);
	return $v;
}

=head2 process

=cut

sub process {
	my $self = shift;
	logDebug("Try to handle request for this page");

	$self->page->handle_request(request => $self->request, data => $self->data);

	my %section = map {
		$_->section => $self->section_content($_->section)
	} $self->site->layout->list;
	my $tmpl = $self->page->template // $self->site->template;
	return '' unless $tmpl;

	return $self->template->as_text($tmpl, {
		context => $self,
		page => $self->page,
		data => $self->data,
		section => \%section
	});
}


=head2 section_content

=cut

sub section_content {
	my $self = shift;
	my $section = shift or return '';
	return EntityModel::Error->new($self, 'No page defined') unless $self->page;

	logDebug("Try section [%s]", $section);
	my $content = $self->page->content_by_section->get($section);
	logDebug("Had content [%s]", $content);
	return EntityModel::Error->new($self, "Section [$section] not found") unless $content;
	logDebug("Template [%s]", $content->template);
	return $self->template->as_text($content->template, {
		context => $self,
		page => $self->page,
		data => $self->data,
	});
}

=head2 load_session

Loads session data into the current context.

=cut

sub load_session {
	my $self = shift;
}

=head2 save_session

=cut

sub save_session {
	my $self = shift;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2009-2011. Licensed under the same terms as Perl itself.
