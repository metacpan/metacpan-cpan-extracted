package List::Extract;
use 5.006001;

$VERSION = 0.03;

use Exporter;
@ISA = Exporter::;
@EXPORT_OK = qw/ extract /;
$EXPORT_TAGS{ALL} = \@EXPORT_OK;

use strict;

sub extract (&\@) {
    my ($code, $array) = @_;

    my (@keep, @extracted);
    for my $orig (@$array) {
        local $_ = $orig;
        if ($code->()) {
            push @extracted, $_;
        }
        else {
            push @keep, $orig;
        }
    }
    @$array = @keep;

    return @extracted;
}

1;

__END__

=head1 NAME

List::Extract - grep and splice combined


=head1 SYNOPSIS

    use List::Extract 'extract';

    my @keywords = qw/
         foo
        !bar
         baz
    /;

    my @exclude = extract { s/^!// } @keywords;

    print "Keywords: @keywords\n";
    print "Exclude: @exclude\n";

    __END__
    Keywords: foo baz
    Exclude: bar


=head1 DESCRIPTION

C<List::Extract> exports a C<grep>-like routine called C<extract> that both returns and extracts the elements that tests true. It's C<grep> and C<splice> combined.


=head1 EXPORTED FUNCTIONS

Nothing is exported by default. The :ALL tag exports everything that can be exported.

=over

=item $count = extract BLOCK ARRAY

=item @extracted = extract BLOCK ARRAY

Removes the elements from array for which C<BLOCK> returns true. In list context the elements are returned in original order. In scalar context the number of removed elements is returned.

In C<BLOCK> the elements in C<ARRAY> will be accessible through C<$_>. Modifications to C<$_> will be preserved in the returned list, but discarded for elements left in the array.

=back


=head1 AUTHOR

Johan Lodin <lodin@cpan.org>


=head1 COPYRIGHT

Copyright 2007-2008 Johan Lodin. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.


=head1 SEE ALSO

L<List::Part>

=cut
