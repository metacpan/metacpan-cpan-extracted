package Dist::Zilla::Plugin::SchwartzRatio;
BEGIN {
  $Dist::Zilla::Plugin::SchwartzRatio::AUTHORITY = 'cpan:YANICK';
}
{
  $Dist::Zilla::Plugin::SchwartzRatio::VERSION = '0.2.0';
}
# ABSTRACT: display the Schwartz ratio of the distribution upon release


use strict;
use warnings;

use LWP::Simple;

use Moose;

with qw/
    Dist::Zilla::Role::Plugin
    Dist::Zilla::Role::AfterRelease
/;

sub after_release {
    my $self = shift;

    # I'm going to hell for that...

    my $page = join "", LWP::Simple::get( 'http://search.cpan.org/dist/' .
        $self->zilla->name );

    my @releases;

    push @releases, $1 if $page =~ m#This Release.*?<td.*?>(.*?)</td>#s;

    if ( $page =~ m#Other Releases.*?<select name="url">(.*?)</select>#s ) {
        my $inner = $&;
        push @releases, map { my $x = $_; $x =~ s/&nbsp;&nbsp;--&nbsp;&nbsp;/, /; $x } $inner =~ />(.*?)</g;
    }

    $self->log( @releases . " old releases are lingering on CPAN" );
    $self->log( "\t" . $_ ) for @releases;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__
=pod

=head1 NAME

Dist::Zilla::Plugin::SchwartzRatio - display the Schwartz ratio of the distribution upon release

=head1 VERSION

version 0.2.0

=head1 SYNOPSIS

In dist.ini:

    [SchwartzRatio]

=head1 DESCRIPTION

The Schwartz Ratio of CPAN is the number of number of latest
releases over the total number of releases that CPAN has. For
a single distribution, it boils down to the less exciting
number of previous releases still on CPAN. 

After a successful release, the plugin displays
the releases of the distribution still kickign around on CPAN,
just to give an idea to the author that maybe it's time
to do some cleanup.

=head1 AUTHOR

Yanick Champoux <yanick@babyl.dyndns.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

