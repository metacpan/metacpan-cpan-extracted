package Form::Field;
use overload '""' => \&render;
use Carp;
use base qw(HTML::Element Form::Base Class::Accessor);
Form::Field->mk_attributes(qw/type _validation_types _tag/);
Form::Field->mk_accessors(qw/name _validation _form/);
Form::Field->_validation_types([ qw/ javascript perl / ]);
Form::Field->_tag("input");
use Module::Pluggable search_path=>['Form::Field'], require => 1;
my $sym = 0;

sub render { 
    my $self = shift;
    if ($self->_validation and
        my $js = $self->_validation->{javascript}) {
        $self->attr("id", "field".++$sym);
        $self->attr("onblur", qq{validate('field$sym', '}.$self->name.
                              qq{', $js)});
    }
    $self->as_HTML; 
}

sub add_validation {
    my ($self, $validation) = @_;
    # This could be a regex, a hash of regexen, or a module name.
    # We want to turn it into a hash.
    if (ref $validation and UNIVERSAL::isa($validation, "Regexp")) {
        $self->_validation({
            map { $_ => $validation } @{$self->_validation_types}
        });
    } elsif (ref($validation) eq "HASH") {
        $self->_validation($validation)
    } else {
        # We'll assume it's a module name, then.
        Form::Maker->_load_and_run($validation);
        $self->_validation($validation->validate($self));
    }
}

1;
