package EntityModel::Web::Site;
{
  $EntityModel::Web::Site::VERSION = '0.004';
}
use EntityModel::Class {
	host		=> 'string',
	template	=> 'string',
	layout		=> { type => 'array', subclass => 'EntityModel::Web::Layout' },
	page		=> { type => 'array', subclass => 'EntityModel::Web::Page' },
	page_by_name	=> { type => 'hash', subclass => 'EntityModel::Web::Page', scope => 'private', watch => { page => 'name' } },
	url_string	=> 'hash',
	url_regex	=> 'array',
};

=head1 NAME

EntityModel::Web::Site

=head1 VERSION

version 0.004

=head1 SYNOPSIS

 my $web = EntityModel::Web->new;
 my $req = EntityModel::Web::Request->new;
 my $site = $web->find_site('somehost.example.com');
 my $page = $site->find_page('http://somehost.example.com/some/page');
 my $response = $page->handle_request($req);

=head1 DESCRIPTION

The site maintains a path map for string and regex paths:

 string => {
  index.html			=> {},
  documentation/index.html	=> {},
 },
 regex => [
  tutorial/([^/]+)/perl.html	=> {}
 ]

When parsing a new page entry, the L</full_path> method is used to identify the entry to
use for the path map.

The / delimiter is added automatically unless the pathseparator parameter is given, in which case
this value will be used instead (can be used for cases such as C<page_(one|two|three).html>.

Any path that matches a string path exactly (via hash lookup) will return that page without further checks.
If this match fails, the string is compared against the regex entries. Normally top-level pages should be
anchored to the start of the string.

Using a prefix substring match may help for performance, although this would need to limit to non-metachars only
and only applies to the start-anchored regex entries.

=cut

use URI;
use Data::Dumper;

=head1 METHODS

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new;

	$self->page->add_watch($self->sap(sub {
		my ($self) = shift;
		my %args = @_;
		$self->add_page_to_map($args{add}) if $args{add};
		$self->remove_page_from_map($args{drop}) if $args{drop};
	}));

	my %args = %{$_[0]};
	if(my $host = delete $args{host}) {
		$self->host($host);
	}
	if(my $template = delete $args{template}) {
		$self->template($template);
	}
	if(my $layout = delete $args{layout}) {
		$self->layout->push(EntityModel::Web::Layout->new(%$_)) for @$layout;
	}
	if(my $page_list = delete $args{page}) {
		for (@$page_list) {
			# Add all these pages and populate the path map, including any subpages.
			my $page = EntityModel::Web::Page->new(%$_, site => $self);
			$self->page->push($page);
		}
	}
	return $self;
}

sub add_page_to_map {
	my ($self, $page) = @_;
	my $path = $page->path;
	$path = qr{$path} if $page->pathtype ne 'string';

	my $current = $page;
	my $depth = 0;
	while(my $parent = $current->parent) {
		if(ref $path) {  # are we a regex?
			my $pp = $parent->path;
			my $sep = $current->separator;
			my $v = $parent->pathtype eq 'string' ? qr{\Q$pp$sep\E} : qr{$pp\Q$sep\E};
			$path = qr{$v$path};
		} else {
			$path = join($current->separator, $parent->path, $path);
		}
		$current = $parent;
		++$depth;
	}

# Add the leading / unless we've overridden it
	my $sep = $current->separator;
	if(ref $path) {  # are we a regex?
		$path = qr{\Q$sep\E$path};
		push @{$self->url_regex->[$depth]}, qr/$path/, $page;
	} else {
		# Only prefix if we don't already have the prefix /
		$path = $sep . $path unless index($path, $sep) == 0;
		$self->url_string->set($path, $page);
	}
}

sub remove_page_from_map {
	my ($self, $page) = @_;
}

=head2 C<page_from_uri>

In list context, returns the captured regex elements if we had any.

=cut

sub page_from_uri {
	my $self = shift;
	my $uri = shift;

# Exact match wins
	my $path = $uri->path;
	my $page = $self->url_string->get($path);
	logDebug("Had [%s] for [%s]", $path, $page);
	return $page if $page;

# Try without extension
	{
		(my $path_basename = $path) =~ s/\.(\w+)$//;
		my $type = $1;
		$page = $self->url_string->get($path_basename);
		logDebug("URL string lookup resulted in [%s]", $page);
		return $page if $page;
	}

# Go through regex options
	my @regex = map { @$_ } grep defined, reverse $self->url_regex->list;
	while(@regex) {
		my ($k, $v) = splice @regex, 0, 2;
		logDebug("Looking for %s, %s from %s", $k, $v, $path);

		if($path =~ $k) {
			return $v unless wantarray;

# Extract the matches - should probably do this and the m{} check in a single step
			my @data = $#+ ? map { (defined($-[$_]) && defined($+[$_])) ? substr($path, $-[$_], $+[$_] - $-[$_]) : '' } 1..$#+ : ();
			return ($v, @data);
		}
	}

	return undef;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2009-2011. Licensed under the same terms as Perl itself.
