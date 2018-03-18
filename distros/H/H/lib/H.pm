package H;
use strict;
use warnings;

our $VERSION = '0.001';

require HS;
require HD;
require HF;
require HL;
require HA;
require HH;

{
    no warnings 'once';
    *AUTOLOAD     = *HS::AUTOLOAD;
    *h::AUTOLOAD  = *HS::AUTOLOAD;
    *hs::AUTOLOAD = *HS::AUTOLOAD;
    *hd::AUTOLOAD = *HD::AUTOLOAD;
    *hf::AUTOLOAD = *HF::AUTOLOAD;
    *hl::AUTOLOAD = *HL::AUTOLOAD;
    *ha::AUTOLOAD = *HA::AUTOLOAD;
    *hh::AUTOLOAD = *HH::AUTOLOAD;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

H - Method wrappers for hash construction.

=head1 DESCRIPTION

It is nice to make hashes like this:

    {
        foo => $thing1->foo(),
        bar => $thing2->bar(),
    }

Note that our hash keys and method names match, this is a common situation.

There are many pitfalls, C<< $thing1->foo() >> may return a scalar, an empty list, an
uneven list, or may return one thing in scalar context, and another in list
context. Sometimes you do not want the key to exist if C<< $thing1->foo >>
returns an empty list.

To compensate you often must use one of these:

    { foo => scalar($bar->foo) }
    { foo => $bar->foo // undef }

    my $foo = $bar->foo;
    { defined($foo) ? (foo => $foo) : () }

    { foo => [$bar->foo] }
    { foo => {$bar->foo} }

This module makes it trivial to concisely make your expections, desires, and
reality all align.

=head1 SYNOPSIS

    use H;

    my %hash = (
        $thing->HS::foo(), # foo => scalar($thing->foo || undef),
        $thing->HD::foo(), # defined(scalar $thing->foo) ? (foo => $thing->foo) : (),
        $thing->HF::foo(), # @foo = $thing->foo; @foo ? (foo => $foo[0]) : (),
        $thing->HL::foo(), # @foo = $thing->foo; @foo ? (foo => $foo[-1]) : (),
        $thing->HA::foo(), # foo => [$thing->foo],
        $thing->HH::foo(), # foo => {$thing->foo},
    );

=head1 TOOLS

This module defines several namespaces, you can wrap any method in a namespace
using the C<< $thing->NS::method() >> calling convention. This is regular perl
syntax! The method will be run via the specified namespace.

All these methods will return a list of the form C<< (method_name => $value) >>
(or an empty list depending on the wrapper).

The method is only ever called once per usage, this is safe to use with methods
that increment a counter or change state and should only be called once.

=head2 $t->HS::method()

This wrapper will always call the method in scalar context, and always returns
both the method name and the return value, the return value may be C<undef>.

    my $value = $t->$method_name();
    return ($method_name => $value);

=head2 $t->HD::method()

This is similar to HF, however if the return value is undefined this will
return an empty list.

    my $value = scalar $t->$method_name();
    return () unless defined $value;
    return ($method_name => $value);

=head2 $t->HF::method()

This will set the value to the first item returned from the method called in
list context. If the list is empty then this wrapper returns an empty list.

    my @list = $t->$method_name();
    return () unless @list;
    return ($method_name => $list[0]);

=head2 $t->HL::method()

This is nearly identical to the HF wrapper above, except it uses the last value
from the list returned.

    my @list = $t->$method_name();
    return () unless @list;
    return ($method_name => $list[-1]);

=head2 $t->HA::method()

In this wrapper the method is called in list context, the list is used as the
return value in an arrayref. This wrapper always returns the method name and an
arrayref, the arrayref may be empty.

    return ($method_name => [$t->$method_name()]);

This is only a small savings in typing, and does not provide much in the way of
edge-case protection.

=head2 $t->HH::method()

This is the same as the HA wrapper except the value is a hashref instead of an
arrayref. Much like the HA wrapper this does not add much protection or savings
in typing.

Unlike the HA wrapper this will be significantly slower (run-time) than simply
using C<< foo => {$t->foo}, >> as a string eval is used to make sure warnings
show the correct file and line number in cases where the list is uneven, has an
undefined key, etc.

=head1 SOURCE

The source code repository for H can be found at
F<http://github.com/exodist/H/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2018 Chad Granum E<lt>exodist@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
