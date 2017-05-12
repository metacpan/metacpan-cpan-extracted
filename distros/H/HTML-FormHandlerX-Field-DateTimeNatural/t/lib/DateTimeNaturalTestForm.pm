package DateTimeNaturalTestForm;

use HTML::FormHandler::Moose;
extends 'HTML::FormHandler';

use MooseX::Types::DateTime;

has 'time_zone' => (
    is         => 'rw',
    isa        => 'DateTime::TimeZone',
    coerce     => 1,
);

has_field 'datetimenatural' => (
    type         => 'DateTimeNatural',
);

1; # eof

