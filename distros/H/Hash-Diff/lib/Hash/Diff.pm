package Hash::Diff;

use strict;
use warnings;
use Carp;
use Hash::Merge;

use base 'Exporter';
use vars qw($VERSION @ISA @EXPORT_OK %EXPORT_TAGS);

$VERSION     = 0.009;
@EXPORT_OK   = qw( diff left_diff );

sub left_diff {
    my ($h1, $h2) = @_;
    my $rh = {}; # return_hash
    
    foreach my $k (keys %{$h1}) {
        if (not defined $h1->{$k} and exists $h2->{$k} and not defined $h2->{$k}) {
            # Empty
        }
        elsif (ref $h1->{$k} eq 'HASH') {
            if (ref $h2->{$k} eq 'HASH') {
                my $d = left_diff($h1->{$k}, $h2->{$k});
                $rh->{$k} = $d if (%$d);
            }
            else {
                $rh->{$k} = $h1->{$k}                
            }
        }
        elsif ((!defined $h1->{$k})||(!defined $h2->{$k})||($h1->{$k} ne $h2->{$k})) {
            $rh->{$k} = $h1->{$k}
        }
    }
    
    return $rh;

}

sub diff {
    my ($h1, $h2) = @_;

    return Hash::Merge::merge(left_diff($h1,$h2),left_diff($h2,$h1));
}


1;

__END__

=head1 NAME

Hash::Diff - Return difference between two hashes as a hash

=head1 SYNOPSIS

    use Hash::Diff qw( diff );
    my %a = ( 
		'foo'    => 1,
	    'bar'    => { a => 1, b => 1 },
	);
    my %b = ( 
		'foo'     => 2, 
		'bar'    => { a => 1 },
	);

    my %c = %{ diff( \%a, \%b ) };
    
    # %c = %{ foo => 1, bar => { b => 1} }

=head1 DESCRIPTION

Hash::Diff returns the difference between two hashes as a hash.

=over 

=item diff ( <hashref>, <hashref> )

Diffs two hashes.  Returns a reference to the new hash.

=item left_diff ( <hashref>, <hashref> )

Returns the values in the left hash that is not, or different from the right hash.

=back

=head1 CAVEATS

This will not handle self-referencing/recursion within hashes well.  
This will only handle HASH and SCALAR. 

Plans for a future version include incorporate deep recursion protection.
And support for ARRAY.

=head1 BUGS

Sure!
Report here: http://rt.cpan.org/NoAuth/Bugs.html?Dist=Hash::Diff

=head1 AUTHOR

Bjorn-Olav Strand E<lt>bo@startsiden.noE<gt>

=head1 COPYRIGHT

Copyright (c) 2010 ABC Startsiden AS. All rights reserved.

This library is free software.  You can redistribute it and/or modify it 
under the same terms as Perl itself.

=cut
