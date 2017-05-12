# use Carp qw(verbose);

use Test::More qw/ no_plan /;

{
    # submitted by Dan Horne
    package T1;
    use strict;

    sub name {
        my $self = shift;
        $self->{name} ||= shift;
        return $self->{name};
    }

    sub greeting {
        my $self = shift;
        my $name = shift;
        return "hello $name";
    }

    sub new {
        my $class = shift;
        bless {}, $class;
    }

    1;
}

use HTML::Template::Pluggable;
use HTML::Template::Plugin::Dot;

my $text = '<tmpl_var name="t.greeting(t.name())">';

my $test = T1->new();
$test->name('bob');
is "hello bob", $test->greeting('bob');
eval {
    my $template = HTML::Template::Pluggable->new(scalarref => \$text);
    $template->param('t' => $test);
    my $out = $template->output;
    is($out, T1->greeting("bob"));
} or warn $@;

__END__
