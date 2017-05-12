package HTML::Entities::Recursive;
use strict;
use warnings;
our $VERSION = '0.01';

use Sub::Recursive;
use HTML::Entities ();

my $fac = recursive {
    my $this = shift;
    my $how  = pop;
    my @rest = @_;

    # See also http://www.stonehenge.com/merlyn/UnixReview/col30.html
    if (not ref $this) {
        HTML::Entities::Recursive->_do($this, @rest, $how);

    } elsif (ref $this eq "ARRAY") {
        [map $REC->($_, @rest, $how), @$this];

    } elsif (ref $this eq "HASH") {
        +{map { $_ => $REC->($this->{$_}, @rest, $how) } keys %$this};

    } elsif (ref $this eq 'SCALAR') {
        \($REC->($$this, @rest, $how));

    } else {
        ($this, @rest);
    }
};

sub new {
    my $class = shift;
    return bless {}, $class;
}

sub _do {
    my $self = shift;
    my $text = shift;
    my $how  = pop;

    if ($how eq 'decode') {
        defined $text ? (HTML::Entities::decode($text, @_)) : ($text, @_);

    } elsif ($how eq 'encode') {
        defined $text ? (HTML::Entities::encode($text, @_)) : ($text, @_);

    } elsif ($how eq 'encode_numeric') {
        defined $text ? (HTML::Entities::encode_numeric($text, @_)) : ($text, @_);

    } else {
        Carp::croak("$how is unknown function");
    }
}

sub decode {
    shift; $fac->(@_, 'decode');
}

sub encode {
    shift; $fac->(@_, 'encode');
}

sub encode_numeric {
    shift; $fac->(@_, 'encode_numeric');
}

1;
__END__

=head1 NAME

HTML::Entities::Recursive - Encode / decode strings of complex data structure with HTML entities recursively

=head1 SYNOPSIS

    use HTML::Entities::Recursive;
    my $recursive = HTML::Entities::Recursive->new;

    my $foo = {
        text => '<div></div>',
    };

    my $bar = $recursive->encode_numeric($foo);
    print $bar->{text}; # prints '&lt;div&gt;&lt;/div&gt;'


=head1 DESCRIPTION

HTML::Entities::Recursive provides API to encode / decode strings of complex data structure with HTML entities recursively.

To avoid conflicting with HTML::Entities' functions, HTML::Entities::Recursive is written in OO-style.
There is no function to be exported.

To proxy content provider's API, we sometimes want to bulk decode and encode complex data structure that contains escaped strings with untrustworthy way. (yes, response from Twitter API :)

HTML::Entities::Recursive helps you to make output safe with ease.

=head1 METHODS

=over 4

=item new

C<new()> takes no argument.

=item encode( $structure )

=item encode( $structure, $unsafe_chars )

=item encode_numeric( $structure )

=item encode_numeric( $structure, $unsafe_chars )

=item decode( $structure )

L<HTML::Entities> refers to C<$unsafe_chars>.

Methods correspond to HTML::Entities' functions but the first argument can be hashref, arrayref or scalarref.

Internally, all corresponding functions are called in array context.
So you cannot use those methods in void context.

That is,

=over 4

=item * Use methods in scalar or array context.

=item * Methods do not modify original structure.

=back

=back

=head1 AUTHOR

punytan E<lt>punytan@gmail.comE<gt>

=head1 SEE ALSO

L<HTML::Entities>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
