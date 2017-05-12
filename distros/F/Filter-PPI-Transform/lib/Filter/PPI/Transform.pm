package Filter::PPI::Transform;

use strict;
use warnings;

our $VERSION = 'v0.0.2'; # VERSION

use Filter::Simple;
use Carp;

FILTER {
	shift;
        my $trans_name = shift;
	eval "require $trans_name" or croak "require $trans_name failed: $@";
	croak "The first argument of use $trans_name MUST be subclass of PPI::Transform" if ! $trans_name->isa('PPI::Transform');
	my $trans = $trans_name->new(@_);
	my $doc = PPI::Document->new(\$_);
	$trans->document($doc);
	$_ = $doc->serialize;
};

1;
__END__
=pod

=head1 NAME

Filter::PPI::Transform - Tiny adapter module from PPI::Transform to source filter

=head1 SYNOPSIS

  use Filter::PPI::Transform 'PPI::Transform::UpdateCopyright', name => 'Yasutaka ATARSHI';
  # source filter by PPI::Transform::UpdateCopyright is enabled here

=head1 DESCRIPTION

Source filter has unlimited power to enhance Perl.
L<PPI> enables us to modify Perl document easily and it provides L<PPI::Transform> interface for document transformation.
This module is a tiny adapter from PPI::Transform to source filter.

=head1 OPTION

The first option MUST be a name of subclass of C<PPI::Transform>. Rest of the options are passed to the transform class C<new>.

=head1 SEE ALSO

=over 4

=item *

L<https://github.com/yak1ex/Filter-PPI-Transform> - Github repository

=item *

L<Filter::PPI> - Another PPI based source filtering. L<PPI::Document> is used.

=item *

L<Filter::Simple>

=back

=head1 AUTHOR

Yasutaka ATARASHI <yakex@cpan.org>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
