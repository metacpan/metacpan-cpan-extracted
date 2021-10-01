# -*- mode: perl; -*-

package Math::BigInt::Named;

use 5.006001;
use strict;
use warnings;

use Carp qw( carp croak );

use Math::BigInt 1.97;
our @ISA = qw(Math::BigInt);

our $VERSION = '0.08';

# Globals.

our ($accuracy, $precision, $round_mode, $div_scale);
$accuracy   = undef;
$precision  = undef;
$round_mode = 'even';
$div_scale  = 40;

# Not all of them exist yet.
my $LANGUAGE = {
  en => 'english',
  de => 'german',
  sp => 'spanish',
  fr => 'french',
  ro => 'romana',
  it => 'italian',
  no => 'norwegian',
  };

# Index of languages that have been loaded.

my $LOADED = { };

sub name {
    # output the name of the number
    my $x = shift;

    # make Math::BigInt::Named -> name(123) work
    $x = $x -> new(shift) unless ref($x);

    return 'NaN' if $x -> is_nan();

    my @args = ();
    if (@_) {
        if (ref($_[0]) eq 'HASH') {
            carp "When the options are given as a hash ref, additional",
              " arguments are ignored" if @_ > 1;
            @args = %{ $_[0] };
        } else {
            @args = @_;
        }
    }

    my $lang;
    while (@args) {
        my $param = shift @args;
        croak "Parameter name can not be undefined" unless defined $param;
        croak "Parameter name can not be an empty string" unless length $param;

        if ($param =~ /^lang(uage)?$/) {
            $lang = shift @args;
            croak "Language can not be undefined" unless defined $lang;
            croak "Language can not be an empty string" unless length $lang;
            next;
        }

        croak "Invalid parameter '$param'";
    }

    $lang = 'english' unless defined $lang;
    $lang = $LANGUAGE -> {$lang} if exists $LANGUAGE -> {$lang}; # en => english

    $lang = 'Math::BigInt::Named::' . ucfirst($lang);

    if (!defined $LOADED -> {$lang}) {
        my $file = $lang;
        $file =~ s|::|/|g;
        $file .= ".pm";
        eval { require $file; };
        croak $@ if $@;
        $LOADED -> {$lang} = 1;
    }

    my $y = $lang -> new($x);
    $y -> name();
}

sub from_name {
    # Create a Math::BigInt::Named from a name string. Not implemented.

    my $x = Math::BigInt -> bnan();
}

1;

__END__

=pod

=head1 NAME

Math::BigInt::Named - Math::BigInt objects that know their name in some languages

=head1 SYNOPSIS

    use Math::BigInt::Named;

    $x = Math::BigInt::Named->new("123");

    print $x->name(),"\n";                      # default is english
    print $x->name( language => 'de' ),"\n";    # but German is possible
    print $x->name( language => 'German' ),"\n";        # like this
    print $x->name( { language => 'en' } ),"\n";        # this works, too

    print Math::BigInt::Named->from_name("einhundert dreiundzwanzig"),"\n";

=head1 DESCRIPTION

This is a subclass of Math::BigInt and adds support for named numbers.

=head1 METHODS

=head2 name()

    print Math::BigInt::Named->name( 123 );

Convert a Math::BigInt to a name.

=head2 from_name()

    my $bigint = Math::BigInt::Named->from_name('hundertzwanzig');

Create a Math::BigInt::Named from a name string. B<Not yet implemented!>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-math-bigint-named at rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/Ticket/Create.html?Queue=Math-BigInt-Named>
(requires login).
We will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::BigInt::Named

You can also look for information at:

=over 4

=item * GitHub

L<https://github.com/pjacklam/p5-Math-BigInt-Named>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/Dist/Display.html?Name=Math-BigInt-Named>

=item * MetaCPAN

L<https://metacpan.org/release/Math-BigInt-Named>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Math-BigInt-Named>

=item * CPAN Ratings

L<https://cpanratings.perl.org/dist/Math-BigInt-Named>

=back

=head1 LICENSE

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Math::BigInt> and L<Math::BigFloat>.

=head1 AUTHORS

=over 4

=item *

(C) by Tels http://bloodgate.com in late 2001, early 2002, 2007.

=item *

Maintainted by Peter John Acklam E<lt>pjacklam@gmail.comE<gt>, 2016-.

=item *

Based on work by Chris London Noll.

=back

=cut
