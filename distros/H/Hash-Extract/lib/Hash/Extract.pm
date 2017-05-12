## ----------------------------------------------------------------------------
#  Hash::Extract
# -----------------------------------------------------------------------------
# Mastering programmed by YAMASHINA Hio
#
# Copyright 2006 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id: /perl/Hash-Extract/lib/Hash/Extract.pm 580 2007-12-19T06:29:03.536065Z hio  $
# -----------------------------------------------------------------------------
package Hash::Extract;
use strict;
use warnings;
use PadWalker qw(var_name);
use B;
use base 'Exporter';

our @EXPORT_OK = qw(hash_extract);
our %EXPORT_TAGS = (
	all => \@EXPORT_OK,
);

our $VERSION = '0.02';

1;

# -----------------------------------------------------------------------------
# hash_extract(\%hash, my $var);
# -----------------------------------------------------------------------------
sub hash_extract
{
	my $hash = shift;
	my $i=0;
	foreach my $var (@_)
	{
		my $name = var_name(1, \$var);
		$name or die "could not detect name of variable";
		{
		local(%+);
		$name =~ s/^\$//;# or die "argument is not scalar variable: $name";
		}
		exists($hash->{$name}) or die "no such hash element: $name";
		$var = $hash->{$name}
	}
}

# -----------------------------------------------------------------------------
# End of Module.
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
__END__

=encoding utf8

=for stopwords
  YAMASHINA
	Hio
	ACKNOWLEDGEMENTS
	AnnoCPAN
	CPAN
	RT

=head1 NAME

Hash::Extract - extract hash values onto lexical variables.


=head1 VERSION

Version 0.02


=head1 SYNOPSIS

 use Hash::Extract qw(hash_extract);
 
 %hash = ( red => 'apple', blue => 'sky', );
 hash_extract( \%hash, my $blue );
 print $blue;  # ==> 'sky'

=head1 EXPORT

This module can export one function.


=head1 FUNCTIONS

=head2 hash_extract(\%hash, my $xxx, my $yyy);

extract value which is contained in hash into specified variable.
hash key of that is same as variable name.


currently, you can use lexical variables declared in same scope
as you call this function.


 hash_extract( $hashref, my $xxx);
 # ==> my $xxx = $hashref->{xxx};

 hash_extract( $hashref, our $xxx);
 # ==> die: could not detect name of variable.

note: in this version, hash_extract do not check value of
arguments. but options may be added in future release.
it is better that variables are set undefined.


=head1 AUTHOR

YAMASHINA Hio, C<< <hio at cpan.org> >>


=head1 BUGS

Please report any bugs or feature requests to
C<bug-hash-extract at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hash-Extract>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.


    perldoc Hash::Extract

You can also look for information at:


=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Hash-Extract>


=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Hash-Extract>


=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Hash-Extract>


=item * Search CPAN

L<http://search.cpan.org/dist/Hash-Extract>


=back

=head1 SEE ALSO

L<PadWalker>


=head1 COPYRIGHT & LICENSE

Copyright 2006-2007 YAMASHINA Hio, all rights reserved.


This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


