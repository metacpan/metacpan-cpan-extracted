package HTML::LinkChanger;

# Version: $Id: LinkChanger.pm 4 2007-10-05 15:51:37Z sergey.chernyshev $

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader HTML::Parser);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = sprintf("2.%d", q$Rev: 4 $ =~ /(\d+)/);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

require HTML::Parser;
require HTML::Tagset;

sub new
{
	my $class = shift;
	my %args = @_;

	my $url_filters = $args{'url_filters'};		# reference to array HTML::LinkChanger::URLFilter objects
							# or reference to one such object

	my $self = $class->SUPER::new(
		api_version => 3,
		default_h => [sub { my $self = shift; $self->{_filtered_html} .= shift }, 'self,text'],
		start_h => ['link_tag_start', 'self,tagname,text,attr,attrseq'],
	);

	# initializing transforming functions array
	if (ref($url_filters) eq 'ARRAY')
	{
		foreach (@{$url_filters})
		{
			die "Array must contain only HTML::LinkChanger::URLFilter objects"
				unless UNIVERSAL::isa($_, 'HTML::LinkChanger::URLFilter');
		}

		$self->{url_filters} = $url_filters;
	}
	elsif (UNIVERSAL::isa($url_filters, 'HTML::LinkChanger::URLFilter'))
	{
		$self->{url_filters} = [$url_filters];
	}
	else
	{
		$self->{url_filters} = []; # empty array - can add more filters later
	}

	$self;
}

sub link_tag_start
{
	my($self, $tag, $text, $attr, $attrseq) = @_;

	my $link_attrs = $HTML::Tagset::linkElements{$tag};

	if ($link_attrs)
	{
		$link_attrs = [$link_attrs] unless ref $link_attrs;

		for my $link_attr (@$link_attrs)
		{
			next unless exists $attr->{$link_attr};
			$attr->{$link_attr} = $self->change_url(
							$attr->{$link_attr},
							$tag,
							$link_attr
						);
		}

		my $output='<'.$tag;
		foreach my $attribute (@$attrseq)
		{
			$output.=' '.$attribute.'="'.$attr->{$attribute}.'"';
		}
		$output.='>';

		$self->{_filtered_html} .= $output;
	}
	else
	{
		$self->{_filtered_html} .= $text;
	}
}

sub filter
{
	my $self = shift;

	delete $self->{_filtered_html};
	$self->parse(@_);
	$self->eof;

	return $self->{_filtered_html};
}

sub filter_file
{
	my $self = shift;

	delete $self->{_filtered_html};
	$self->parse_file(@_);
	$self->eof;

	return $self->{_filtered_html};
}

sub filtered_html
{
	my $self = shift;
	return $self->{_filtered_html};
}

sub change_url
{
	my $self = shift;
	my $url = shift;	# url of the link
	my $tag = shift;	# tag containing a link to change
	my $attr = shift;	# attribute containing a link to change

	foreach my $filter (@{$self->{url_filters}})
	{
		$url = $filter->url_filter(
				url => $url,
				tag => $tag,
				attr => $attr
			);
	}

	return $url;	# abstract class just keeps everything as it is
}

1;
__END__

=head1 NAME

HTML::LinkChanger - abstract Perl class to change all linking URLs in HTML.

=head1 SYNOPSIS

BEGIN {

	package Http2Ftp;

	require HTML::LinkChanger;
	use vars qw(@ISA);
	@ISA = qw(HTML::LinkChanger);

	#
	# Converting http URLs to FTP urls
	#
	sub change_url
	{
	        my $self = shift;
	        my $url = shift;

		$url=~s/^http:/ftp:/;

		return $url;
	}
}

my $http2ftp = new Http2Ftp();

my $converted_HTML = $http2ftp->filter($original_HTML);

=head1 DESCRIPTION

HTML::LinkChanger is an abstract class so you need to subclass it to make it
do something. See HTML::LinkChanger::Absolutizer for one useful example of
such class.

HTML::LinkChanger uses HTML::Tagset::linkElements to change all
attributes that contain links that needs to be updated.

This class is a subclass of HTML::Parser. You can call filter()
method to convert scalar containing HTML or filter_file() method to convert
HTML from file.

You can also call conventional HTML::Parser's parse() and parse_file()
methods and call filtered_html() after that to retreive results.

=head1 AUTHOR

Sergey Chernyshev <sergeyche@cpan.org>

=head1 SEE ALSO

HTML::Parser, HTML::Tagset, HTML::LinkChanger::Absolutizer

=cut
