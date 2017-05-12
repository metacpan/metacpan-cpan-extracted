#!/usr/bin/perl -w

use strict;
use warnings;

use Config::IniFiles;
use Mac::QuickBundle qw(build_application);

my $cfg = Config::IniFiles->new( -file => $ARGV[0] );

build_application( $cfg );

__END__

=head1 NAME

quickbundle - build Mac OS X bundles for Perl scripts

=head1 SYNOPSIS

    quickbundle.pl bundle.ini

And in the configuration file:

    [application]
    name=MyFilms
    dependencies=myfilms_dependencies
    main=bin/myfilms

    [myfilms_dependencies]
    scandeps=myfilms_scandeps

    [myfilms_scandeps]
    script=bin/myfilms
    inc=lib

=head1 DESCRIPTION

This is a thin wrapper around L<Mac::QuickBundle>.

=head1 AUTHOR

Mattia Barbon <mbarbon@cpan.org>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
