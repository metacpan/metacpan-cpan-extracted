use strict;
use warnings;

{{
    $name = $dist->name =~ s/-/::/gr ; ''
}}use {{ $name }};

my $app = {{ $name }}->apply_default_middlewares({{ $name }}->psgi_app);
$app;

