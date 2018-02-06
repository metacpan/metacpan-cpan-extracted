package Dist::Zilla::Plugin::Author::SKIRMESS::InsertVersion;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.032';

use Moose;

with qw(
  Dist::Zilla::Role::FileMunger
);

use Carp;
use Path::Tiny;

use namespace::autoclean;

sub munge_file {
    my ( $self, $file ) = @_;

    my $filename = $file->name;

    # stringify returns the path standardized with Unix-style / directory
    # separators.
    return if path($filename)->stringify() !~ m{ ^ (?: bin | lib | xt | t ) / }xsm;

    my $content = $file->content;

    # Skip files without pod
    return if $content !~ m{ ^ =pod }xsm;

    if ( $content !~ m{ ^ =head1 \s+ VERSION $ }xsm ) {
        $self->log("No VERSION section found in POD in file $filename. Skipping it.");
        return;
    }

    # Replace the existing VERSION section with the current version
    my $version_section = "\n\n=head1 VERSION\n\nVersion " . $self->zilla->version . "\n\n";
    if (
        $content !~ s{
            [\s\n]*
            ^ =head1 \s+ VERSION [^\n]* $
            .*?
            ^ ( = (?: head | cut ) )
        }{$version_section$1}xsm
      )
    {
        $self->log_fatal("Unable to replace VERSION section in file $filename.");

        # log_fatal should die
        croak 'internal error';
    }

    $file->content($content);
    return;
}

__PACKAGE__->meta->make_immutable;

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
