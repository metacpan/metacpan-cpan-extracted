package Language::Kemuri;
use strict;
use warnings;
use Carp;
our $VERSION = '0.07';
use Exporter;
our @EXPORT_OK = qw/kemuri/;
use 5.010001;

sub kemuri {
    my $code = shift;

    my @stack;
    my $buf = "";
    
    for my $c ( split //, $code ) {
        given ($c) {
            when (q{`}) {
                push @stack, unpack("C*", reverse "Hello, world!");
            }
            when (q{"}) {
                my $x = pop @stack;
                push @stack, $x;
                push @stack, $x;
            }
            when (q{'}) {
                my $x = pop @stack;
                my $y = pop @stack;
                my $z = pop @stack;
                push @stack, $x;
                push @stack, $z;
                push @stack, $y;
            }
            when ('^') {
                my $x = pop @stack;
                my $y = pop @stack;
                push @stack, $x ^ $y;
            }
            when ('~') {
                my $x = pop @stack;
                push @stack, -($x+1);
            }
            when ('|') {
                $buf .= reverse map { chr($_ % 256) } @stack;
            }
            default {
                croak "unknown kemuri token $c in $code";
            }
        }
    }

    return $buf;
}

1;
__END__

=head1 NAME

Language::Kemuri - Kemuri Interpreter.

=head1 SYNOPSIS

    use Language::Kemuri;
    kemuri('`|'); # => Hello, world!

=head1 DESCRIPTION

An interpreter for Kemuri language.

=head1 METHODS

=head2 kemuri

run the kemuri, and return the output value.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Tokuhiro Matsuno  C<< <tokuhiro __at__ mobilefactory.jp> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007, Tokuhiro Matsuno C<< <tokuhiro __at__ mobilefactory.jp> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

