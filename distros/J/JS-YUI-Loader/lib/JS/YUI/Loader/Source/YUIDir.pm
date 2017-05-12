package JS::YUI::Loader::Source::YUIDir;

use Moose;
extends qw/JS::YUI::Loader::Source/;

use Path::Class;
use JS::YUI::Loader::Carp;
use JS::YUI::Loader;

has version => qw/is ro required 1 lazy 1/, default => JS::YUI::Loader->LATEST_YUI_VERSION;
has base => qw/is ro/;

sub BUILD {
    my $self = shift;
    my $given = shift;
    my $base = $self->base || $given->{dir} or croak "Don't have a base dir";
    my $version = $self->version || 0;
    $version = JS::YUI::Loader->LATEST_YUI_VERSION if $version eq 0;
    $base =~ s/%v/$version/g;
    $base =~ s/%%/%/g;
    $self->{base} = Path::Class::Dir->new($base);
}

override file => sub {
    my $self = shift;
    my $item = shift;
    my $filter = shift;

    $item = $self->catalog->item($item);
    return $self->base->file($item->path($filter));
};

1;
