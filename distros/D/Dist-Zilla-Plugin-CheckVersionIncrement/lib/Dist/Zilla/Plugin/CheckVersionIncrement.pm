## no critic
package Dist::Zilla::Plugin::CheckVersionIncrement;
{
  $Dist::Zilla::Plugin::CheckVersionIncrement::VERSION = '0.121750';
}
## use critic
# ABSTRACT: Prevent a release unless the version number is incremented
use Moose;

with 'Dist::Zilla::Role::BeforeRelease';
use Encode qw(encode_utf8);
use LWP::UserAgent;
use version ();
use JSON::PP;


# Lots of this is cargo-culted from DZP::CheckPrereqsIndexed
sub before_release {
    my ($self) = @_;

    my $pkg = $self->zilla->name;
    $pkg =~ s/-/::/g;
    ### $pkg

    my $pkg_version = version->parse($self->zilla->version);
    my $indexed_version;

    my $ua = LWP::UserAgent->new(keep_alive => 1);
    $ua->env_proxy;
    my $res = $ua->get("http://cpanidx.org/cpanidx/json/mod/$pkg");
    if ($res->is_success) {
        my $yaml_octets = encode_utf8($res->decoded_content);
        my $payload = JSON::PP->new->decode($yaml_octets);
        if (@$payload) {
            $indexed_version = version->parse($payload->[0]{mod_vers});
        }
    }

    if ($indexed_version) {
        return if $indexed_version < $pkg_version;

        my $indexed_description;
        if ($indexed_version == $pkg_version) {
            $indexed_description = "the same version ($indexed_version)";
        }
        else {
            $indexed_description = "a higher version ($indexed_version)";
        }

        return if $self->zilla->chrome->prompt_yn(
            "You are releasing version $pkg_version but $indexed_description is already indexed on CPAN. Release anyway?",
            { default => 0 }
        );
        $self->log_fatal("aborting release of version $pkg_version because $indexed_description is already indexed on CPAN");
    }
    else {
        $self->log("Dist not indexed on CPAN. Skipping check for incremented version.");
    }
}

1; # Magic true value required at end of module


=pod

=head1 NAME

Dist::Zilla::Plugin::CheckVersionIncrement - Prevent a release unless the version number is incremented

=head1 VERSION

version 0.121750

=head1 SYNOPSIS

In your F<dist.ini>

    [CheckVersionIncrement]

=head1 DESCRIPTION

This plugin prevents your from releasing a distribution unless it has
a version number I<greater> than the latest version already indexed on
CPAN.

Note that this plugin doesn't check whether your release method
actually involves the CPAN or not. So if you don't use the
UploadToCPAN plugin for releases, then you probably shouldn't use this
one either.

=head1 METHODS

=head2 before_release

This method checks the version of the dist to be released against the
latest version already indexed on CPAN. If the version to be released
is not greater than the indexed version, it prompts the user to
confirm the release.

This method does nothing if the dist is not indexed at all.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<rct+perlbug@thompsonclan.org>.

=head1 SEE ALSO

=over 4

=item *

L<Dist::Zilla::Plugin::CheckPrereqsIndexed> - Used as the example for getting the indexed version of a dist

=back

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AUTHOR

Ryan C. Thompson <rct@thompsonclan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ryan C. Thompson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut


__END__

