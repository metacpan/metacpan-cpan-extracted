package HTML::Adsense;

use strict;
use warnings;

use Class::Accessor;

use base qw(Class::Accessor);

HTML::Adsense->mk_accessors(qw(client width height format type channel border bg link text url));

our $VERSION = '0.2';

sub new {
	my ($class, %args) = @_;
	my $self = bless { %args }, $class;
	$self->set_defaults();
	return $self;
}

sub set_defaults {
	my ($self) = @_;
	$self->client('pub-4763368282156432');
	$self->set_format('text 468x60');
	$self->border('FFFFFF');
	$self->bg('FFFFFF');
	$self->link('CC6600');
	$self->text('000000');
	$self->url('008000');
	return 1;
}

sub set_format {
	my ($self, $format) = @_;

	my %formats = (
		'text 468x60' => ['468x60_as', 468, 60, 'text'],
		'text 728x90' => ['728x90_as', 728, 90, 'text'],
	);

	$format = $formats{$format} || $formats{'text 468x60'};
	$self->format($format->[0]);
	$self->width($format->[1]);
	$self->height($format->[2]);
	$self->type($format->[3]);

	return 1;
}

sub render {
	my ($self) = @_;
	
	if (! $self->client) { die 'A client ID must be provided.'; }
	
	my $ad = '';
	$ad .= <<'EOF';
<script type="text/javascript">
<!--
EOF

    for my $var (qw/client width height format type channel/) {
		if ( $self->$var ) { $ad .= "google_ad_$var = \"" . $self->$var . "\"\n"; }
	}
	
	for my $var (qw/border bg link text url/) {
		if ( $self->$var ) { $ad .= "google_color_$var = \"" . $self->$var . "\"\n"; }
	}

	$ad .= <<'EOF';
//--></script>
<script type="text/javascript" src="http://pagead2.googlesyndication.com/pagead/show_ads.js">
</script>
EOF

	return $ad;
}

1;

=head1 NAME

HTML::Adsense - Create adsense widgets easily

=head1 SYNOPSIS

This module wraps Google Adsense ad creation in OO perl code.

  use HTML::Adsense;
  
  my $myad = HTML::Adsense->new(
    'client' => 'pub-4763368282156432',
  ); # OR
  $myad->client('pub-4763368282156432');
  print $myadd->render();

=head1 METHODS

=head2 new

Creates the HTML::Adsense object.

=head2 render

Returns a the adsense code.

=head2 set_defaults

Sets several defaults, used in object creation.

=head2 set_format

Sets the height, width, type and format variables based on a format name
and a list of preset values.

=head1 ACCESSOR METHODS

=over

=item client

The client ID.

=item width

The ad width.

=item height

The ad height.

=item format

The ad format.

=item type

The ad type.

=item channel

The ad channel.

=item border

The ad border color.

=item bg

The ad background color.

=item link

The ad link color.

=item text

The ad text color.

=item url

The ad url color.

=back

=head1 SUPPORTED AD FORMATS

This module has several height/width/type formats to select from. See the
adsense formats page for more information on available adsense formats.

  https://www.google.com/adsense/adformats

This doesn't prevent you from using your own formats and colors. See the
accessor methods for more information.

=over

=item text 468x60

=item text 728x90

=back

=head1 AUTHOR

Nick Gerakines, C<< <nick at gerakines.net> >>

=head1 CAVEATS

[A] There is a default client ID set. You Must either pass the client ID when
creating the object or set it via an accessor or you will B<NOT> get paid.

[B] The current list of supported ad preset formats is very limited.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-html-adsense at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-Adsense>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::Adsense

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-Adsense>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-Adsense>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-Adsense>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-Adsense>

=item * Google Adsense Home Page

L<https://www.google.com/adsense/>

=item * Google Adsense Blog

L<http://adsense.blogspot.com/>

=item * Google Adsense Supported Formats

L<https://www.google.com/adsense/adformats>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 Nick Gerakines, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
