package HTML::LinkChanger::URLFilter;

# Version: $Id: URLFilter.pm 4 2007-10-05 15:51:37Z sergey.chernyshev $

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = sprintf("2.%d", q$Rev: 4 $ =~ /(\d+)/);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

sub new
{
	my $class = shift;
	my $self = bless {}, $class;
	
	$self;
}

sub url_filter
{
	my $self = shift;
	my %args = @_;

	my $url = $args{url};	# url of the link
	my $tag = $args{tag};	# tag containing a link to change
	my $attr = $args{attr};	# attribute containing a link to change

	die 'You need to implement this method to create a filter';

	return $url;
}

1;
__END__

=head1 NAME

HTML::LinkChanger::URLFilter - abstract class that can be subclassed to implement filters for HTML::LinkChanger.

=head1 SYNOPSIS

use HTML::LinkChanger;
use HTML::LinkChanger::Absolutizer;
use HTML::LinkChanger::URLFilter;

package MyFilter;

use vars qw($VERSION @ISA);

@ISA = qw(HTML::LinkChanger::URLFilter);

sub url_filter
{
        my $self = shift;
	my %args = @_;

	my $url = $args{url};   # url of the link
	my $tag = $args{tag};   # tag containing a link to change
	my $attr = $args{attr}; # attribute containing a link to change

	# replacing URL with click counter
	return 'http://www.mysite.com/counter?url='.$url;
}

package main;

#
# make links absolute and then replace them with click counter URL
#
my $filter_chain = [
	new HTML::LinkChanger::Absolutizer(base_url => 'http://www.google.com/'),
	new MyFilter()
];

my $changer = new HTML::LinkChanger(url_filters=>$filter_chain);

my $out = $changer->filter($in);

=head1 DESCRIPTION

HTML::LinkChanger::URLFilter can be subclassed to create a transforming class that can be used in HTML::LinkChanger to convert all URLs in the document.

Filters can be applied in any sequence and they get link url, tag name and attribute name as arguments so developer can base rewriting decisions based on them.

One of the examples of useful URL filter is HTML::LinkChanger::Absolutizer which replaces all relative URLs in HTML with absolute.

=head1 AUTHOR

Sergey Chernyshev <sergeyche@cpan.org>

=head1 SEE ALSO

HTML::LinkChanger, HTML::LinkChanger::Absolutizer

=cut

