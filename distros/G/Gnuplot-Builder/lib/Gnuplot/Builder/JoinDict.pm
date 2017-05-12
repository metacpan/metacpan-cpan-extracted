package Gnuplot::Builder::JoinDict;
use strict;
use warnings;
use Gnuplot::Builder::PartiallyKeyedList;
use Carp;
use Exporter 5.57 qw(import);
use overload '""' => "to_string";

our @EXPORT_OK = qw(joind);

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        separator => defined($args{separator}) ? $args{separator} : "",
        pkl => Gnuplot::Builder::PartiallyKeyedList->new,
        filter => $args{filter},
        validator => $args{validator},
    }, $class;
    croak "filter must be a code-ref" if defined($self->{filter}) && ref($self->{filter}) ne "CODE";
    croak "validator must be a code-ref" if defined($self->{validator}) && ref($self->{validator}) ne "CODE";
    my $content = $args{content};
    $content = [] if not defined $content;
    croak "content must be an array-ref" if ref($content) ne "ARRAY";
    $self->_set_destructive(@$content);
    return $self;
}

sub joind {
    my ($separator, @content) = @_;
    return __PACKAGE__->new(
        separator => $separator,
        content => \@content
    );
}

sub get_all_keys {
    return $_[0]->{pkl}->get_all_keys;
}

sub get_all_values {
    return $_[0]->{pkl}->get_all_values
}

sub to_string {
    my ($self) = @_;
    my @vals = defined($self->{filter})
        ? $self->{filter}->($self)
        : $self->{pkl}->get_all_values;
    return join($self->{separator}, grep { defined($_) } @vals);
}

sub get {
    my ($self, $key) = @_;
    return undef if not defined $key;
    return $self->{pkl}->get($key);
}

sub set {
    my ($self, @content) = @_;
    return $self->clone->_set_destructive(@content);
}

sub set_all {
    my ($self, $value) = @_;
    return $self->set(map { $_ => $value } $self->{pkl}->get_all_keys);
}

sub _validate {
    my ($self) = @_;
    $self->{validator}->($self) if defined $self->{validator};
}

sub _set_destructive {
    my ($self, @content) = @_;
    croak "odd number of elements in content" if @content % 2 != 0;
    foreach my $i (0 .. (@content / 2 - 1)) {
        my ($key, $value) = @content[2*$i, 2*$i+1];
        croak "undefined key in content" if not defined $key;
        $self->{pkl}->set($key, $value);
    }
    $self->_validate();
    return $self;
}

sub clone {
    my ($self) = @_;
    my $clone = ref($self)->new(separator => $self->{separator}, filter => $self->{filter});
    $clone->{pkl}->merge($self->{pkl});
    $clone->{validator} = $self->{validator};
    return $clone;
}

sub delete {
    my ($self, @keys) = @_;
    my $clone = $self->clone;
    $clone->{pkl}->delete($_) foreach grep { defined($_) } @keys;
    $clone->_validate();
    return $clone;
}

sub separator {
    my ($self) = @_;
    return $self->{separator};
}

sub Lens {
    my ($self, $key) = @_;
    require Gnuplot::Builder::Lens;
    return Gnuplot::Builder::Lens->new(
        "get", "set", $key
    );
}

1;
__END__

=pod

=head1 NAME

Gnuplot::Builder::JoinDict - immutable ordered hash that joins its values in stringification

=head1 SYNOPSIS

    use Gnuplot::Builder::JoinDict;
    
    my $dict = Gnuplot::Builder::JoinDict->new(
        separator => ', ',
        content => [x => 640, y => 480]
    );
    "$dict";  ## => 640, 480
    
    $dict->get("x"); ## => 640
    $dict->get("y"); ## => 480
    
    my $dict2 = $dict->set(y => 16);
    "$dict";   ## => 640, 480
    "$dict2";  ## => 640, 16
    
    my $dict3 = $dict2->set(x => 8, z => 32);
    "$dict3";  ## => 8, 16, 32
    
    my $dict4 = $dict3->delete("x", "y");
    "$dict4";  ## => 32

=head1 DESCRIPTION

Basically L<Gnuplot::Builder::JoinDict> is just an ordered associative array (sometimes called as a "dictionary"),
so it's the same as L<Tie::IxHash>.

The difference from L<Tie::IxHash> is:

=over

=item *

L<Gnuplot::Builder::JoinDict> is B<immutable>. Every setter method doesn't alter the original object, but returns a new one.

=item *

When a L<Gnuplot::Builder::JoinDict> object is stringified, it B<joins> all its values with the given separator and returns the result.

=back

=head1 EXPORTABLE FUNCTIONS

=head2 $dict = joind($separator, @content)

Alias for C<< Gnuplot::Builder::JoinDict->new(separator => $separator, content => \@content) >>.
Exported only by request.

=head1 CLASS METHODS

=head2 $dict = Gnuplot::Builder::JoinDict->new(%args)

The constructor.

Fields in C<%args> are:

=over

=item C<separator> => STR (optional, default: "")

The separator string that is used when joining.

=item C<content> => ARRAY_REF (optional, default: [])

The content of the C<$dict>.
The array-ref must contain key-value pairs. Keys must not be C<undef>.

=item C<filter> => CODE_REF (optional)

If set, this code-ref is called when the C<$dict> is stringified (i.e. C<< $dict->to_string >> is called).
The code-ref is supposed to modify the values in C<$dict> to produce the final result of stringification.

    @modified_values = $filter->($dict)

where C<$dict> is the L<Gnuplot::Builder::JoinDict> object.
The filter must return a list C<@modified_values>.

For example,

    my $dict = Gnuplot::Builder::JoinDict->new(
        separator => " & ", content => [x => 10, y => 20],
        filter => sub {
            my ($dict) = @_;
            my @keys = $dict->get_all_keys();
            my @values = $dict->get_all_values();
            return map { "$keys[$_]=$values[$_]" } 0 .. $#keys;
        }
    );
    "$dict"; ## => x=10 & y=20

The filter is inherited by L<Gnuplot::Builder::JoinDict> objects derived from the original one.

=item C<validator> => CODE_REF (optional)

If set, this code-ref is called when some key-value pairs are set or deleted to a L<Gnuplot::Builder::JoinDict> object.
The code-ref is supposed to check the content and throw an exception when something is wrong.

    $validator->($dict)

where C<$dict> is the L<Gnuplot::Builder::JoinDict> object.

The validator is called when C<new()>, C<delete()>, C<set()> and C<set_all()> methods are called.

The validator is inherited by L<Gnuplot::Builder::JoinDict> objects derived from the original one.

=back

=head1 OBJECT METHODS

=head2 $str = $dict->to_string()

Join C<$dict>'s values with the separator and return the result.

If some values are C<undef>, those values are ignored.

=head2 $value = $dict->get($key)

Return the C<$value> for the C<$key>.

If C<$dict> doesn't have C<$key>, it returns C<undef>.

=head2 @keys = $dict->get_all_keys()

Return all keys from C<$dict>.

=head2 @values = $dict->get_all_values()

Return all values from C<$dict>.

=head2 $new_dict = $dict->set($key => $value, ...)

Add new key-value pairs to C<$dict> and return the result.
You can specify more than one key-value pairs.

If C<$dict> already has C<$key>, its value is replaced in C<$new_dict>.
Otherwise, a new pair of C<$key> and C<$value> is added.

=head2 $new_dict = $dict->set_all($value)

Set all values to C<$value> and return the result.

=head2 $new_dict = $dict->delete($key, ...)

Delete the given keys from C<$dict> and return the result.
You can specify more than one C<$key>s.

If C<$dict> doesn't have C<$key>, it's just ignored.

=head2 $new_dict = $dict->clone()

Create and return a clone of C<$dict>.

=head2 $separator = $dict->separator()

Get the separator.

=head1 OVERLOAD

When you evaluate a C<$dict> as a string, it executes C<< $dict->to_string() >>. That is,

    "$dict" eq $dict->to_string;

=head1 Data::Focus COMPATIBLITY

L<Gnuplot::Builder::JoinDict> implements C<Lens()> method, so you can use L<Data::Focus> to access its attributes.

The C<Lens()> method creates a L<Data::Focus::Lens> object for accessing the content via C<get()> and C<set()> methods.

    use Data::Focus qw(focus);
    
    my $scalar = focus($dict)->get("x");
    ## same as: my $scalar = $dict->get("x");
    
    my $new_dict = focus($dict)->set(x => '($1 * 1000)');
    ## same as: my $new_dict = $dict->set(x => '($1 * 1000)');

=head1 AUTHOR

Toshio Ito, C<< toshioito at cpan.org >>

=cut
