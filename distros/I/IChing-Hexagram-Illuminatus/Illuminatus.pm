package IChing::Hexagram::Illuminatus;

$IChing::Hexagram::Illuminatus::VERSION = "0.01";

use strict;
use warnings;
use LWP::UserAgent;
use HTTP::Request;
use HTML::Summary;
use HTML::TreeBuilder;

=head1 NAME

IChing::Hexagram::Illuminatus - An IChing hexagram

=head1 SYNOPSIS

  use IChing::Hexagram::Illuminatus;

  my $hex = IChing::Hexagram::Illuminatus->new;

  my $hex = IChing::Hexagram::Illuminatus->new(
		{ political      => 'http://policital.site.com',
		  economic       => 'http://economic.ste.com',
		  meterological  => 'http://meterological.ste.com',
		  astrological   => 'http://astrological.ste.com',
		  astronomical   => 'http://astronomical.ste.com',
		  technological  => 'http://technoloigical.ste.com',
		}
  );

  my $political_reference     = $hex->political;
  my $economic_reference      = $hex->economic;
  my $meterological_reference = $hex->meterological;
  my $astrological_reference  = $hex->astrological;
  my $astronomical_reference  = $hex->astronomical;
  my $technological_reference = $hex->technological;

  my $reading = $hex->throw;

=head1 DESCRIPTION

While reading the Illuminatus! Trilogy, there is a machine called FUCKUP, which 
stands for First Universal Cybernetic-Kinetic-Ultramicro-Programmer. And 
Hagbard Celine uses this to generate an IChing hexagram.

This modules attempts to do the same thing.

=head2 So what is an IChing hexagram then?

Honestly? I have no idea.

=head2 Alright then, how is it described in the book?

Glad you asked.

This will read a random open circuit as a broken (yin) line, then read a 
random closed circuit as a full (yang) line, until six such lines are
round, then simulate an IChing hexagram being thrown.

This is fed into the IChing interpretation engine, and cross checked with
the current day's political, economic, meterological, astrological, 
astronomical and technological news.

At the end of all this, you have a pseudo scientific/crackpot prediciton of
the future.

=head2 So I get my fortune told. Is that it?

Not only your fortune, but a broad sweep of What Is To Come.

OK, I admit it. What a pile of old trousers. But I like the books, and 
this is part of my homage to them.

=head1 METHODS

=head2 new

  my $hex = IChing::Hexagram::Illuminatus->new;

  my $hex = IChing::Hexagram::Illuminatus->new(
		{ political      => 'http://policital.site.com',
		  economic       => 'http://economic.ste.com',
		  meterological  => 'http://meterological.ste.com',
		  astrological   => 'http://astrological.ste.com',
		  astronomical   => 'http://astronomical.ste.com',
		  technological  => 'http://technoloigical.ste.com',
		}
  );

This will make a new IChing::Hexagram::Illuminatus object. All the values 
passed in with the hashref are optional. If nothing is passed in, defaults 
are used as defined by me.

=cut

sub new {
  my $self = {};
  bless $self, shift;
  return $self->_init(@_);
}

sub _init {
  my ($self, $ref) = @_;

  #
  # yes, I know I could contruct this differently.
  #
  $self->{political}     = $ref->{political}     || 'http://www.stopworldwar3.com/News.rdf'; 
  $self->{economic}      = $ref->{economic}      || 'http://headlines.internet.com/internetnews/bus-news/news.rss'; 
  $self->{meterological} = $ref->{meterological} || 'http://weather.yahoo.com'; 
  $self->{astrological}  = $ref->{astrological}  || 'http://slashgoth.org/backend/weblog.rdf'; 
  $self->{astronomical}  = $ref->{astronomical}  || 'http://www.beyond2000.com/b2k.rdf'; 
  $self->{technological} = $ref->{technological} || 'http://www.slashdot.org/slashdot.rdf'; 
 
  return $self;
}

=head2 throw

  my $reading = $hex->throw;

This will get you the hexagram. It is a string, on three lines, with 
a digit on each line, either a one or a zero. The one represents
an unbroken yin line, while a zero gives the broken yang line.

For example, 

0			-- --
1 would be read as      _____
1			_____

But as well as the hexagram, it gets you the news from various sources.

From these two things, if you are skilled, and Know The Way, then you
can interpret these and discover what is going on in the world.

=cut

sub throw {
  my $self = shift;
  my $hex = $self->_hexagram;
  my $text = $self->_get_headlines;
  print "Your hexagram: $hex\n\nWorld info\n$text\n\n";
}

sub _hexagram {
  my $self = shift;
  #
  # TODO : Make this a better random number
  #
  
  my $bin = sub { int rand(2) };
  my $pattern;
  $pattern .= $bin->() for (1 .. 3);
  return $pattern;
}

sub _ua { 
  my $self = shift;
  unless (exists $self->{ua}) {
    $self->{ua} = LWP::UserAgent->new;
  }
  return $self->{ua};
}

sub _summary {
  my $self = shift;
  unless (exists $self->{summary}) {
    $self->{summary} = HTML::Summary->new(
        LENGTH   => 500,
        USE_META => 1,
  );
  }
  return $self->{summary};
}

sub _get_headlines {
  my $self = shift;
  my $ua = $self->_ua; my $summarizer = $self->_summary;
  my $rubbish;
  foreach my $category (qw/political economic meterological 
			   astrological astronomical technological/) {
    my $response = $ua->request(HTTP::Request->new('GET', $self->$category));
    my $tree = HTML::TreeBuilder->new;
    $tree->parse( $response->as_string );
    my ($summary, $throw) = split /HTTP/, $summarizer->generate( $tree );
    $rubbish .= "\n$category\n$summary\n"
  }
  return $rubbish;
}

=head2 political

  my $political_reference = $hex->political;

This will return the site from which the political information if gathered.

=cut

sub political { shift->{political} }

=head2 meterological

  my $meterological_reference = $hex->meterological;

This will return the site from which the meterological information if gathered.

=cut

sub meterological { shift->{meterological} }

=head2 economic

  my $economic_reference = $hex->economic;

This will return the site from which the economic information if gathered.

=cut

sub economic  { shift->{economic} }

=head2 astrological

  my $mastrological_reference = $hex->astrological;

This will return the site from which the astrological information if gathered.

=cut

sub astrological { shift->{astrological} }

=head2 astronomical

  my $mastronomical_reference = $hex->astronomical;

This will return the site from which the astronomical information if gathered.

=cut

sub astronomical { shift->{astronomical} }

=head2 technologcal

  my $technological_reference = $hex->technological;

This will return the site from which the technological information if gathered.

=cut

sub technological { shift->{technological} }

=head1 TODO

o Perhaps include some interpretation engine? Which takes the hexagram and
  the headlines and predicts the future?
o Stop thinking about this module

=head1 SHOWING YOUR APPRECIATION

There was a thread on london.pm mailing list about working in a vacumn
- that it was a bit depressing to keep writing modules but never get
any feedback. So, if you use and like this module then please send me
an email and make my day.

All it takes is a few little bytes.

(Leon wrote that, not me!)

=head1 AUTHOR

Stray Toaster E<lt>F<coder@stray-toaster.co.uk>E<gt>

=head2 With Thanks

  o Robert Shea and Robert Anton Wilson for giving me both the Illuminatus!
    and the Schrodinger Cat books!

=head1 COPYRIGHT

Copyright (C) 2002, mwk

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=head1 SANITY CLAUSE

Ain't you heard? There is no Sanity Clause. Surely that is obvious?!

=head1 So why doesn't this live in the ACME:: namespace?

A good, and very valid, question. 

Perhaps I have taken this all a bit lightly, but I am sure that there are
those who think their lives should be lived by what the IChing readings tell
them. And far be it for me to make a mockery of their beliefs, as I am sure 
some of mine are just as wacky in their eyes.

So, in the interest of community relations, I have decided to pollute the top
level namespace. As, indeed, someone might want to (upon being inspired and 
spurred by this module) create an IChing::Hexagram::Real or something.

=cut

return qw/No secret message in this one. Sorry!/;
