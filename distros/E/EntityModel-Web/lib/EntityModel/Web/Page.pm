package EntityModel::Web::Page;
{
  $EntityModel::Web::Page::VERSION = '0.004';
}
use EntityModel::Class {
	name			=> 'string',
	path			=> 'string',
	pathtype		=> 'string',
	title			=> 'string',
	description		=> 'string',
	template		=> 'string',
	separator		=> { type => 'string', default => '/' },
	parent			=> { type => 'EntityModel::Web::Page' },
	pathinfo		=> { type => 'array', subclass => 'EntityModel::Web::Page::Pathinfo' },
	data			=> { type => 'array', subclass => 'EntityModel::Web::Page::Data' },
	content			=> { type => 'array', subclass => 'EntityModel::Web::Page::Content' },
	content_by_section	=> { type => 'hash', subclass => 'EntityModel::Web::Page::Content', watch => { content => 'section' } },
	handler			=> { type => 'array', subclass => 'EntityModel::Web::Page::Handler' },
	handler_for_http_verb	=> { type => 'hash', subclass => 'EntityModel::Web::Page::Handler', watch => { handler => 'type' } },
};

=head1 NAME

EntityModel::Web::Page - handle page definitions

=head1 VERSION

version 0.004

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use EntityModel::Web::Response;
use Data::Dumper;

=head1 METHODS

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new;
	my %args = @_;
	my $site = delete $args{site};
	$self->separator('/');
	foreach my $item (qw(name path pathtype title description separator template)) {
		if(defined(my $v = delete $args{$item})) {
			$self->$item($v);
		}
	}
	$self->pathtype('string') unless $self->pathtype;
	if(my $pathinfo = delete $args{pathinfo}) {
		$self->pathinfo->push(EntityModel::Web::Page::Pathinfo->new($_)) for @$pathinfo;
	}
	if(my $data = delete $args{data}) {
		$self->data->push(EntityModel::Web::Page::Data->new($_)) for @$data;
	}
	if(my $content = delete $args{content}) {
		$self->content->push(EntityModel::Web::Page::Content->new(%$_)) for @$content;
	}
	if(my $handler = delete $args{handler}) {
		$self->handler->push(EntityModel::Web::Page::Handler->new($_)) for @$handler;
	}
	if(my $parent = delete $args{parent}) {
		$self->parent($site->page_by_name->get($parent));
	}
#	warn "Create page with " . Dumper \%args;
#	warn "Page " . $self->name;
#	warn " * Description " . ($self->description // '');
#	warn " * Path        " . ($self->path // '');
#	warn " * Pathtype    " . ($self->pathtype // '');
#	warn " * Title       " . ($self->title // '');
	die "pathtype not defined" unless defined $self->pathtype;
	return $self;
}

sub handle_request {
	my $self = shift;
	my %args = @_;

	my $req = delete $args{request} or die "No request supplied";
	my $response = EntityModel::Web::Response->new(
		request	=> $req,
		page	=> $self
	);
#	$response->apply_data(delete $args{data}) if exists $args{data};

	logDebug("Looking for handler on [%s] for %s", $req->method, $self->name);
	logDebug("-> [%s]", $_) for keys %{ $self->handler_for_http_verb };
	# If we have a handler set up for this request, use it
	if(my $handler = $self->handler_for_http_verb->get($req->method)) {
		logWarning("Found [%s]", $handler);
		my $rslt = $handler->($response);
		# And pass the value back if true (which means the handler's done everything we need)
		return $rslt if $rslt;
	}

	return $response;
}

sub extract_data {
	my $self = shift;
	my $data = shift;
	my %pathinfo;
	foreach my $pi ($self->pathinfo->list) {
		$pathinfo{$pi->name} = shift @$data;
	}
	return %pathinfo;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2009-2011. Licensed under the same terms as Perl itself.
