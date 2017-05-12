package HTML::LinkChanger::Absolutizer;

# Version: $Id: Absolutizer.pm 4 2007-10-05 15:51:37Z sergey.chernyshev $

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require HTML::LinkChanger::URLFilter;
require URI;
require HTML::LinkChanger;

@ISA = qw(Exporter AutoLoader HTML::LinkChanger::URLFilter);
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
	my %args = @_;

	die "Must specify base URL" unless $args{base_url};

	my $self = $class->SUPER::new();

	$self->{_absolutizer_base} = URI->new($args{base_url});

	$self;
}

sub url_filter
{
	my $self = shift;
	my %args = @_;

	my $url	= $args{url};   # url of the link
	my $tag = $args{tag};   # tag containing a link to change
	my $attr = $args{attr}; # attribute containing a link to change
					
	my $base = $self->{_absolutizer_base};

	return URI->new($url, $base)->abs($base);
}

1;
__END__

=head1 NAME

HTML::LinkChanger::Absolutizer - subclass of HTML::LinkChanger that converts
all relative URLs to absolute ones.

=head1 SYNOPSIS

use HTML::LinkChanger;
use HTML::LinkChanger::Absolutizer;

my $filters = [
		new HTML::LinkChanger::Absolutizer(
				base_url => 'http://www.google.com/'
			)
	];


my $changer = new HTML::LinkChanger( url_filters => $filters );

my $out = $changer->filter($in);

=head1 DESCRIPTION

HTML::LinkChanger::Absolutizer is an implementation of HTML::LinkChanger::URLFilter
that can be used in HTML::LinkChanger to convert all relative URLs to absolute.

This module can be very useful when processing RSS feeds for example since RSS standards are
not very strict about relative URL handling and might misinterpret them.

=head1 AUTHOR

Sergey Chernyshev <sergeyche@cpan.org>

=head1 SEE ALSO

HTML::LinkChanger

=cut
