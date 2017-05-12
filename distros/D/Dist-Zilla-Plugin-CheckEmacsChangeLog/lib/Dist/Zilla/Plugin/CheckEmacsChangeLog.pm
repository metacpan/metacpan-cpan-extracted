#-----------------------------------------------------------------
# Dist::Zilla::Plugin::CheckEmacsChangeLog
# Author: Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer se below.
#
# ABSTRACT: Check missing version in ChangeLog
# PODNAME: Dist::Zilla::Plugin::CheckEmacsChangeLog
#-----------------------------------------------------------------
use strict;
use warnings;
package Dist::Zilla::Plugin::CheckEmacsChangeLog;
our $VERSION = '0.0.2'; # VERSION

use Moose;
extends 'Dist::Zilla::Plugin::CheckChangeLog';

has filename => (
    is      => 'ro',
    isa     => 'Str',
    default => 'ChangeLog',
);

sub check_file_for_version {
    my ( $self, $content, $version ) = @_;

    $SIG{__DIE__} =  sub {
        my $msg = shift;
        $msg =~ s{CheckChangeLog}{CheckEmacsChangeLog}g;
        die $msg;
    };

    use Tie::STDOUT
        print => sub {
            print map { my $m = $_; $m =~ s{CheckChangeLog}{CheckEmacsChangeLog}g; $m } @_;
    };

    my @lines = split( /\n/, $content );
    foreach (@lines) {

        # no blanket lines
        next unless /\S/;

        # seen it?
        return 1 if /\Q$version\E/;
    }
    return 0;
}

1;


=pod

=head1 NAME

Dist::Zilla::Plugin::CheckEmacsChangeLog - Check missing version in ChangeLog

=head1 VERSION

version 0.0.2

=head1 SYNOPSIS

    # dist.ini
    [CheckEmacsChangeLog]

    # or
    [CheckEmacsChangeLog]
    filename = another.file.name

=head1 DESCRIPTION

It is a simple extension of L<Dist::Zilla::Plugin::CheckChangeLog>
allowing to check that a sentence about a new version was added to a
file C<ChangeLog> in your project. It differs from the
L<Dist::Zilla::Plugin::CheckChangeLog> by expecting the format of the
C<ChangeLog> file being the one used by the Emacs's ChangeLog
mode. Which means, for example, this one:

   2012-03-03  Martin Senger  <martin.senger&#64;gmail.com>
      * Version 0.0.1 released

=head1 ATTRIBUTES

There is one optional attribute C<filename> allowing to change the
file name with the logs:

    [CheckEmacsChangeLog]
    filename = another.file.name

The main reason for having this attribute is that it has a default
value C<ChangeLog> (suitable for Emacs) which is different from the
one used in the original L<Dist::Zilla::Plugin::CheckChangeLog>.

=head1 AUTHOR

Martin Senger <martin.senger@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Martin Senger, CBRC-KAUST (Computational Biology Research Center; King Abdullah University of Science and Technology) All Rights Reserved..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

