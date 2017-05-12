package Getopt::TypeConstraint::Mouse;
use 5.008005;
use strict;
use warnings;
use Mouse;
with qw(MouseX::Getopt::GLD);

our $VERSION = "0.05";

sub get_options {
    my ($class, @args) = @_;
    while (my ($key, $val) = splice @args, 0, 2) {
        for my $alias (qw(desc description doc )) {
            if (exists $val->{$alias}) {
                $val->{documentation} = delete $val->{$alias};
            }
        }
        has $key => ( is => 'ro', %$val);
    }
    $class->new_with_options()
}

1;
__END__

=encoding utf-8

=head1 NAME

Getopt::TypeConstraint::Mouse - A command line options processor uses Mouse's type constraints

=head1 SYNOPSIS

in your script

    #!perl
    use Getopt::TypeConstraint::Mouse;

    my $options = Getopt::TypeConstraint::Mouse->get_options(
        foo => +{
            isa           => 'Str',
            required      => 1,
            documentation => 'Blah Blah Blah ...',
        },
        bar => +{
            isa           => 'Str',
            default       => 'Bar',
            documentation => 'Blah Blah Blah ...',
        },
    );

    print $options->{foo}, "\n";
    print $options->{bar}, "\n";

use it

    $ perl ./script.pl --for=Foo --bar=Bar
    Foo
    Bar

    $ perl ./script.pl
    Mandatory parameter 'foo' missing in call to (eval)

    usage: script.pl [-?] [long options...]
    	-? --usage --help  Prints this usage information.
    	--foo              Blah Blah Blah ...
    	--bar              Blah Blah Blah ..

=head1 QUESTIONS

=head2 What types are supported?

See L<MouseX::Getopt#Supported-Type-TypeConstraints> for details.

=head2 What options are supported?

See L<MouseX::Getopt#METHODS> for details.

=head1 SEE ALSO

=over

=item L<MouseX::Getopt>

=item L<Smart::Options>

=item L<Docopt>

=item L<Getopt::Long::Descriptive>

=item L<Getopt::Compact::WithCmd>

=back

=head1 LICENSE

Copyright (C) Hiroki Honda.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Hiroki Honda E<lt>cside.story@gmail.comE<gt>

=cut

