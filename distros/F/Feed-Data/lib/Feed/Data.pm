package Feed::Data;

use Moo;
use MooX::HandlesVia;
use Types::Standard qw/Any Str ArrayRef HashRef Optional/;
use Carp qw(carp croak);
use Feed::Data::Parser;
use Feed::Data::Stream;
use Feed::Data::Object;
use HTML::TableContent;
use JSON;
use Compiled::Params::OO qw/cpo/;
use XML::RSS::LibXML;
use Text::CSV_XS qw/csv/;
use YAML::XS qw//;

use 5.006;
our $VERSION = '0.07';

our $validate;
BEGIN {
	$validate = cpo(
		write => [Any, Str, Optional->of(Str)],
		render => [Any, Optional->of(Str), {default => sub { 'text' }}],
		generate => [Any, Optional->of(Str), {default => sub { 'text' }}],
		rss => [Any, Optional->of(Str)],
		raw => [Any, Optional->of(Str)],
		text => [Any, Optional->of(Str)],
		json => [Any, Optional->of(Str)],
		yaml => [Any, Optional->of(Str)],
		csv => [Any, Optional->of(Str)],
		table => [Any, Optional->of(Str)],
		convert_feed => [Any, Str, Str]
	);
}

has 'feed' => (
	is => 'rw',
	isa => ArrayRef
	lazy => 1,
	default => sub { [ ] },
	handles_via => 'Array',
	handles => {
		all => 'elements',
		count => 'count',
		get => 'get',
		pop => 'pop',
		delete => 'delete',
		insert => 'unshift',
		is_empty => 'is_empty',
		clear => 'clear',
	}
);

has title => (
	is => 'rw',
	isa => Str
);

has description => (
	is => 'rw',
	isa => Str
);

has link => (
	is => 'rw',
	isa => Str
);

has rss_channel => (
	is => 'rw',
	isa => HashRef
	default => sub { { } }
);

sub parse {
	my ($self, $stream) = @_;

	if (!$stream) {
		croak "No stream was provided to parse().";
	}

	my $parser = Feed::Data::Parser->new(
		stream => Feed::Data::Stream->new(stream => $stream)->open_stream
	)->parse;

	my $parsed = $parser->parse;
	my $feed = $parser->feed;
	return carp 'parse failed' unless $feed;

	if ($self->count >= 1) {
		$self->insert(@{ $parsed });
	} else {
		$self->feed($parsed);
	}

	return 1;
}

sub write {
	my ($self, $stream, $type) = $validate->write->(@_);
	Feed::Data::Stream->new(stream => $stream)->write_file($self->render($type || 'text'));
	return 1;
}

sub render {
	my ( $self, $format ) = $validate->render->(@_);
	$format = '_' . $format; 
	return $self->$format('render'); 
}

sub generate {
	my ( $self, $format ) = $validate->generate->(@_);
	$format = '_' . $format; 
	return $self->$format('generate'); 
}

sub _rss {
	my ($self, $type) = $validate->rss->(@_);
	my $rss = XML::RSS::LibXML->new(version => '1.0');
	$rss->channel(
		title => $self->title || "Feed::Data",
		link  => $self->link ||  "Feed::Data",
		description => $self->description || "Feed::Data",
		%{$self->rss_channel}
	);
	my @render = $self->_convert_feed('generate', 'json');
	for (@render) {
		$rss->add_item(
			%{$_}
		);
	}
	return $rss->as_string;
}

sub _raw {
	my ( $self, $type ) = $validate->raw->(@_);
	my @render = $self->_convert_feed($type, 'raw');
	if ($type eq q{render}) {
		return join "\n", @render;
	} else {
		return \@render;
	}
}

sub _text {
	my ( $self, $type ) = $validate->text->(@_);
	my @render = $self->_convert_feed($type, 'text');
	if ($type eq q{render}) {
		return join "\n", @render;
	} else {
		return \@render;
	}
}

sub _json {
	my ( $self, $type ) = $validate->json->(@_);
	my @render = $self->_convert_feed('generate', 'json');
	my $json = JSON->new->allow_nonref;
	return $json->pretty->encode( \@render );
}

sub _yaml {
	my ( $self, $type ) = $validate->yaml->(@_);
	my @render = $self->_convert_feed('generate', 'json');
	return YAML::XS::Dump \@render;
}

sub _table {
	my ( $self, $type ) = $validate->table->(@_);
	my @render = $self->_convert_feed('generate', 'json');
	my $table = HTML::TableContent->new();
	$table->create_table({
		aoh => \@render,
		order => [
			qw/author title description category comment content date image link permalink tagline/
		]
	})->render;
}

sub _styled_table {
	my ( $self, $type ) = $validate->table->(@_);
	my @render = $self->_convert_feed('generate', 'json');
	my $table = HTML::TableContent->new();
	$table->create_table({
		aoh => \@render,
		order => [
			qw/author title description category comment content date image link permalink tagline/
		]
	})->render . '<style> 
		table {
			font-family: "Trebuchet MS", Arial, Helvetica, sans-serif;
			border-collapse: collapse;
			width: 100%;
		}

		td, th {
			word-break: break-word;
			min-width: 100px;
			border: 1px solid #ddd;
			padding: 8px;
		}

		tr:nth-child(even){background-color: #f2f2f2;}

		tr:hover {background-color: #ddd;}

		th {
			padding-top: 12px;
			padding-bottom: 12px;
			text-align: left;
			background-color: #4c65af;
			color: white;
		}
	</style>'
}

sub _csv {
	my ( $self, $type ) = $validate->json->(@_);
	my @render = $self->_convert_feed('generate', 'json');
	my $string;
	csv (in => \@render, out => \$string);
	return $string;
}

sub _convert_feed {
	my ( $self, $type, $format ) = $validate->convert_feed->(@_);
	my @render;
	foreach my $object ( @{$self->feed} ) {
		push @render, $object->$type($format);
	}
	return @render;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Feed::Data - dynamic data feeds

=head1 VERSION

Version 0.07

=head1 SYNOPSIS 

	use Feed::Data;

	my $feed = Feed::Data->new();
	$feed->parse( 'https://services.parliament.uk/calendar/lords_main_chamber.rss' );

	$feed->all;
	$feed->count;
	$feed->delete($index);
	$feed->get($index);

	$feed->write( 'path/to/empty.rss', 'rss' );
	my $feed_text = $feed->render('rss'); 

	foreach my $object ( $feed->all ) {
		$object->render('text'); # text, html, xml..
		$object->hash('text'); # text, html, xml...
		$object->fields('title', 'description'); # returns title and description object
		$object->edit(title => 'TTI', description => 'Should have been a PWA.'); # sets
		
		$object->title->text;
		$object->link->raw;
		$object->description->text;
		$object->image->raw;
		$object->date->text;
		
		$entry->title->as_text;
	}

	...

	use Feed::Data;

	my $feed = Feed::Data->new();
	
	$feed->parse( 'https://services.parliament.uk/calendar/commons_main_chamber.rss' );

	my $string = $feed->render('styled_table');

	$feed->clear;

	$feed->parse($string);

=head1 DESCRIPTION

Feed::Data is a frontend for building dynamic data feeds.

=cut

=head1 Methods

=cut

=head2 parse

Populates the feed Attribute, this is an Array of Feed::Data::Object 's

You can currently build Feeds by parsing xml (RSS, ATOM), JSON, CSV, plain text using key values seperated by a colon  HTML via Meta Tags (twitter, opengraph) or table markup.

=cut

=over

=item URI

	# any rss/atom feed or a web page that contains og or twitter markup
	$feed->parse( 'http://examples.com/feed.xml' );

=item File

	$feed->parse( 'path/to/feed.json' );

=item Raw 

	$feed->parse( 'qq{<?xml version="1.0"><feed> .... </feed>} );

=back 

=head2 all

returns all elements in the current feed

	$feed->all

=cut

=head2 count

returns the count of the current data feed

	$feed->count

=cut

=head2 get

accepts an index and returns an Feed::Data::Object from feed by its Array index

	$feed->get($index)

=cut

=head2 pop

pop the last Feed::Data::Object from the current feed

	$feed->pop;

=cut

=head2 delete

accepts an index and deletes the relevant Feed::Data::Object based on its Array index

	$feed->delete($index);

=cut

=head2 insert

insert an 'Feed::Data::Object' into the feed

	$feed->insert($record)

=cut

=head2 is_empty

returns true if Feed::Data is empty.

	$feed->is_empty
	
=cut

=head2 clear

clear the current feed.

	$feed->clear

=cut

=head2 title

Set the title of the rss feed the default is Feed::Data.

	$feed->title('Custom Title');

=head2 link

Set the link of the rss feed the default is Feed::Data.

	$feed->link('https://custom.link');

=head2 description

Set the description of the rss feed the default is Feed::Data.

	$feed->description('Custom Description');

=head2 rss_channel

Pass additional arguments into the rss feed channel section. See XML::RSS for more information.

	$feed->rss_channel({  
		dc => {
			date       => '2000-01-01T07:00+00:00',
			subject    => "LNATION",
			creator    => 'email@lnation.org',
			publisher  => 'email@lnation.org',
			rights     => 'Copyright 2000, lnation.org',
		},
		syn => {
			updatePeriod     => "hourly",
			updateFrequency  => "1",
			updateBase       => "1901-01-01T00:00+00:00",
		},
	});

=head2 render

render the feed using the passed in format, defaults to text.
	
	# raw - as taken from the feed
	# text - stripped to plain text
	# json 
	# rss
	# csv
	# yaml
	# table
	# styled_table

	$feed->render('raw');

=cut

=head2 generate

returns the feed object as a Array of hashes but with the values rendered, key being the field. You can also pass in a format.
	
	$feed->hash('text');

=cut

=head2 write

Writes the current stream to file.

	$feed->write($file_path, $type);

=head1 AUTHOR

lnation, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-feed-data at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Feed-Data>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Feed-Data>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Feed-Data>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Feed-Data>

=item * Search CPAN

L<http://search.cpan.org/dist/Feed-Data/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2016 LNATION.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Feed::Data
