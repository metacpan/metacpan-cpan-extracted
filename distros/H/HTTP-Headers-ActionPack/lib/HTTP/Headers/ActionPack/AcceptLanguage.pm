package HTTP::Headers::ActionPack::AcceptLanguage;
BEGIN {
  $HTTP::Headers::ActionPack::AcceptLanguage::AUTHORITY = 'cpan:STEVAN';
}
{
  $HTTP::Headers::ActionPack::AcceptLanguage::VERSION = '0.09';
}
# ABSTRACT: A Priority List customized for Media Types

use strict;
use warnings;

use parent 'HTTP::Headers::ActionPack::PriorityList';

# We'll just assume that any script or variant names are being given in the
# right form. To do this all properly would basically require having all the
# ICU data available, which we're not going to attempt currently.
sub canonicalize_choice {
    return unless defined $_[1];
    my @parts = split /[-_]/, $_[1];

    my $lang = lc shift @parts;

    if (@parts) {
        $parts[-1] = uc $parts[-1]
            if length $parts[-1] == 2;
    }

    return join '-', $lang, @parts;
}

1;

__END__

=pod

=head1 NAME

HTTP::Headers::ActionPack::AcceptLanguage - A Priority List customized for Media Types

=head1 VERSION

version 0.09

=head1 SYNOPSIS

  use HTTP::Headers::ActionPack::AcceptLanguage;

  # normal constructor
  my $list = HTTP::Headers::ActionPack::AcceptLanguage->new(
      [ 1.0 => 'en-US' ],
      [ 0.7 => 'en-GB' ],
  );

  # or from a string
  my $list = HTTP::Headers::ActionPack::AcceptLanguageList->new_from_string(
      'en-US; q=1.0, en-GB; q=0.7'
  );

=head1 DESCRIPTION

This is a subclass of the L<HTTP::Headers::ActionPack::PriorityList>
class with some language specific features.

=head1 METHODS

=over 4

=item C<canonicalize_choice>

This takes a string containing a locale code and returns the canonical version
of that code.

This is incomplete, as it simply lower cases the language piece ("en", "zh")
and upper cases the country ("US", "TW"). It does not attempt to canonicalize
scripts or variants in the locale code.

=back

=head1 AUTHOR

Stevan Little <stevan.little@iinteractive.com>

=head1 CONTRIBUTORS

=over 4

=item *

Andrew Nelson <anelson@cpan.org>

=item *

Dave Rolsky <autarch@urth.org>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Jesse Luehrs <doy@tozt.net>

=item *

Karen Etheridge <ether@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
