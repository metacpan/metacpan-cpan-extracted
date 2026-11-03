<html>
<p>Please don't panic, it's only a fixture.</p>
<?php

echo \Locale\Simple\l('PHP fqn call');
echo l(<<<EOT
PHP heredoc "quoted" and it's fine
second line
EOT
);
echo ln(<<<'EOT'
PHP nowdoc one $notvar
EOT
, 'PHP nowdoc many', 2);
echo l("PHP escaped \$dollar and \"quote\"");
echo l("PHP interpolated $name here");
echo lp('PHP_ctx', 'PHP single ' . 'concat');
?>
<p>Isn't this fun? Still no string here.</p>
<?php echo ld('php_dom', 'PHP after inline html'); ?>
