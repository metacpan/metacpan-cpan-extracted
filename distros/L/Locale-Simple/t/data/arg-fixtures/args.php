<?php
// Fixture for t/52-scrape-args.t: what follows the strings is code.
echo l("PHP var %s", $name);
$y = l("PHP assign %s", $user->name);
echo ln("PHP count one", "PHP count many", $n);
echo ln("PHP method %d", "PHP methods %d", $obj->count());
echo ln("PHP count fn %d", "PHP count fns %d", count($items), $items['a,b']);
echo l("PHP paren %s", ")");
echo l("PHP comma %s %s", ",", 'it\'s, (');
echo l("PHP escape %s", "tab\t(");
echo l("PHP heredoc arg %s", <<<EOT
a, ( b
EOT
);
echo l("PHP nested %s and %s", l("PHP Apple"), $x);
echo lp("PHP_ctx", "PHP ctx %s", $arr["key"]);
echo l(
    "PHP multi %s %s",
    $first,
    implode(", ", array_map(fn($u) => $u->name, $list)),
);
echo ln("PHP nested count one", "PHP nested count many", count(l("PHP in count")));
echo l($notConstant, l("PHP inside skipped"));
