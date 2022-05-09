
use strict;
use warnings;

use Test::More 'no_plan';

use HTML::Template::Pluggable;
use HTML::Template::Plugin::Dot;

{
    package My::Auto;

    sub new { bless {}, shift }
    sub foo { "foo" }
    sub AUTOLOAD { "bar" }
}

sub render {
    my ($str, @params) = @_;
    my $t = HTML::Template::Pluggable->new(
        scalarref => \$str, die_on_bad_params => 0
    );
    $t->param( @params );
    return $t->output;
}
my $obj = My::Auto->new;
my $x = render(q{<tmpl_var auto.foo>}, auto => $obj);
is $x, 'foo', 'can("foo")';

is $obj->quux, "bar", "object can autoload";

my $y = render(q{<tmpl_var auto.quux>}, auto => $obj);
is $y, 'bar', 'can("AUTOLOAD")';

__END__
ok 1 - can("foo")
ok 2 - can("AUTOLOAD")
1..2
