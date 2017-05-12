use utf8;
package Dist::Zilla::Plugin::ContributorsFromPod;
BEGIN {
  $Dist::Zilla::Plugin::ContributorsFromPod::AUTHORITY = 'cpan:RKITOVER';
}
$Dist::Zilla::Plugin::ContributorsFromPod::VERSION = '0.01';
use 5.008001;
use Moose;
use MooseX::Types::Moose qw/ArrayRef Str/;
use Pod::Text;
use List::AllUtils 'apply';

with 'Dist::Zilla::Role::MetaProvider';

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::ContributorsFromPod - Populate meta x_contributors
from CONTRIBUTORS POD in the dist

=head1 SYNOPSIS

in dist.ini:

  [ContributorsFromPod]

=head1 DESCRIPTION

If you have a

  =head1 CONTRIBUTORS

section in your main file in your distribution, this L<Dist::Zilla>
plugin will populate your META.json x_contributors list from it.

The format should be:

  Some Name <some@email.com>

nicknames are also supported:

  ircnick: Some Name <some@email.com>

B<NOTE:> the word C<CONTRIBUTORS> must be in upper case, and the
following C<=head1> section must also be in upper case. C<CONTRIBUTORS>
being the last C<=head1> section is also fine. This is because we use a
regex to parse out the list from Pod::Text.

=cut

has _contributors => (is => 'ro', isa => ArrayRef[Str], lazy_build => 1);

sub metadata {
    my $self = shift;

    return $self->_contributors ? { 'x_contributors' => $self->_contributors } : {};
}

sub _build__contributors {
    my $self = shift;

    my $pod_parser = Pod::Text->new(
        code   => 1,
        errors => 'die',
        indent => 0,
        quotes => 'none',
        width  => ~0
    );

    $pod_parser->output_string(\my $output);

    $pod_parser->parse_file($self->zilla->main_module->name);

    # grab the actual contributors section

    my ($emails) = $output =~ /^CONTRIBUTOR[[:upper:]\s]*\s (.+?) (?:^[[:upper:][:punct:]\s]+$ | \s*\Z)/msx;

    return [
        apply { s/^\S+?:\s*// }                   # strip irc_nic: ... prefixes
        grep /^[^<>@]+ <[^<>]+ \@ [^<>]+> \s*$/x, # loose filter for contributor lines
        split /\s*(?:\r?\n)+\s*/, $emails         # split by newline
    ];
}

=head1 SEE ALSO

=over 4

=item * L<Dist::Zilla::Plugin::ContributorsFromGit>

=item * L<Dist::Zilla::Role::MetaProvider>

=back

=head1 AUTHOR

Rafael Kitover <rkitover@cpan.org>

=cut

__PACKAGE__->meta->make_immutable;

__PACKAGE__; # End of Dist::Zilla::Plugin::ContributorsFromPod
