package Dist::Zilla::Plugin::ChangesFromYaml;
# ABSTRACT: convert Changes from YAML to CPAN::Changes::Spec format
our $VERSION = '0.005'; # VERSION

use Moose;
with( 'Dist::Zilla::Role::FileMunger' );
use namespace::autoclean;
use Dist::Zilla::Plugin::ChangesFromYaml::Convert qw(convert);

has dateformat => (is => 'ro', isa => 'Str', default => '');

sub munge_file {
    my ($self, $file) = @_;

    return unless $file->name eq 'Changes';

    $file->content( convert( $file->encoded_content, $self->dateformat ) );
    $self->log_debug(
        [
            'Converte Changes from YAML to CPAN::Changes::Spec', $file->name
        ]
    );
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

Dist::Zilla::Plugin::ChangesFromYaml - convert Changes from YAML to CPAN::Changes::Spec format

=head1 SYNOPSIS

In your 'dist.ini':

    [ChangesFromYaml]

=head1 DESCRIPTION

This module lets you keep your Changes file in YAML format:

    version: 0.37
    date:    Fri Oct 25 21:46:59 MYT 2013
    changes:
    - 'Bugfix: Run Test::Compile tests as xt as they require optional dependencies to be present (GH issue #22)'
    - 'Testing: Added Travis-CI integration'
    - 'Makefile: Added target to update version on all packages'

and during build converts it to CPAN::Changes::Spec format

    0.37 Fri Oct 25 21:46:59 MYT 2013
     - Bugfix: Run Test::Compile tests as xt as they require optional
       dependencies to be present (GH issue #22)
     - Testing: Added Travis-CI integration
     - Makefile: Added target to update version on all packages

=head1 DATE FORMAT

The dates used on the YAML format can also be converted if they don't follow CPAN::Changes::Spec rules.

Ie. if you keep your dates as the output of `date` (Sun Oct 27 02:10:50 MYT 2013), add:

    [ChangesFromYaml]
    dateformat = ccc MMM dd HH:mm:ss zzz yyyy

This will convert your dates from:

    version: 0.37
    date:    Fri Oct 25 21:46:59 MYT 2013

into:

    0.37 2013-10-25 21:46:59 +0800


For documentation on the pattern, read L<DateTime::Format::CLDR>.

=head1 AUTHOR

Carlos Lima <carlos@cpan.org>

=cut
