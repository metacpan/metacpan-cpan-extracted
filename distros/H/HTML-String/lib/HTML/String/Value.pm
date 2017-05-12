package HTML::String::Value;

use strictures 1;
use UNIVERSAL::ref;
use Safe::Isa;
use Scalar::Util qw(blessed);
use Data::Munge;

use overload
    '""'   => '_hsv_escaped_string',
    '.'    => '_hsv_dot',
    'bool' => '_hsv_is_true',

    fallback => 1,
;

sub new {
    if (blessed($_[0])) {
        my $c = shift;
        return $c->_hsv_unescaped_string->new(@_);
    }
    my ($class, @raw_parts) = @_;

    my $opts = (ref($raw_parts[-1]) eq 'HASH') ? pop(@raw_parts) : {};

    my @parts = map {
        if (ref($_) eq 'ARRAY') {
            $_
        } elsif ($_->$_isa(__PACKAGE__)) {
            @{$_->{parts}}
        } else {
            [ $_, 0 ]
        }
    } @raw_parts;

    my $self = bless { parts => \@parts, %$opts }, $class;

    return $self;
}

sub AUTOLOAD {
    my $invocant = shift;
    (my $meth = our $AUTOLOAD) =~ s/.*:://;
    die "No such method ${meth} on ${invocant}"
        unless ref($invocant);
    return $invocant->_hsv_unescaped_string->$meth(@_);
}

sub _hsv_escaped_string {
    my $self = shift;

    if ($self->{ignore}{scalar caller}) {
        return $self->_hsv_unescaped_string;
    }

    return join '', map +(
        $_->[1]
            ? byval { 
                s/&/&amp;/g;
                s/</&lt;/g;
                s/>/&gt;/g;
                s/"/&quot;/g;
                s/'/&#39;/g;
              } $_->[0]
            : $_->[0]
    ), @{$self->{parts}};
}

sub _hsv_unescaped_string {
    my $self = shift;

    return join '', map $_->[0], @{$self->{parts}};
}

sub _hsv_dot {
    my ($self, $str, $prefix) = @_;

    return $self unless defined $str && length $str;

    my @parts = @{$self->{parts}};

    my @new_parts = (
        $str->$_isa(__PACKAGE__)
            ? @{$str->{parts}}
            : [ $str, 1 ]
    );

    if ( $prefix ) {
        unshift @parts, @new_parts;
    } else {
        push @parts, @new_parts;
    }

    return bless({ %$self, parts => \@parts }, blessed($self));
}

sub _hsv_is_true {
    my ($self) = @_;
    return 1 if grep $_, map $_->[0], @{$self->{parts}};
}

# we need to local $@ here because some modules (cough, TT, cough)
# will do a 'die $@ if $@' without realising that it wasn't their eval
# that set it

sub isa {
    my $self = shift;
    return (
        do {
            local $@;
            eval { blessed($self) and $self->_hsv_unescaped_string->isa(@_) }
        }
        or $self->SUPER::isa(@_)
    );
}

sub can {
    my $self = shift;
    return (
        do {
            local $@;
            eval { blessed($self) and $self->_hsv_unescaped_string->can(@_) }
        }
        or $self->SUPER::can(@_)
    );
}

sub ref { '' }

sub DESTROY { }

1;

__END__

=head1 NAME

HTML::String::Value - A scalar hiding as a string on behalf of L<HTML::String>

=head1 SYNOPSIS

Usually, you'd create this with L<HTML::String>'s L<HTML::String/html> export
but:

  my $html = HTML::String::Value->new($do_not_escape_this);

  my $html = HTML::String::Value->new([ $do_not_escape_this, 0 ]);

  my $html = HTML::String::Value->new([ $do_escape_this, 1 ]);

  my $html = HTML::String::Value->new($already_an_html_string_value);

  my $html = HTML::String::Value->new(@an_array_of_any_of_the_above);

  my $html = HTML::String::Value->new(
    @parts, { ignore => { package_name => 1 } }
  );

=head1 METHODS

=head2 new

  my $html = HTML::String::Value->new(@parts, \%options?);

Each entry in @parts consists of one of:

  'some text that will not be escaped'

  [ 'some text that will not be escaped', 0 ]

  [ 'text that you DO want to be escaped', 1 ]

  $existing_html_string_value

Currently, the %options hashref contains only:

  (
    ignore => { 'Package::One' => 1, 'Package::Two' => 1, ... }
  )

which tells this value object to ignore whether escaping has been requested
for any particular chunk and instead to provide the unescaped version.

When called on an existing object, does the equivalent of

  $self->_hsv_unescaped_string->new(@args);

to fit in with the "pretending to be a class name" behaviour provided by
L</AUTOLOAD>.

=head2 _hsv_escaped_string

  $html->_hsv_escaped_string

Returns a concatenation of all parts of this value with those marked for
escaping escaped, unless the calling package has been specified in the
C<ignore> option to L</new>.

If the calling package has been marked as ignoring escaping, returns the
result of L</_hsv_unescaped_string>.

You probably shouldn't be calling this directly.

=head2 _hsv_unescaped_string

  $html->_hsv_unescaped_string

Returns a concatenation of all parts of this value with no escaping performed.

You probably shouldn't be calling this directly.

=head2 _hsv_dot

  $html->_hsv_dot($other_string, $reversed)

Returns a new value object consisting of the two values' parts concatenated
together (in reverse if C<$reversed> is true).

Unlike L</new>, this method defaults to escaping a bare string provided.

You probably shouldn't be calling this directly.

=head2 _hsv_is_true

  $html->_hsv_is_true

Returns true if any of this value's parts are true.

You probably shouldn't be calling this directly.

=head2 AUTOLOAD

  $html->method_name(@args)

This calls the equivalent of

  $html->_hsv_unescaped_string->method_name(@args)

to allow for class method calls even when the class name has ended up being
turned into a value object.

=head2 isa

  $html->isa($name)

This method returns true if either the value or the unescaped string are
isa the supplied C<$name> in order to allow for class method calls even when
the class name has ended up being turned into a value object.

=head2 can

  $html->can($name)

This method returns a coderef if either the value or the unescaped string
provides this method; methods on the unescaped string are preferred to allow
for class method calls even when the class name has ended up being
turned into a value object.

=head2 ref

  $html->ref

This method always returns C<''>. Since we register ourselves with
L<UNIVERSAL::ref>, this means that

  ref($html);

will also return C<''>, which means that modules loaded after this one will
see a value object as being a plain scalar unless they're explicitly checking
the defined-ness of the return value of C<ref>, which probably means that they
wanted to spot people cheating like we're trying to.

If you have trouble with things trying to treat a value object as something
other than a string, try loading L<UNIVERSAL::ref> earlier.

=head2 DESTROY

Overridden to do nothing so that L</AUTOLOAD> doesn't trap it.

=head1 OPERATOR OVERLOADS

=head2 stringification

Stringification is overloaded to call L</_hsv_escaped_string>

=head2 concatenation

Concatentation is overloaded to call L</_hsv_dot>

=head2 boolification

Boolification is overloaded to call L</_hsv_is_true>

=head1 AUTHORS

See L<HTML::String> for authors.

=head1 COPYRIGHT AND LICENSE

See L<HTML::String> for the copyright and license.

=cut
