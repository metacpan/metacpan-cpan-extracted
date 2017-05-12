DateTimeX::TO_JSON
==================

Injects a TO_JSON method to a DateTime so that it can be serialized by JSON
serializers.

To install this module from source

    dzil install

To read the documentation

    perldoc DateTimeX::TO_JSON

Brief Synopsis

    use DateTime;
    use DateTimeX::TO_JSON; # formatter => DateTime::Format::RFC3339;
    use JSON;

    my $out = JSON->new->convert_blessed(1)->encode([DateTime->now]);

You can specify any formatter that conforms to the DateTime::Format methods.
