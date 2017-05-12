package Dist::Zilla::App::Command::msg_scan;

# ABSTRACT: Collect localization strings into a translation template

use Dist::Zilla::App -command;
use strict;
use warnings;
use Moose;
use namespace::autoclean;

our $VERSION = '0.90';

with 'Dist::Zilla::Role::PotWriter';

sub command_names { qw(msg-scan) }

sub abstract { 'scan localization strings into a translation template' }

sub usage_desc { '%c %o' }

sub opt_spec {
    return (
        [ 'xgettext|x=s'         => 'location of xgttext utility'      ],
        [ 'encoding|e=s'         => 'charcter encoding to be used'     ],
        [ 'pot-file|pot|p=s'     => 'pot file location'                ],
        [ 'copyright-holder|c=s' => 'name of the copyright holder'     ],
        [ 'bugs-email|b=s'       => 'email address for reporting bugs' ],
    );
}

sub validate_args {
    my ($self, $opt, $args) = @_;

    require IPC::Cmd;
    my $xget = $opt->{xgettext} ||= 'xgettext' . ($^O eq 'MSWin32' ? '.exe' : '');
    $self->zilla->log_fatal(
        qq{Cannot find "$xget": Are the GNU gettext utilities installed?}
    ) unless IPC::Cmd::can_run($xget);

    if (my $enc = $opt->{encoding}) {
        require Encode;
        $self->zilla->log_fatal(qq{"$enc" is not a valid encoding})
            unless Encode::find_encoding($enc);
    } else {
        $opt->{encoding} = 'UTF-8';
    }
}

sub execute {
    my ( $self, $opt ) = @_;

    require Path::Class;
    my $dzil     = $self->zilla;
    my $plugin   = $self->zilla->plugin_named('LocaleTextDomain')
        or $dzil->log_fatal('LocaleTextDomain plugin not found in dist.ini!');
    my $pot_file = Path::Class::file($opt->{pot_file} || (
        $plugin->lang_dir, $self->zilla->name . '.pot'
    ));

    $plugin->log("extracting gettext strings into $pot_file");
    $self->write_pot(
        to               => $pot_file,
        xgettext         => $opt->{xgettext},
        encoding         => $opt->{encoding},
        copyright_holder => $opt->{copyright_holder},
        bugs_email       => $opt->{bugs_email},
    );
}

1;
__END__

=head1 Name

Dist::Zilla::App::Command::msg_scan - Scan localization strings into a translation template

=head1 Synopsis

In F<dist.ini>:

  [LocaleTextDomain]
  textdomain = My-App
  lang_dir = po

On the command line:

  dzil msg-scan

=head1 Description

This command scans your distribution's Perl modules and creates or updates a
L<GNU gettext|http://www.gnu.org/software/gettext/>-style language translation
template. It relies on the settings from the
L<C<LocaleTextDomain> plugin|Dist::Zilla::Plugin::LocaleTextDomain> for its
settings, and requires that the GNU gettext utilities be available.

=head2 Options

=head3 C<--xgettext>

The location of the C<xgettext> program, which is distributed with L<GNU
gettext|http://www.gnu.org/software/gettext/>. Defaults to just C<xgettext>,
which should work if it's in your path.

=head3 C<--encoding>

The encoding to assume the Perl modules are encoded in. Defaults to C<UTF-8>.

=head3 C<--pot-file>

The name of the template file to write to. Defaults to
C<$lang_dir/$textdomain.pot>.

=head3 C<--copyright-holder>

Name of the application copyright holder. Defaults to the copyright holder
defined in F<dist.ini>.

=head3 C<--bugs-email>

Email address to which translation bug reports should be sent. Defaults to the
email address of the first distribution author, if available.

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Copyright and License

This software is copyright (c) 2012-2013 by David E. Wheeler.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut
