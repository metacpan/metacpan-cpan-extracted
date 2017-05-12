# $Id$

package Google::Chart;
use 5.008;
use Moose;
use Google::Chart::Axis;
use Google::Chart::Legend;
use Google::Chart::Grid;
use Google::Chart::Color;
use Google::Chart::Data;
use Google::Chart::Size;
use Google::Chart::Type;
use Google::Chart::Types;
use Google::Chart::Title;
use Google::Chart::Margin;
use LWP::UserAgent;
use URI;
use overload
    '""' => \&as_uri,
    fallback => 1,
;

use constant BASE_URI => URI->new("http://chart.apis.google.com/chart");

our $VERSION   = '0.05014';
our $AUTHORITY = 'cpan:DMAKI';

my %COMPONENTS = (
    type => {
        is => 'rw',
        does => 'Google::Chart::Type',
        coerce => 1,
        required => 1,
    },
    data => {
        is       => 'rw',
        does     => 'Google::Chart::Data',
        coerce   => 1,
    },
    color => {
        is       => 'rw',
        isa      => 'Google::Chart::Color',
        coerce   => 1,
    },
    legend => {
        is       => 'rw',
        does     => 'Google::Chart::Legend',
        coerce   => 1,
    },
    grid => {
        is       => 'rw',
        isa     => 'Google::Chart::Grid',
        coerce   => 1,
    },
    size => {
        is       => 'rw',
        isa      => 'Google::Chart::Size',
        coerce   => 1,
        required => 1,
        lazy     => 1,
        default  => sub { Google::Chart::Size->new( width => 400, height => 300 ) },
    },
    marker => {
        is       => 'rw',
        isa      => 'Google::Chart::Marker',
        coerce   => 1,
    },
    axis => {
        is       => 'rw',
        isa      => 'Google::Chart::Axis',
        coerce   => 1,
    },
    fill => {
        is       => 'rw',
        does     => 'Google::Chart::Fill',
        coerce   => 1
    },
    title => {
        is       => 'rw',
        does     => 'Google::Chart::Title',
        coerce   => 1
    },
    margin => {
        is       => 'rw',
        does     => 'Google::Chart::Margin',
        coerce   => 1
    },
);
my @COMPONENTS = keys %COMPONENTS;

{
    while (my ($name, $spec) = each %COMPONENTS ) {
        has $name => %$spec;
    }
}

has 'ua' => (
    is         => 'rw',
    isa        => 'LWP::UserAgent',
    required   => 1,
    lazy_build => 1,
);

__PACKAGE__->meta->make_immutable;

no Moose;

sub _build_ua {
    my $self = shift;
    my $ua = LWP::UserAgent->new(
        agent => "perl/Google-Chart-$VERSION",
        env_proxy => exists $ENV{GOOGLE_CHART_ENV_PROXY} ? $ENV{GOOGLE_CHART_ENV_PROXY} : 1,
    );
    return $ua;
}

# XXX 
# We need a trigger function that gets called whenever a component
# is set, so we can validate if the combination of components are
# actually feasible.

sub as_uri {
    my $self = shift;

    my %query;
    foreach my $c (@COMPONENTS) {
        my $component = $self->$c;
        next unless $component;
        my @params = $component->as_query;
        while (@params) {
            my ($name, $value) = splice(@params, 0, 2);
            next unless length $value;
            $query{$name} = $value;
        }
    }

    # If in case you want to change this for debugging or whatever...
    my $uri = $ENV{GOOGLE_CHART_URI} ? 
        URI->new($ENV{GOOGLE_CHART_URI}) :
        BASE_URI->clone;
    $uri->query_form( %query );
    return $uri;
}

sub render {
    my $self = shift;
    my $response = $self->ua->get($self->as_uri);

    if ($response->is_success) {
        return $response->content;
    } else {
        die $response->status_line;
    }
}

sub render_to_file {
    # XXX - This is done like this because there was a document-implementation
    # mismatch. In the future, single argument form should be deprecated
    my $self = shift;
    my $filename = (@_ > 1) ? do {
        my %args = @_;
        $args{filename};
    }: $_[0];

    open my $fh, '>', $filename or die "can't open $filename for writing: $!\n";
    binmode($fh); # be nice to windows
    print $fh $self->render;
    close $fh or die "can't close $filename: $!\n";
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Chart - Interface to Google Charts API

=head1 SYNOPSIS

  use Google::Chart;

  my $chart = Google::Chart->new(
    type => "Bar",
    data => [ 1, 2, 3, 4, 5 ]
  );

  print $chart->as_uri, "\n"; # or simply print $chart, "\n"

  $chart->render_to_file( filename => 'filename.png' );

=head1 DESCRITPION

Google::Chart provides a Perl Interface to Google Charts API 
(http://code.google.com/apis/chart/).

Please note that version 0.05000 is a major rewrite, and has little to no
backwards compatibility.

=head1 METHODS

=head2 new(%args)

Creates a new Google::Chart instance. 

=over 4

=item type

Specifies the chart type, such as line, bar, pie, etc. If given a string like
'Bar', it will instantiate an instance of Google::Chart::Type::Bar by
invoking argument-less constructor.

If you want to pass parameters to the constructor, either pass in an
already instanstiated object, or pass in a hash, which will be coerced to
the appropriate object

  my $chart = Google::Chart->new(
    type => Google::Chart::Bar->new(
      orientation => "horizontal"
    )
  );

  # or

  my $chart = Google::Chart->new(
    type => {
      module => "Bar",
      args   => {
        orientation => "horizontal"
      }
    }
  );

=item size

Specifies the chart size. Strings like "400x300", hash references, or already
instantiated objects can be used:

  my $chart = Google::Chart->new(
    size => "400x300",
  );

  my $chart = Google::Chart->new(
    size => {
      width => 400,
      height => 300
    }
  );

=item marker

Specifies the markers that go on line charts.

=item axis

Specifies the axis labels and such that go on line and bar charts

=item legend

=item color

=item fill

=item

=back

=head2 as_uri()

Returns the URI that represents the chart object.

=head2 render()

Generates the chart image, and returns the contents.
This method internally uses LWP::UserAgent. If you want to customize LWP settings, create an instance of LWP::UserAgent and pass it in the constructor

    Google::Chart->new(
        ....,
        ua => LWP::UserAgent->new( %your_args )
    );

Proxy settings are automatically read via LWP::UserAgent->env_proxy(), unless you specify GOOGLE_CHART_ENV_PROXY environment variable to 0

=head2 render_to_file( %args )

Generates the chart, and writes the contents out to the file specified by
`filename' parameter

=head2 BASE_URI

The base URI for Google Chart

=head1 FEEDBACK

We don't believe that we fully utilize Google Chart's abilities. So there
might be things missing, things that should be changed for easier use.
If you find any such case, PLEASE LET US KNOW! Suggestions are welcome, but
code snippets, pseudocode, or even better, test cases, are most welcome.

=head1 TODO

=over 4

=item Standardize Interface

Objects need to expect data in a standard format. This is not the case yet.
(comments welcome)

=item Moose-ish Errors

I've been reported that some Moose-related errors occur on certain platforms.
I have not been able to reproduce it myself, so if you do, please let me
know.

=back

=head1 AUTHORS

Daisuke Maki C<< <daisuke@endeworks.jp> >> (current maintainer)

Nobuo Danjou C<< <nobuo.danjou@gmail.com> >>

Marcel Grünauer C<< <marcel@cpan.org> >> (original author)

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
