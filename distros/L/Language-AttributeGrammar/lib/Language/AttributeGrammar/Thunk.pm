package Language::AttributeGrammar::Thunk;

use Carp::Clan '^Language::AttributeGrammar';
use Perl6::Attributes;

=head1 NAME

Language::AttributeGrammar::Thunk - Delayed code logic

=head1 DESCRIPTION

This is a four stage thunk.

    stage 1: code unset
    stage 2: code set, unevaluated
    stage 3: code being evaluated
    stage 4: code evaluated and return value stored

=over

=cut

sub new {
    my ($class, $code, $attr, $at) = @_;
    my $self = bless {
        stage => ($code ? 2 : 1),
        code  => $code,
        value => undef,
        attr  => $attr,
        at    => $at,
    } => ref $class || $class;
    $self;
}

=item * new($class, ?$code, ?$attr, ?$at)

Creates a new thunk object.  If $code, $attr, and $at are specified,
initializes the object via C<set>.

=cut

sub set {
    my ($self, $code, $attr, $at) = @_;
    unless ($.stage == 1) {
        croak "Attribute '$attr' defined more than once at $at and $.at";
    }
    $.at = $at;
    $.code = $code;
    $.stage++;
}

=item * $thunk->set($code, $attr, $at)

Set the code for a thunk.  $attr is the name of the attribute that this code is
evaluating (for example "Cons:length") and $at is a description of the location
at which the thunk was defined (for example "grammar.pl line 42").  Both of the
latter two are only used for diagnostic purposes.  This method is only valid
when the thunk is in stage 1 (and it moves it to stage 2).

=cut

sub get {
    my ($self, $attr, $at) = @_;
    if ($.stage == 4) {
        $.value;
    }
    elsif ($.stage == 2) {
        $.stage++;
        $.value = $.code->();
        undef $.code;
        $.stage++;
        $.value;
    }
    elsif ($.stage == 3) {
        croak "Infinite loop on attribute '$attr' at $at";
    }
    else {
        croak "Attribute '$attr' not defined at $at";
    }
}

=item * $thunk->get($attr, $at)

valuate a thunk.  $attr is the name of the attribute that is being fetched,
and $at is a description of the location at which it is being fetched.  In
stage 1 it fails because there is no code to evaluate, and in stage 3 it fails
because this implies that an infinite loop would occur.  After successful
execution of this method, the thunk is in stage 4.

=cut

1;

=back

=head1 SEE ALSO

L<Language::AttributeGrammar>, L<Data::Lazy>
