use Test::More tests => 7;
use HTML::Template::Pluggable;
use HTML::Template::Plugin::Dot;
use Carp 'croak';

sub render {
    my( $template, %vars ) = @_;

    my $t = HTML::Template::Pluggable->new(
        scalarref => \$template
    );
    eval { $t->param( %vars ) };

    return $t->output;
}

my $out;

$out = render(
    "<tmpl_var testobj.attribute>",
    testobj => testclass->new()
);
is( $out, 'attribute_value' );

$out = render(
    "<tmpl_var testobj.hello>",
    testobj => testclass->new()
);
is( $out, 'hello' );

$out = render(
    "<tmpl_var testobj.echo('1')>",
    testobj => testclass->new()
);
is( $out, '1' );

$out = render(
    "<tmpl_var testobj.echo(somevar)>",
    testobj => testclass->new(),
    somevar => 'somevalue4'
);
is( $out, 'somevalue4' );

$out = render(
    "<tmpl_var name=\"testobj.test(somevar)\">",
    testobj => testclass->new(),
    somevar => 'somevalue5'
);
# contribution expected 'somevalue5', but since test() isn't
# a method of testclass, this should return nothing.
is( $out, '' );

$out = render(
    "<tmpl_var name='somevar'><tmpl_var testobj.echo(somevar)>",
    testobj => testclass->new(),
    somevar => 'somevalue'
);
is( $out, 'somevaluesomevalue' );

$out = render(
    "<tmpl_var name='somevar'>",
    testobj => testclass->new(),
    somevar => 'somevalue6'
);
is( $out, 'somevalue6' );

package testclass;

sub new {
    my $class = shift;
    my $self = { attribute => 'attribute_value' };
    return bless $self, $class;
}

sub echo {
    shift;
    return join(', ', @_);
}

sub hello {
    return 'hello';
}

__END__
