package Graph::Template::TextObject;

use strict;

BEGIN {
    use vars qw(@ISA);
    @ISA = qw(Graph::Template::Base);

    use Graph::Template::Base;

#    use Unicode::String;
}

# This is a helper object. It is not instantiated by the user,
# nor does it represent an XML object. Rather, certain elements,
# such as <textbox>, can use this object to do text with variable
# substitutions.

sub new
{
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->{STACK} = [] unless UNIVERSAL::isa($self->{STACK}, 'ARRAY');

    return $self;
}

sub resolve
{
    my $self = shift;
    my ($context) = @_;

#    my $t = Unicode::String::utf8('');
    my $t = '';

    for my $tok (@{$self->{STACK}})
    {
        my $val = Graph::Template::Factory::isa($tok, 'VAR')
            ? $tok->resolve($context)
            : $tok;

#        $t .= Unicode::String::utf8("$val");
        $t .= $val;
    }

    return $t;
}

1;
__END__
