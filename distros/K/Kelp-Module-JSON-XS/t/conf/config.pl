{
    modules      => ['JSON::XS'],
    modules_init => {
        'JSON::XS' => {
            pretty        => 0,
            allow_blessed => 1,
            utf8          => 1,
        }
    }
}
