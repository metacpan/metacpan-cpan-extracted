package MarpaX::Tester;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Marpa::R2;
use Data::Dumper;

=head1 NAME

MarpaX::Tester - Given a Marpa grammar and one or more test cases, generates output

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

When working with parsers, I find test-driven development to be the quickest and most
effective way of getting where I want to go. (Also when working with anything else, but
we're talking about parsers right now.) This module does that.

    use MarpaX::Tester;

    my $r = MarpaX::Tester->new($grammar);
    my $results = $r->test($text);
    $results = $r->test([$text1, $text2]);
    
There's also a command-line utility to produce conveniently formatted versions for
posting and gisting.

The results are a hashref; "grammar" is the text of the grammar in question, "status" is
binary indicating OK or not OK at the grammar parsing level (i.e. has Marpa accepted the grammar
itself), "error" is the error raised by Marpa, if the status is false. If the error has a line and
column specified (not all errors do), then the text of the grammar will have an extra line inserted
pointing at the error with a '........^' format.

Either way, "ver" is the Marpa version used to generate this test.

(These are already available immediately after the grammar is defined, of course, and can be
retrieved at that stage with C<<$r->status>> and C<<$r->result>>, but to keep things dead simple,
you can still throw your test cases at an invalid grammar - they just won't be parsed, obviously.)

So if there is a parse error, you get a structure like this:

   {
       grammar => '...',
       status  => 0,
       error   => '...',
   }
   
If the grammar succeeds in compiling, then results are in "results", either a hashref or an array of
hashrefs, like this:

   {
       grammar => '...',
       status  => 1,
       results => {
                     test   => '...',
                     status => 0,
                     error  => '...',
                  },
   }
   
or conversely like this:

   {
       grammar => '...',
       status  => 1,
       results => {
                     test      => '...',
                     status    => 1,
                     parse     => '...',
                     parse_val => ...
                  },
   }
   
And if you pass in a list of tests, you'll get this:

   {
       grammar => '...',
       status  => 1,
       results => [
                    {
                        test   => '...',
                        status => 0,
                        error  => '...',
                    },
                    {
                        test      => '...',
                        status    => 1,
                        parse     => '...',
                        parse_val => ...,
                    }
                  ],
   }

In successful tests, you get both the parse_val (the actual value returned from the parse) and the Data::Dumper
text version in "parse". This makes it easy for the command-line utility to use the Template Toolkit to format
the results.

=head1 METHODS

=head2 new

Given a string, makes a grammar and recognizer and stashes them for later use, or saves the error
after convenient formatting.

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->{grammar} = shift;
    my $g = $self->{grammar};
    $self->{g} = eval { Marpa::R2::Scanless::G->new({source => \$g}); };
    if ($@) {
        $self->{status} = 0;
        $self->{error} = _format_error($@);
        my ($line, $column) = _error_location($self->{error});
        if (defined $line) {
            $self->{grammar} = _decorate_text ($self->{grammar}, $line, $column);
        }
    } else {
        $self->{status} = 1;
    }
    return $self;
}

sub _format_error {
    my $error = shift;
    $error =~ s/Marpa::R2 exception at.*\n//gm;
    $error =~ s/^\*.*\n//gm;
    return $error;
}
sub _error_location {
    my $error = shift;
    if ($error =~ /line (\d+), column (\d+)/) {
        return ($1, $2);
    } else {
        return ();
    }
}
sub _decorate_text {
    my ($text, $line, $column) = @_;
    my $output = '';
    my $current = 1;
    foreach my $tline (split /\n/, $text) {
        $output .= "$tline\n";
        $output .= '.' x ($column - 1) . "^ ERROR!\n" if $current == $line;
        $current++;
    }
    $output;
}

=head2 test

Tests one or more texts and returns the results in the structure described above.

=cut

sub test {
    my $self = shift;
    return $self->result unless $self->{status};  # Don't try if there's no recognizer.

    $self->{result} = 
       {
           grammar => $self->{grammar},
           ver     => $Marpa::R2::VERSION,
           status  => 1,
           result  => $self->_run_test(@_),
       }
}

sub _run_test {
    my $self = shift;
    my $test = shift;
    
    return $self->_one_test ($test) unless ref($test) eq 'ARRAY';
    my @results = ();
    foreach my $individual (@$test) {
        push @results, $self->_one_test($individual);
    }
    \@results;
}

sub _one_test {
    my $self = shift;
    my $string = shift;

    my $r = Marpa::R2::Scanless::R->new({ grammar => $self->{g} });

    eval { $r->read(\$string); };
    if ($@) {
        return {
           test => $string,
           status => 0,
           error => $@,
        };
    } else {
        my $value = $r->value;
        return {
            test => $string,
            status => defined $value ? 1 : 0,
            parse => _format_dump($value),
            parse_val => $value,
        };
    }
}

sub _format_dump { # The Dumper format doesn't appeal to me as diagnostic output.
   my $dump = shift;
   $dump = Dumper($dump);
   $dump =~ s/\$VAR1 = \\//;
   $dump =~ s/^          //gm;
   $dump;
}
    

=head2 status

Returns the BNF parse status of the original grammar (I know, two levels of parsing make it
hard to distinguish - this is the status of the grammar specification itself, not the status of
your test cases).

=cut

sub status { $_[0]->{status} }

=head2 result

Returns the last result from the test object - either the parse error or the last test set.

=cut

sub result {
    my $self = shift;
    return $self->{result} if $self->{result};
    if ($self->{status}) {
        return {
            grammar => $self->{grammar},
            ver     => $Marpa::R2::VERSION,
            status  => 1,
        };
    }
    return {
       grammar => $self->{grammar},
       ver     => $Marpa::R2::VERSION,
       status  => 0,
       error   => $self->{error},
    };
}

=head1 AUTHOR

Michael Roberts, C<< <michael at vivtek.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-marpax-tester at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MarpaX-Tester>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MarpaX::Tester


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MarpaX-Tester>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MarpaX-Tester>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MarpaX-Tester>

=item * Search CPAN

L<http://search.cpan.org/dist/MarpaX-Tester/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Michael Roberts.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of MarpaX::Tester
