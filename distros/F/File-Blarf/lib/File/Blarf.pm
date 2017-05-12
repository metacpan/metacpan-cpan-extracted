package File::Blarf;
{
  $File::Blarf::VERSION = '0.12';
}
# ABSTRACT: Simple reading and writing of files

use warnings;
use strict;
use 5.008;

use Fcntl qw( :flock );


sub slurp {
    my $file = shift;
    my $opts = shift || {};

    if ( -e $file && open( my $FH, '<', $file ) ) {
        flock( $FH, LOCK_SH ) if $opts->{Flock};
        my @lines = <$FH>;
        flock( $FH, LOCK_UN ) if $opts->{Flock};
        # DGR: we just read it, what could possibly go wrong?
        ## no critic (RequireCheckedClose)
        close($FH);
        ## use critic
        if (wantarray) {
            if ( $opts->{Chomp} ) {
                chomp(@lines);
            }
            return @lines;
        }
        else {
            my $out = join q{}, @lines;
            if ( $opts->{Chomp} ) {
                chomp($out);
            }
            return $out;
        }
    }
    else {
        return;
    }
}


sub blarf {
    my $file = shift;
    my $str  = shift;
    my $opts = shift || {};

    my $mode = '>';
    if ( $opts->{Append} ) {
        $mode = '>>';
    }
    # DGR: due to flock and newlines we can't be anymore brief
    ## no critic (RequireBriefOpen)
    if ( open( my $FH, $mode, $file ) ) {
        flock( $FH, LOCK_EX ) if $opts->{Flock};
        if(!print $FH $str) {
            return;
        }
        if ( $opts->{'Newline'} ) {
            if(!print $FH "\n") {
                return;
            }
        }
        flock( $FH, LOCK_UN ) if $opts->{Flock};
        if(close($FH)) {
            return 1;
        }
    }
    ## use critic

    return;
}

sub cat {
    my $source_file = shift;
    my $dest_file   = shift;
    my $opts        = shift || {};

    my $mode = '>';
    if ( $opts->{Append} ) {
        $mode = '>>';
    }
    # DGR: the files could be huge, so we MUST no read them into main memory
    ## no critic (RequireBriefOpen)
    if ( open( my $IN, '<', $source_file ) ) {
        flock( $IN, LOCK_SH ) if $opts->{Flock};
        my $status = 0;
        if ( open( my $OUT, $mode, $dest_file ) ) {
            flock( $OUT, LOCK_EX ) if $opts->{Flock};
            while ( my $line = <$IN> ) {
                if(!print $OUT $line) {
                    return;
                }
            }
            flock( $OUT, LOCK_UN ) if $opts->{Flock};
            if(close($OUT)) {
                $status = 1;
            }
        }
        flock( $IN, LOCK_UN ) if $opts->{Flock};
        # DGR: we were just reading ...
        ## no critic (RequireCheckedClose)
        close($IN);
        ## use critic
        if ($status) {
            return $status;
        }
    }
    ## use critic
    # something went wrong ...
    return;
}


1; # End of File::Blarf

__END__

=pod

=head1 NAME

File::Blarf - Simple reading and writing of files

=head1 VERSION

version 0.12

=head1 SYNOPSIS

    use File::Blarf;

    my $foo = File::Blarf::slurp('/etc/passwd');

=head1 NAME

File::Blarf - Simple reading and writing of files.

=head1 SUBROUTINES/METHODS

=head2 slurp

Read a whole file into a string.

=head2 blarf

Write a string into a file.

=head2 cat

Append on file to another.

=head1 AUTHOR

Dominik Schulz, C<< <dominik.schulz at gauner.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-file-blarf at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Blarf>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::Blarf

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Blarf>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-Blarf>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-Blarf>

=item * Search CPAN

L<http://search.cpan.org/dist/File-Blarf/>

=back

=head1 SEE ALSO

=over 4

=item * File::Slurp

L<File::Slurp> provides a more sophisticated implementation of much of the same functiality

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Dominik Schulz

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
