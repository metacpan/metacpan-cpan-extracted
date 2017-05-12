package JS::YUI::Loader::Source::Internet;

use Moose;
extends qw/JS::YUI::Loader::Source/;
#use JS::YUI::Loader::Carp;

use JS::YUI::Loader;
use URI;

has version => qw/is ro required 1 lazy 1/, default => JS::YUI::Loader->LATEST_YUI_VERSION;
has base => qw/is ro/, default => "http://yui.yahooapis.com/%v/build";

sub BUILD {
    my $self = shift;
    my $given = shift;
    my $base = $self->base;
    my $version = $self->version || 0;
    $version = JS::YUI::Loader->LATEST_YUI_VERSION if $version eq 0;
    $base =~ s/%v/$version/g;
    $base =~ s/%%/%/g;
    $base = URI->new("$base") unless blessed $base && $base->isa("URI");
    $self->{base} = $base;
}

override uri => sub {
    my $self = shift;
    my $item = shift;
    my $filter = shift;

    $item = $self->catalog->item($item);
    return $item->path_uri($self->base, $filter);
};

1;
