<?php
// PHP: double quotes and heredoc interpolate $name, {$...} and ${...}; such a
// literal is not a msgid, the calls in its arguments still are.
l("PHP hello $name is not read %s", l("PHP inner of interpolation"));
l("PHP braces {$name} is not read");
l("PHP dollar brace ${name} is not read");
l("PHP member $obj->name is not read");
l("PHP joined " . "PHP $name is not read");
l(<<<EOT
PHP heredoc $name is not read
EOT);
l("PHP escaped \$name and {\$name} and %2\$s");
l("PHP lone 5 $ and $1 and { brace }");
l(<<<EOT
PHP heredoc escaped \$name
EOT);
l(<<<'EOT'
PHP nowdoc $name stays
EOT);
l('PHP single $name {$name} stays');
l( <<<EOT
PHP heredoc after a space
EOT);
l("PHP joined " . <<<EOT
PHP heredoc after a dot
EOT);
