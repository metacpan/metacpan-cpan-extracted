#!/use/bin/env php

<?php

$file = $argv[1];
$ini_array = parse_ini_file( $file );
print_r($ini_array);

