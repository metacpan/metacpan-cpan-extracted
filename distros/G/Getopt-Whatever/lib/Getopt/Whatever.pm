package Getopt::Whatever;

use warnings;
use strict;

our $VERSION = '0.01';

# The import method is pretty basic, it just chops up the @ARGV array and parses
# out anything that looks like an argument and makes it a key-value pair in the
# %ARGV hash.  The basic flow is:
#   1) if there aren't double-dashes at the start of an argument, consider the
#      argument a bareword and go to the next argument
#   2) split the key/value pair on the first equal sign
#   3) if there isn't a key, we were passed only double-dashes so stop processing
#   4) Add the flag or key/value pair to the %ARGV hash

sub import {
    my %flags;
    my %values;
    my @barewords;
    while ( my $arg = shift @ARGV ) {

        if ( substr( $arg, 0, 2 ) ne q{--} ) {
            push @barewords, $arg;
            next;
        }

        my ( $key, $value ) = split /=/xms, substr( $arg, 2 ), 2;

        last unless ( defined $key ) or ( defined $value );

        if ( defined $value ) {
            if ( exists $values{$key} ) {
                if ( not ref $values{$key} ) {
                    $values{$key} = [ $values{$key} ];
                }
                push @{ $values{$key} }, $value;
            }
            else {
                $values{$key} = $value;
            }
        }
        else {
            $flags{$key} = 1;
        }
    }

    %ARGV = ( %flags, %values );
    unshift @ARGV, @barewords;

    return;
}

1;

__END__

=pod

=head1 NAME

Getopt::Whatever - Collects whatever options you pass it!

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Getopt::Whatever;
    
    for my $key (keys %ARGV) {
        if(ref $ARGV{$key}) {
            print $key, ' -> ', join(', ', @{$ARGV{$key}}), "\n";
        }
        else {
            print $key, ' -> ', $ARGV{$key}, "\n";
        }
    }
    
    print "@ARGV\n";

=head1 DESCRIPTION

Getopt::Whatever parses whatever command line options that it can find in
C<@ARGV> and places them into C<%ARGV>.  The parsing only supports long
options (double-dashed), but might eventually also support short-form
options.  After parsing, anything that was not considered an option is
left in C<@ARGV>.

The best way to describe what this module does is probably just to give
an illustration, so here goes... suppose you use C<Getopt::Whatever>
in your program, C<my_program>.  Here are some combinations of what
you'll get.

As just a basic example:

  my_program --verbose --data_file=/tmp/data.out go now -bob

Produces:

    @ARGV = ('go', 'now', '-bob');
    
    %ARGV = (
        verbose => 1,
        data_file => '/tmp/data.out',
    );

What about double-keys:

  my_program --data_file=/tmp/data.out --data_file=/tmp/more_data.out

Produces:

    @ARGV = ();
    
    %ARGV = (
        data_file => [ '/tmp/data.out', '/tmp/more_data.out' ],
    );

The results are hopefully what most users would expect.

You might be asking why you would need this module.  We'll, I've found
it to be useful for creating programs that drive templates.  The programs
can accept a template file and then whatever arguments you give it
to fill in the template.  There are probably other uses, but this is
enough for me.

=over 4

=item * Options with no values are considered flags and given a value of one.

=item * Options with arguments are placed as a key-value pair into C<%ARGV>.

=item * Duplicate key-value options cause the hash value to become an array of values.

=item * Key-value pairs take precidence over flags.

=item * Processing stops at a lone '--'.

=item * Everything not considered an option is left on C<@ARGV>.

=back

You can find a fairly detailed list of what you should expect from edge
cases in C<t/argv_tests.t>.

=head1 SUBROUTINES/METHODS

There aren't any subroutines exported because everything that this module
does happens on import.  About the only thing that you'll notice is that
C<%ARGV> will be populated if you were passed any arguments.

=head1 AUTHOR

Josh McAdams, C<< <joshua.mcadams at gmail.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-getopt-whatever at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Getopt-Whatever>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 INCOMPATIBILITIES

It is not recommended to use this alongside any other of the 
C<Getopt::> modules because you'll have multiple modules dinking
around with C<@ARGV>.

=head1 DEPENDENCIES

None that I know of.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Getopt::Whatever

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Getopt-Whatever>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Getopt-Whatever>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Getopt-Whatever>

=item * Search CPAN

L<http://search.cpan.org/dist/Getopt-Whatever>

=back

=head1 SEE ALSO

=over 4

=item L<Getopt::Casual> - the inspiration for C<Getopt::Whatever> because it seemed like a good idea, but didn't do exactly what I wanted.

=item L<Getopt::Long> - One of the standard C<Getopt::> modules.

=item L<Getopt::Std> - Another of the standard C<Getopt::> modules.

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2007 Josh McAdams, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

