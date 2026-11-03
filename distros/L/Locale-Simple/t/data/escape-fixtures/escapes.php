<?php
// PHP: double quotes and heredoc know the escapes, an unknown one keeps its
// backslash; \x and octal are bytes. Single quotes and nowdoc keep the text.
l("PHP newline\n");
l("PHP tab\t dollar \$ quote \" backslash \\ keeps \q");
l("PHP hex \x41\xc3\xa4 octal \101 unicode \u{e4}");
l('PHP single \n stays, \\ is one, \' is a quote');
l(<<<EOT
PHP heredoc\tdone \"quoted\"
EOT);
l(<<<'EOT'
PHP nowdoc\t stays
EOT);
l("PHP joined\n" . 'PHP raw\t' . "\tPHP end");
ln("PHP one\n", "PHP many\n", $n);
l("0");
lp("0", "PHP context zero");
