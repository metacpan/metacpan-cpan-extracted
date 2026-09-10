package Koha::QA::Security;

use Modern::Perl;

=head1 NAME

Koha::QA::Security - Security-related QA checks for Koha

=head1 SYNOPSIS

  use Koha::QA::Security;

=head1 DESCRIPTION

This is a namespace for security-related QA check modules.

=head1 MODULES

=over 4

=item L<Koha::QA::Security::TemplateFilters> - Detect and fix missing filters in TT templates

=item L<Koha::QA::Security::CSRF> - Check for missing CSRF tokens in forms

=item L<Koha::QA::Security::Nonce> - Check for missing nonce attributes in script/link tags

=back

=head1 SEE ALSO

L<Koha::QA>

=cut

1;
