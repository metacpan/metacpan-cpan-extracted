package Locale::Maketext::Utils::Phrase::cPanel;

use strict;
use warnings;

$Locale::Maketext::Utils::Phrase::cPanel::VERSION = '0.1';

use Locale::Maketext::Utils::Phrase::Norm ();
use base 'Locale::Maketext::Utils::Phrase::Norm';

# Mock Cpanel::Locale-specific bracket notation methods for the filters’ default maketext object:
use Locale::Maketext::Utils::Mock ();
Locale::Maketext::Utils::Mock->create_method(
    {
        'output_cpanel_error'        => undef,
        'get_locale_name_or_nothing' => undef,
        'get_locale_name'            => undef,
        'get_user_locale_name'       => undef,
    }
);

sub new_legacy_source {
    my $conf = ref( $_[-1] ) eq 'HASH' ? pop(@_) : {};

    $conf->{'exclude_filters'}{'Ampersand'} = 1;
    $conf->{'exclude_filters'}{'Markup'}    = 1;

    push @_, $conf;
    goto &Locale::Maketext::Utils::Phrase::Norm::new_source;
}

sub new_legacy_target {
    my $conf = ref( $_[-1] ) eq 'HASH' ? pop(@_) : {};

    $conf->{'exclude_filters'}{'Ampersand'} = 1;
    $conf->{'exclude_filters'}{'Markup'}    = 1;

    push @_, $conf;
    goto &Locale::Maketext::Utils::Phrase::Norm::new_target;
}

# If they ever diverge we simply need to:
#  1. Update POD
#  2. probably update t/08.cpanel_norm.t
#  3. add our own new_source() or list of defaults that SUPER::new_source would call instead of using its array or something
# sub new_source {
#     …
#     return $_[0]->SUPER::new_source(… @non_default_list …);
# }

1;

__END__

=encoding utf-8

=head1 NAME

Locale::Maketext::Utils::Phrase::cPanel - cPanel recipe to Normalize and perform lint-like analysis of phrases

=head1 VERSION

This document describes Locale::Maketext::Utils::Phrase::cPanel version 0.1

=head1 SYNOPSIS

    use Locale::Maketext::Utils::Phrase::cPanel;

    my $norm = Locale::Maketext::Utils::Phrase::cPanel->new_source() || die;

    my $result = $norm->normalize('This office has worked [quant,_1,day,days,zero days] without an “accident”.');

    # process $result

=head1 DESCRIPTION

Exactly like L<Locale::Maketext::Utils::Phrase::Norm> except the default filters are what cPanel requires.

=head1 DEFAULT cPanel RECIPE FILTERS

Currently the same as the base class’s L<Locale::Maketext::Utils::Phrase::Norm/"DEFAULT FILTERS">.

If that ever changes it will be reflected here.

=head2 Legacy related methods

=head3 new_legacy_source()

Just like L<base new_source()|Locale::Maketext::Utils::Phrase::Norm/"new_source()"> except it skips the markup filters since legacy values can contain HTML.

=head3 new_legacy_target()

Just like L<base new_target()|Locale::Maketext::Utils::Phrase::Norm/"new_target()"> except it skips the markup filters since legacy values can contain HTML.

=head1 Internal Object

When a filter needs an object (e.g. Compiles) this module uses a L<Locale::Maketext::Utils::Mock> object that knows about cPanel specific bracket notation methods instead of a Cpanel::Locale object for a number of reasons:

=over 4

=item 1 Availability

Things outside of cPanel code (i.e. systems without access to Cpanel::) will have access to the same code that is used on cPanel servers.

For example: cplint, build servers, QA servers, translators, my laptop, etc

=item 2 Consistency.

Every consumer (including /ULC code, cplint, build servers, QA servers, translators, my laptop, etc) will get the exact same results.

=item 3 Sanity check.

Adding new bracket notation needs done thoughtfully and completely. Requiring it be discussed/vetted and then added upstream (i.e. here) helps ensure that that happens.

=over 4

=item * Does it really belong as bracket notation?

There is a good chance there is already a way to do what you want or that it belongs elsewhere.

=item * If so, is it cPanel specific or should it be in L::M::U ?

=item * In addition to tests and it’s Javascript counterpart:

=over 4

=item * It needs documented in the correct places.

If its not in L::M::U (i.e. it’s POD) then it needs added to our internal and/or public documentation.

=item * XLIFF needs to know about it.

That is true whether it is in L::M::U or C::L.

=item * The security team will want to review it and add it to their list.

That is true whether it is in L::M::U or C::L.

=back

=back

If all of that is satisifed then we add it here and update our RPM and we know we have a solid, well thought out, and well executed new bracket notation method.

All of those benefits in a process that takes a matter of hours from start to finish. If 24 hours seems too long of a delay compare that to the effort required to undo/deprecate/backcompat a poorly planned/implemented thing!

=back

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012 cPanel, Inc. C<< <copyright@cpanel.net>> >>. All rights reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself, either Perl version 5.10.1 or, at your option,
any later version of Perl 5 you may have available.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
