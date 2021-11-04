package FindApp::Object::Behavior::Overloading;

use charnames qw(:full);

use FindApp::Utils ":overload";

use overload reverse (
    as_string      =>  qw( "" ),
    as_number      =>  qw( 0+ ),
    op_equals      =>  qw( == ),
    op_notequals   =>  qw( != ),
    op_eq          =>  qw( eq ),
    op_ne          =>  qw( ne ),
);

sub op_eq {
    my($a, $b, $flipped) = @_;
    my($a_str, $b_str);

# bless({ # FindApp::Object=HASH(0x7f9a630cd6f0)
# bless([], "FindApp::Object::State::Group::State::Dirs"); # FindApp::Object::State::Group::State::Dirs=ARRAY(0x7f8f8480e8c0)

    # have to trim the uniquifying address that as_string adds
    for (($a_str, $b_str) = map {"$_"} $a, $b) {
        s{
            \A .* \K                            # first line, keep it
            \N{SPACE} \N{NUMBER SIGN} \N{SPACE} # then
            \w+ (?: ::\w+ )* = \p{upper}+ \( 0x \p{ahex}+ \) (?= \n)
        }[]x ;
    }
    return $a_str eq $b_str;
}

sub op_ne { ! &op_eq }

1;

__END__

=head1 NAME

FindApp::Object::Behavior::Overloading - provide an object with simply overloads

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 Overloads

=over

=item as_string

The L<Data::Dump> output.

=item as_number

The object address.

=item op_equals

For the C<==> operator, compares addresses.

=item op_notequals

For the C<!=> operator, compares addresses.

=item op_eq

For the C<eq> operator, compares stringifications.

=item op_ne

For the C<ne> operator, compares stringifications.

=back

=head2 Methods

=over

=item op_eq

=item op_ne

=back

=head1 SEE ALSO

=head1 AUTHOR

=head1 LICENCE AND COPYRIGHT
