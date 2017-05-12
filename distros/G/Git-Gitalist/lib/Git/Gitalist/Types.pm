package Git::Gitalist::Types;

use MooseX::Types -declare => [qw/ SHA1 /];

use MooseX::Storage::Engine ();

use MooseX::Types::DateTime qw/ DateTime /;
use MooseX::Types::Common::String qw/ NonEmptySimpleStr /;
use MooseX::Types::Moose qw/ ArrayRef /;

subtype SHA1,
    as NonEmptySimpleStr,
    where { $_ =~ qr/^[0-9a-fA-F]{40}$/ },
    message { q/Str doesn't look like a SHA1./ };

coerce SHA1,
    from NonEmptySimpleStr,
    via { 1 };

MooseX::Storage::Engine->add_custom_type_handler(
    DateTime,
        expand   => sub {
            my $val = shift;
            Carp::confess("Not implemented");
        },
        collapse => sub {
            $_[0]->ymd('-') . 'T' . $_[0]->hms(':') . 'Z' 
        },
);

1;
