[![Build Status](https://travis-ci.org/brummett/JSON-String.svg?branch=master)](https://travis-ci.org/brummett/JSON-String)

## Name

JSON::String - Automatically update a string contianing JSON when a data structure changes

## Synopsis

    my $json_string = q({ a: 1, b: 2, c: [ 4, 5, 6 ] });
    my $data = JSON::String->tie($json_string);

    $data->{a} = 'changed'; # $json_string now contains: { "a": "changed", "b": 2, "c"; [ 4, 5, 6 ] }
    @{$data->{c}} = [qw(this data changed)]; { "a": "changed", "b": 2, "c": ["this", "data", "changed"] }

