use 5.006;
use strict;
use warnings;

=head1 NAME

EJS::Template::Util - Utility for EJS::Template

=cut

package EJS::Template::Util;
use base 'Exporter';

our @EXPORT_OK = qw(clean_text_ref);

use Encode;
use Scalar::Util qw(tainted);

=head1 Methods

=head2 clean_text_ref

Usage:

    my $original_ref = \'some text';
    my $modified_ref = clean_text_ref($original_ref,
            $encode_utf8, $sanitize_utf8, $force_untaint);
    
    # where the last three arguments are boolean values
    # to indicate whether each conversion is required.

Depending on JavaScript engines, the text value passed from Perl to JavaScript
needs to be cleaned up, especially related to the UTF8 flag and the taint mode.

It takes a reference to the text as the first argument, and returns a reference
to the modified text, of if no conversion is necessary, the original reference
is returned.

=over 4

=item * $encode_utf8

Indicates the text needs to be a utf8-encoded string, where the utf8 flag
has to be turned off.

=item * $sanitize_utf8

Indicates the text cannot contain any invalid utf8 characters. The conversion
is done by applying C<Encode::decode_utf8()> and then C<Encode::encode_utf8()>.

=item * $force_untaint

Indicates tainted strings cannot be passed to the JavaScript engine. This flag
effectively disables the taint flag, trusting the JavaScript code to be safe.

=back

=cut

sub clean_text_ref {
    my ($value_ref, $encode_utf8, $sanitize_utf8, $force_untaint) = @_;
    
    if (Encode::is_utf8($$value_ref)) {
        if ($encode_utf8) {
            # UTF8 flag must be turned off. (Otherwise, segmentation fault occurs)
            $value_ref = \Encode::encode_utf8($$value_ref);
        }
    } elsif ($sanitize_utf8 && $$value_ref =~ /[\x80-\xFF]/) {
        # All characters must be valid UTF8. (Otherwise, segmentation fault occurs)
        $value_ref = \Encode::encode_utf8(Encode::decode_utf8($$value_ref));
    }
    
    if ($force_untaint && tainted($$value_ref)) {
        $$value_ref =~ /(.*)/s;
        $value_ref = \qq($1);
    }
    
    return $value_ref;
}

=head1 SEE ALSO

=over 4

=item * L<EJS::Template>

=back

=cut

1;
