package Dist::Zilla::PluginBundle::Prereqs;

our $VERSION = '0.93'; # VERSION
# ABSTRACT: Useful Prereqs modules in a Dist::Zilla bundle

use sanity;
use Moose;

with 'Dist::Zilla::Role::PluginBundle::Merged' => { mv_plugins => [qw( AutoPrereqs MinimumPerl )] };
 
sub configure { shift->add_merged( qw[ AutoPrereqs MinimumPerl MinimumPrereqs PrereqsClean ] ); }

__PACKAGE__->meta->make_immutable;
42;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Prereqs - Useful Prereqs modules in a Dist::Zilla bundle

=head1 SYNOPSIS

    ; Instead of this...
    [AutoPrereqs]
    skip = ^Foo|Bar$
    [MinimumPerl]
    [MinimumPrereqs]
    minimum_year = 2008
    [PrereqsClean]
    minimum_perl = 5.8.8
    removal_level = 2
 
    ; ...use this
    [@Prereqs]
    skip = ^Foo|Bar$
    minimum_year = 2008
    minimum_perl = 5.8.8
    removal_level = 2
 
    ; and potentially put some manual entries afterwards...
    [Prereqs]
    ; ...
    [RemovePrereqs]
    ; ...
    [RemovePrereqsMatching]
    ; ...
    [Conflicts]
    ; ...

=head1 DESCRIPTION

This is a handy L<Dist::Zilla> plugin bundle that ties together several useful Prereq
plugins:

=over

=item *

L<AutoPrereqs|Dist::Zilla::Plugin::AutoPrereqs>

=item *

L<MinimumPerl|Dist::Zilla::Plugin::MinimumPerl>

=item *

L<MinimumPrereqs|Dist::Zilla::Plugin::MinimumPrereqs>

=item *

L<PrereqsClean|Dist::Zilla::Plugin::PrereqsClean>

=back

This also delegates the ordering pitfalls, so you don't have to worry about that.  All
of the options from those plugins are directly supported from within the bundle, via
L<PluginBundle::Merged|Dist::Zilla::Role::PluginBundle::Merged>.

=head1 SEE ALSO

"Manual entry" Dist::Zilla Prereq plugins: L<Prereqs|Dist::Zilla::Plugin::Prereqs>, L<RemovePrereqs|Dist::Zilla::Plugin::RemovePrereqs>,
L<RemovePrereqsMatching|Dist::Zilla::Plugin::RemovePrereqsMatching>, L<Conflicts|Dist::Zilla::Plugin::Conflicts>

=head1 AVAILABILITY

The project homepage is L<https://github.com/SineSwiper/Dist-Zilla-PluginBundle-Prereqs>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Dist::Zilla::PluginBundle::Prereqs/>.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Internet Relay Chat

You can get live help by using IRC ( Internet Relay Chat ). If you don't know what IRC is,
please read this excellent guide: L<http://en.wikipedia.org/wiki/Internet_Relay_Chat>. Please
be courteous and patient when talking to us, as we might be busy or sleeping! You can join
those networks/channels and get help:

=over 4

=item *

irc.perl.org

You can connect to the server at 'irc.perl.org' and talk to this person for help: SineSwiper.

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests via L<https://github.com/SineSwiper/Dist-Zilla-PluginBundle-Prereqs/issues>.

=head1 AUTHOR

Brendan Byrd <BBYRD@CPAN.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Brendan Byrd.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
