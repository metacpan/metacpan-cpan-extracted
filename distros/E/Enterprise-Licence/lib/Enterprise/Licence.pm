package Enterprise::Licence;
use utf8; use strict; use warnings; our $VERSION = '0.03';
use DateTime; use Math::BigInt; use Compress::Huffman;
use Shannon::Entropy qw/entropy/; use Bijection qw/all/;

sub new {
	my ($pkg, $args) = (@_, {});
	my $self = bless {}, $pkg;
	unless ($args->{secret} && entropy($args->{secret}) > 3) {
		die 'no secure secret passed to new';
	}
	$self->{secret} = $args->{secret};
	$self->{increment} = $args->{increment} || 0.1;
	my $ch = $self->huffman([split '', $args->{secret}]);
	$self->{ch} = $ch;
	bijection_set(
		($args->{offset} ? $args->{offset} : ()),
		@{$args->{biject}}
	) if $args->{biject};
	$self;
}

sub bin2dec {
	my $dec = $_[1];
	return Math::BigInt->new("0b$dec");
}

sub dec2bin {
	my $i = Math::BigInt->new($_[1]);
	return substr($i->as_bin(), 2);
}

sub customer_offset {
	my $encode = [split '', $_[1]];
	my $ch = $_[0]->huffman($encode);
	return $ch->encode($encode);
}

sub huffman {
	my ($self, $encode) = @_;
	my $ch = Compress::Huffman->new();
	my $i = $self->{increment};
	my %symbols = map {
		$_ => ( $i += $self->{increment} )
	} @{$encode};
	$ch->symbols(\%symbols, notprob => 1);
	return $ch;
}

sub bi { return scalar biject($_[1]); }
sub in { return scalar inverse($_[1]); }

1;

__END__

=head1 NAME

Enterprise::Licence - Licence or License

=head1 VERSION

Version 0.03

=cut

=head1 SYNOPSIS

	use Enterprise::Licence::Generate;
	use Enterprise::Licence::Validate;

	my $sec = 'ab3yq34s1£f';
	my $generator = Enterprise::Licence::Generate->new({ secret => $sec });

	my $client = 'unique';
	my $licence = $generator->generate($client, { years => 99 });

	my $validator = Enterprise::Licence::Validate->new({ secret => $sec });
	my @valid = $validator->valid($licence, $client);
	# (1) == valid
	# (0, 1) == expired
	# (0, 0) == invalid

=cut

=head1 Description

I used to have software which was white labeled and distributed into environments that I did not control. I needed a way to programmatically licence code for a set period of time 1 month trial, 5 years etc. Hence this module was created.

=head2 The Licence

The following is an example of a licence that this module generates:

	jQT42jKM_-gfPn32-qs49pg-lpsYxqok

It can be broken down into 4 parts:

=over

=item secret + client/environment

	jQT42jKM_

Decimal Huffman compressed secret + Decimal Huffman compressed client/environment bijected.

=item start time

	gfPn32

The Bijected epoch your licence is valid from.

=item expire time

	qs49pg

The Bijected epoch your licence is valid to.

=item duration

	lpsYxqok

The Bijected duration of the licence (expire time - start time) this is to validate that the licence has not been manipulated.

=back

=head1 Generate/Validate

=head2 new

Both Generate and Validate accept the same parameters to new 

=over 

=item secret

A string that should have an entropy greater than 3. This value is meant to be set at application level, hidden in compiled abstracted code.

=item increment

A float that will be used to build the huffman symbols table.

=item biject

An array reference that is passed to bijection_set.

=item offset

An offset that is passed to bijection_set.

=back

=head2 generate

To generate a licence it as simple as the following:

	my $generator = Enterprise::Licence::Generate->new({ secret => $secret });
	my $licence = $generator->generate('world-wide', { months => 1 });

=over

=item client/environment

The first param to generate should be your environment/client identifier.

=item duration

The second param should be a valid reference that can be passed to DateTime->add().

=back

=cut

=head2 validate

To validate a licence:

	my $validator = Enterprise::Licence::Validate->new({ secret => $secret });
	my @valid = $validator->valid($licence, 'world-wide');
	# (1) == The licence is valid
	# (0, 1) == The licence is valid but it has expired
	# (0, 0) == The licence is invalid.

=over

=item client/environment

The first param to validate should be the licence string.

=item duration

The second param to validate should be your environment/client identifier.

=back

=cut

=head1 AUTHOR

LNATION, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-enterprise-licence at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Enterprise-Licence>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Enterprise::Licence


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Enterprise-Licence>

=item * Search CPAN

L<http://search.cpan.org/dist/Enterprise-Licence/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2019->2025 LNATION.

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

1; # End of Enterprise::Licence
