package Import::Export;

use Carp;
use namespace::clean ();

our $VERSION = '1.01';

our %EX;

our %EXTYPE = (
	'&' => \&_export_code,
	'$' => \&_export_scalar,
	'@' => \&_export_array,
	'%' => \&_export_hash,
	'*' => \&_export_glob,
);

sub import {
	my ($pkg, $options, $caller) = (shift, {}, caller());
	return unless my @export = @_;
	Carp::croak('define your %EX export hash')
		unless (%EX) = %{"${pkg}::EX"};

	$options = pop @export if ref $export[-1];
	$caller = $options->{-caller} if exists $options->{-caller};
	my @exported = export($pkg, $caller, @export);

	$options->{clean} and "$options->{clean}" eq "import"
		? namespace::clean->clean_subroutines( # sub import { p->import(@export, { clean => 'import' }) }
			$caller,
			@exported
		)
		: namespace::clean->import(  # use p @export, { clean => 1 }
			-cleanee => $caller,
			@exported
		);
}

sub export {
	my ($pkg, $caller, @exported) = (shift, shift);
	while (my $ex = shift) {
		my $type;
		if ( ! $EX{$ex} ) {
		 	my @export = grep {
				grep { $_ =~ m{\Q$ex\E} } @{ $EX{$_} }
			} keys %EX;
			scalar @export
				? return export($pkg, $caller, (@export, @_))
				: Carp::croak "$ex is not exported";
		}

		$type = ($ex =~ s/^(\W)//) ? $1 : "&";
		$caller->can($ex) and next;

		my $exporting = $EXTYPE{$type} or Carp::croak("Cant export symbol $type");
		*{"${caller}::${ex}"} = $exporting->($pkg, $ex);
		push @exported, $ex;
	}
	return @exported;
}

sub _export_code { \&{"$_[0]::$_[1]"} }
sub _export_scalar { \${"$_[0]::$_[1]"} }
sub _export_array { \@{"$_[0]::$_[1]"} }
sub _export_hash { \%{"$_[0]::$_[1]"} }
sub _export_glob { *{"$_[0]::$_[1]"} }

1;

__END__

=head1 NAME

Import::Export - Exporting

=head1 VERSION

Version 1.01

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

	package One;

	use base 'Import::Export';

	our %EX = (
		one => [qw/all/],
		two => [qw/all another/]
	);

	sub one { 'Echo' }

	package One::Two;

	use One qw/all/;

	.....

	use One qw/one/ { clean => 1 };

	.....

	package Lost

	sub import {
		...
		require Found;
		Found->import(qw/all/, { clean => 'import', -caller => $caller });
		...
	}


=head2 import

=head2 export

=head1 AUTHOR

Robert Acock, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-combine-keys at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Import-Export>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Import::Export

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Import-Export>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Import-Export>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Import-Export>

=item * Search CPAN

L<http://search.cpan.org/dist/Import-Export/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Robert Acock.

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

