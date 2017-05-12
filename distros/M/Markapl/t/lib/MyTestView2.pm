package MyTestView2;
use strict;
use warnings;

use Markapl;
use Markapl::Helpers;

template '/helper-heads-cells' => sub {
    table {
	heads qw(Name Age Weight Height);
	cells qw(Gugod 29 100kg 170cm);
    }
};

template '/helper-THs-TDs' => sub {
    table {
	THs qw(Name Age Weight Height);
	TDs qw(Gugod 29 100kg 170cm);
    }
};

template '/helper-ths-tds' => sub {
    table {
	ths qw(Name Age Weight Height);
	tds qw(Gugod 29 100kg 170cm);
    }
};

template '/helper-linklist' => sub {
    linklist(
        "foobar" => "/path/to/foobar",
        "fnord" => "/path/to/fnrd",
    );
};

1;
