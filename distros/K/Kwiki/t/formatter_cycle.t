use lib 't', 'lib';
use strict;
use warnings;
use Test::More;
BEGIN {
    eval "use Test::Memory::Cycle";
    if ($@) {
        plan skip_all => 'These tests require Test::Memory::Cycle';
    }
    else {
        plan tests => 2;
    }
}
use Kwiki;

{
    my $kwiki = Kwiki->new;
    my $hub = $kwiki->load_hub({formatter_class => 'Kwiki::Formatter'});
    my $formatter = $hub->formatter;

    $formatter->text_to_html(text());

    memory_cycle_ok($formatter, 'check for cycles in the formatter after parsing something');
}

{
    my $kwiki = Kwiki->new;
    my $hub = $kwiki->load_hub({formatter_class => 'Kwiki::Formatter'});
    my $formatter_top =
        $hub->formatter->top_class->new(text => text());

    $formatter_top->to_html;

    memory_cycle_ok($formatter_top,
                    'check for cycles in the formatter top class after parsing something');
}

sub text {
    <<'EOF';
----

= ABC
== Foo

* 1
* 2

0 1
0 2
0 3

Plain text

.pre
Pre formatter
.pre

| 1 | -2- | 3 |
| _a_ | /b/ | *c* |
| 
  sub foo {
    my $autarch;
  }
| <html> | * foo
|

http://www.urth.org/
[http://www.urth.org/ Urth]

{{ *asis* }}

---

EOF
}
