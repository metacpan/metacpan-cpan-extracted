use strict;
use warnings;
use Test::Base;
use HTML::DoCoMoCSS;

BEGIN { use_ok 'HTML::DoCoMoCSS' }

filters {
    input => ['inliner', 'untabify'],
};

sub untabify {
    my $src = shift;
    $src =~ s/\t/    /g;
    return $src;
}

sub inliner {
    my $html = shift;
    my $inliner = HTML::DoCoMoCSS->new(base_dir => 't/');
    return $inliner->apply($html)
}

run_is input => 'expected';

__END__

=== simple
--- input
<html>
<head>
<link rel="stylesheet" href="/css/foo.css" />
</head>
<body>
<div class="title">bar</div>
</body>
</html>
--- expected
<?xml version="1.0"?>
<html>
<head>
<link rel="stylesheet" href="/css/foo.css"/>
</head>
<body>
<div class="title" style="color:red">bar</div>
</body>
</html>

=== input tag
--- input
<html>
<head>
<link rel="stylesheet" href="/css/foo.css" />
</head>
<body>
<input type="text" name="foo" />
</body>
</html>
--- expected
<?xml version="1.0"?>
<html>
<head>
<link rel="stylesheet" href="/css/foo.css"/>
</head>
<body>
<input type="text" name="foo"/>
</body>
</html>

=== with doctype/xml
--- input
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//i-mode group (ja)//DTD XHTML i-XHTML(Locale/Ver.=ja/1.0) 1.0//EN" "i-xhtml_4ja_10.dtd">
<html>
<head>
<link rel="stylesheet" href="/css/foo.css" />
</head>
<body>
<div class="title">bar</div>
</body>
</html>
--- expected
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//i-mode group (ja)//DTD XHTML i-XHTML(Locale/Ver.=ja/1.0) 1.0//EN" "i-xhtml_4ja_10.dtd">
<html>
<head>
<link rel="stylesheet" href="/css/foo.css"/>
</head>
<body>
<div class="title" style="color:red">bar</div>
</body>
</html>

=== don't remove comments
--- input
<html>
<head>
<link rel="stylesheet" href="/css/foo.css" />
</head>
<body>
<div class="title">bar</div>
<!-- hoge -->
</body>
</html>
--- expected
<?xml version="1.0"?>
<html>
<head>
<link rel="stylesheet" href="/css/foo.css"/>
</head>
<body>
<div class="title" style="color:red">bar</div>
<!-- hoge -->
</body>
</html>

=== add more style
--- input
<html>
<head>
<link rel="stylesheet" href="/css/foo.css" />
</head>
<body>
<div class="title" style="background-color: blue">bar</div>
</body>
</html>
--- expected
<?xml version="1.0"?>
<html>
<head>
<link rel="stylesheet" href="/css/foo.css"/>
</head>
<body>
<div class="title" style="background-color: blue;color:red">bar</div>
</body>
</html>

=== override style
--- input
<html>
<head>
<link rel="stylesheet" href="/css/foo.css" />
</head>
<body>
<div class="title" style="color: blue">bar</div>
</body>
</html>
--- expected
<?xml version="1.0"?>
<html>
<head>
<link rel="stylesheet" href="/css/foo.css"/>
</head>
<body>
<div class="title" style="color: blue;color:red">bar</div>
</body>
</html>

=== numeric character reference
--- input
<html>
<head>
<link rel="stylesheet" href="/css/foo.css" />
</head>
<body>
<div>&#66666;</div>
</body>
</html>
--- expected
<?xml version="1.0"?>
<html>
<head>
<link rel="stylesheet" href="/css/foo.css"/>
</head>
<body>
<div>&#66666;</div>
</body>
</html>

=== a:pseudo
--- input
<html>
<head>
<link rel="stylesheet" href="/css/pseudo.css" />
</head>
<body>
<div class="foo">hoge</div>
</body>
</html>
--- expected
<?xml version="1.0"?>
<html>
<head>
<link rel="stylesheet" href="/css/pseudo.css"/>
<style type="text/css">a:visited {
    background-color: red;
    color: blue;
}
a:link {
    background-color: red;
    color: yellow;
}
</style></head>
<body>
<div class="foo" style="color:red">hoge</div>
</body>
</html>

=== get from http server
--- SKIP
--- input
<html>
<head>
<link rel="stylesheet" href="http://www.unoh.net/font2.css" />
</head>
<body>
<div>&#66666;</div>
</body>
</html>
--- expected
<html><head><link href="/css/foo.css" rel="stylesheet" /></head><body><div>&#66666;</div></body></html>

=== read from style tag
--- input
<html>
<head>
<link rel="stylesheet" href="/css/foo.css" />
<style>
.yes {
    color: white;
}
</style>
</head>
<body>
<div class="yes">bar</div>
</body>
</html>
--- expected
<?xml version="1.0"?>
<html>
<head>
<link rel="stylesheet" href="/css/foo.css"/>
<style>
.yes {
    color: white;
}
</style>
</head>
<body>
<div class="yes" style="color:white">bar</div>
</body>
</html>

=== XHTML name space
--- input
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//i-mode group (ja)//DTD XHTML i-XHTML(Locale/Ver.=ja/1.0) 1.0//EN" "i-xhtml_4ja_10.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<link rel="stylesheet" href="/css/foo.css" />
</head>
<body>
<div class="title">bar</div>
</body>
</html>
--- expected
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//i-mode group (ja)//DTD XHTML i-XHTML(Locale/Ver.=ja/1.0) 1.0//EN" "i-xhtml_4ja_10.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<link rel="stylesheet" href="/css/foo.css"/>
</head>
<body>
<div class="title" style="color:red">bar</div>
</body>
</html>

=== XHTML name space DTD default
--- input
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
<link rel="stylesheet" href="/css/foo.css" />
</head>
<body>
<div class="title">bar</div>
</body>
</html>
--- expected
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<link rel="stylesheet" href="/css/foo.css" />
</head>
<body>
<div class="title" style="color:red">bar</div>
</body>
</html>

