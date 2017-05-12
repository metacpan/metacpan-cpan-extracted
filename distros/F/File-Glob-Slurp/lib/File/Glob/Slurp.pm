package File::Glob::Slurp;
use 5.008001;
use warnings;
use strict;
our $VERSION = sprintf "%d.%02d", q$Revision: 0.2 $ =~ /(\d+)/g;
use Carp;

no warnings 'redefine';

*CORE::GLOBAL::glob = sub {
    my $path = shift;
    $path =~ s/\A\s+//;
    $path =~ s/\s+\z//;
    my $slurp;
    if ( $path =~ m{\w+://} ) {
        eval { require LWP::Simple; };
        croak $@ if $@;
        $slurp = LWP::Simple::get($path);
    }
    else {
        local $/;
        open my $fh, '<', $path or croak "$path:$!";
        $slurp = CORE::readline($fh);
        close $fh;
    }
    return $slurp;
};

if ($0 eq __FILE__){
    my $content = <http://www.dan.co.jp/>;
    print $content;
}

1; # End of File::Glob::Slurp

=head1 NAME

File::Glob::Slurp - Turns <> into a slurp operator

=head1 VERSION

$Id: Slurp.pm,v 0.2 2009/06/10 05:51:19 dankogai Exp dankogai $

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

  use File::Glob::Slurp;
  # slurps path/to/filename.ext
  my $home = <path/to/filename.ext>; 
  # you can do this if you have LWP::Simple
  my $away = <http://example.com/>;

=head1 EXPORT

tweaks C<CORE::GLOBAL::glob>

=head1 DESCRIPTION

HACK #90 of PERL HACK proved that C<< <*glob*> >> operator is a pretty
good place to implement micro-DSL.  This module turns ancient 
C<< *glob* >> operator into modern C<< slurp >> operator!

As shown in L</SYNOPSIS>, The overridden C<< <> >> slurps not only
local files but also URL if you have L<LWP::Simple> installed.

=head2 CAVEAT

Unfortunately C<< <> >> also acts as C<readline()>.  Therefore

  my $content = <$path>;

Does not work.  In such cases simply add whitespece like:

  my $content = < $path >;

=head1 AUTHOR

Dan Kogai, C<< <dankogai at dan.co.jp> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-file-glob-slurp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Glob-Slurp>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::Glob::Slurp

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Glob-Slurp>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-Glob-Slurp>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-Glob-Slurp>

=item * Search CPAN

L<http://search.cpan.org/dist/File-Glob-Slurp/>

=back

=head1 ACKNOWLEDGEMENTS

Hack #90 of Perl Hacks L<http://oreilly.com/catalog/9780596526740/>

L<Perl6::Slurp>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Dan Kogai, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
