package Excel::Template::TextObject;

use strict;

BEGIN {
    use vars qw(@ISA);
    @ISA = qw(Excel::Template::Base);

    use Excel::Template::Base;
}

# This is a helper object. It is not instantiated by the user,
# nor does it represent an XML object. Rather, certain elements,
# such as <textbox>, can use this object to do text with variable
# substitutions.

sub new
{
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->{STACK} = []
        unless defined $self->{STACK} &&
            ref $self->{STACK} eq 'ARRAY';

    return $self;
}

sub resolve
{
    my $self = shift;
    my ($context) = @_;

    my $use_unicode = $context->use_unicode;

    my $t;
    if ($use_unicode)
    {
        require Unicode::String;
        $t = Unicode::String::utf8('');
    }
    else
    {
        $t = '';
    }

    for my $tok (@{$self->{STACK}})
    {
        my $val = $tok;
        $val = $val->resolve($context)
            if Excel::Template::Factory::is_embedded( $val );

        $t .= $use_unicode
            ? Unicode::String::utf8("$val")
            : $val;
    }

    return $t;
}

1;
__END__

=head1 NAME

Excel::Template::TextObject - Excel::Template::TextObject

=head1 PURPOSE

=head1 NODE NAME

=head1 INHERITANCE

=head1 ATTRIBUTES

=head1 CHILDREN

=head1 AFFECTS

=head1 DEPENDENCIES

=head1 USAGE

=head1 AUTHOR

Rob Kinyon (rob.kinyon@gmail.com)

=head1 SEE ALSO

=cut
