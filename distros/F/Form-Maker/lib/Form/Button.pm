package Form::Button;
use base "HTML::Element";
use overload '""' => sub { shift->as_HTML };
use strict; use warnings;

sub name { shift->attr("name") }

sub new {
    my ($self, $label) = @_;
    $self->SUPER::new("input", 
        type => ($label eq "reset" ? "reset" : "submit"),
        name => $label
    );
}

1;
