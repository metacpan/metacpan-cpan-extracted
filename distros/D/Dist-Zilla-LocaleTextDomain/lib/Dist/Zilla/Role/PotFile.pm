package Dist::Zilla::Role::PotFile;

# ABSTRACT: Something finds or creates a gettext language translation template file

use Moose::Role;
use strict;
use warnings;
use Path::Class;
use namespace::autoclean;

with 'Dist::Zilla::Role::PotWriter';
requires 'zilla';

our $VERSION = '0.90';

sub pot_file {
    my ( $self, %p ) = @_;
    my $dzil = $self->zilla;
    my $pot  = $p{pot_file};
    if ($pot) {
        $dzil->log_fatal("Template file $pot does not exist") unless -e $pot;
        return $pot;
    }

    # Look for a template in the default location used by `msg-scan`.
    my $plugin = $self->zilla->plugin_named('LocaleTextDomain')
        or $dzil->log_fatal('LocaleTextDomain plugin not found in dist.ini!');

    $pot = file $plugin->lang_dir, $dzil->name . '.pot';
    return $pot if -e $pot;

    # Create a temporary template file.
    require File::Temp;
    my $tmp = $self->{tmp} = File::Temp->new(SUFFIX => '.pot', OPEN => 0);
    $pot = file $tmp->filename;
    $self->log('extracting gettext strings');
    $self->write_pot(
        to               => $pot,
        xgettext         => $p{xgettext},
        encoding         => $p{encoding},
        copyright_holder => $p{copyright_holder},
        bugs_email       => $p{bugs_email},
    );
    return $self->{potfile} = $pot;
}

1;
__END__

=head1 Name

Dist::Zilla::Plugin::PotFile - Something finds or creates a gettext language translation template file

=head1 Synopsis

  with 'Dist::Zilla::Role::PotFile';

  # ...

  sub execute {
      my $self = shift;
      my $pot_file = $self->pot_file(%params);
  }


=head1 Description

This role provides a utility method for finding or creating a
L<GNU gettext|http://www.gnu.org/software/gettext/>-style language translation
template.

=head2 Instance Methods

=head3 C<pot_file>

  $self->pot_file(%params);

Finds or creates a temporary
L<GNU gettext|http://www.gnu.org/software/gettext/>-style language translation
file. It works in this order:

=over

=item *

If the C<pot_file> parameter is passed a value and the named file exists, it
will be returned.

=item *

If the file stored in the language directory, as specified for the
L<C<LocaleTextDomain> plugin|Dist::Zilla::Plugin::LocaleTextDomain>, with the
name of the distribution and ending in F<.pot>, it will be returned. This is
the default location for a template file created by the
L<C<msg-scan>|Dist::Zilla::App::Command::msg_scan> command.

=item *

The sources will be scanned for localizable strings and a temporary template
file created. This file will automatically be deleted at program exit.

=back

The supported parameters are:

=over

=item C<pot_file>

A path to an existing translation template file. If this file does not exist,
an exception will be thrown.

=item C<xgettext>

Path to the C<xgettext> application. Defaults to just C<xgettext>
(C<xgettext.exe> on Windows), which should work if it's in your path.

=item C<encoding>

Encoding to assume when scanning for localizable strings. Defaults to
C<UTF-8>.

=item C<copyright_holder>

The name of the translation copyright holder. Defaults to the copyright holder
configured for L<Dist::Zilla>.

=item C<bugs_email>

Email address for reporting translation bugs. Defaults to the email address of
the first author known to L<Dist::Zilla>, if available and parseable by
L<Email::Address>.

=back

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Copyright and License

This software is copyright (c) 2012-2013 by David E. Wheeler.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut
