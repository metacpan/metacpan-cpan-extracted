package Document::Maker::Source::FileScan;

use Moose;

use Scalar::Util qw/blessed/;
use Document::Maker::FileFinder::Query;

with map { "Document::Maker::Role::$_" } qw/Component Dependency/;

has finder => qw/is ro required 1/, handles => [qw/found fresh freshness/];

sub BUILD {
    my $self = shift;
    my $finder = $self->finder;
    return if blessed $finder;
    if (Document::Maker::FileFinder::Query->recognize($finder)) {
        $self->{finder} = Document::Maker::FileFinder::Query->new(query => $finder);
    }
}

sub make {
    my $self = shift;
    for my $found (@{ $self->found }) {
        next if -e $found;
        $self->log->debug("Don't know how to make: ", $found) and return 0 unless $self->maker->make($found);
    }
}


1;
