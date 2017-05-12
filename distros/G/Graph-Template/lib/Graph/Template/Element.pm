package Graph::Template::Element;

use strict;

BEGIN {
    use vars qw(@ISA);
    @ISA = qw(Graph::Template::Base);

    use Graph::Template::Base;
}

sub get_value
{
    my $self = shift;
    my ($context, $attr) = @_;

    my $txt = $context->get($self, $attr);
    if (defined $txt)
    {
        my $txt_obj = Graph::Template::Factory->create('TEXTOBJECT');
        push @{$txt_obj->{STACK}}, $txt;
        $txt = $txt_obj->resolve($context);
    }
    elsif ($self->{TXTOBJ})
    {
        $txt = $self->{TXTOBJ}->resolve($context);
    }
    else
    {
#        $txt = Unicode::String::utf8('');
        $txt = '';
    }

    return $txt;
}

1;
__END__
