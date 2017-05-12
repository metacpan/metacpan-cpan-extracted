eval <<'EOT';
sub foo {
    $i = 1;
    $i = 2;
    $i = 3;
}
EOT

foo();
foo();

1;
