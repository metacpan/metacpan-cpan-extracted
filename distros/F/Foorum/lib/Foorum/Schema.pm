package Foorum::Schema;

use Moose;

our $VERSION = '1.001000';

extends 'DBIx::Class::Schema';

__PACKAGE__->load_classes;

use Foorum::XUtils ();

has 'base_path' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        return Foorum::XUtils::base_path();
    }
);

has 'config' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        return Foorum::XUtils::config();
    }
);

has 'cache' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        return Foorum::XUtils::cache();
    }
);

has 'theschwartz' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        return Foorum::XUtils::theschwartz();
    }
);

has 'tt2' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        return Foorum::XUtils::tt2();
    }
);

around 'connect' => sub {
    my $next = shift;

    my $s = $next->(@_);
    $s->storage->sql_maker->quote_char('`');
    $s->storage->sql_maker->name_sep('.');
    return $s;
};

1;
