
package DocSet::Doc::HTML2HTMLPS;

use strict;
use warnings;

use DocSet::Util;

use vars qw(@ISA);
require DocSet::Doc::HTML2HTML;
@ISA = qw(DocSet::Doc::HTML2HTML);

use DocSet::Doc::Common ();
*postprocess = \&DocSet::Doc::Common::postprocess_ps_pdf;

1;
__END__

=head1 NAME

C<DocSet::Doc::HTML2HTMLPS> - HTML source to PS (intermediate HTML) target converter

=head1 SYNOPSIS



=head1 DESCRIPTION

See C<DocSet::Doc::HTML2HTML>. This sub-class only extends the
postprocess() method.

=head1 METHODS

For the rest of the super class methods see C<DocSet::Doc::HTML2HTML>.

=over

=item * postprocess()

Convert the generated HTML doc to PS and PDF.

=back

=head1 AUTHORS

Stas Bekman E<lt>stas (at) stason.orgE<gt>

=cut
