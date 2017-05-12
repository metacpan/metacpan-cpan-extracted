package MP3::Album::Layout::Fetcher;

use strict;
use Data::Dumper;
use MP3::Album::Layout;

@__PACKAGE__::FETCHERS = ();
my $myname = __PACKAGE__;
my $me = $myname;
$me =~ s/\:\:/\//g;

foreach my $d (@INC) {
   chomp $d;
   if (-d "$d/$me/") { 
       local(*F_DIR);
       opendir(*F_DIR, "$d/$me/");
       while ( my $b = readdir(*F_DIR)) {
	       next unless $b =~ /^(.*)\.pm$/; 
	       push @__PACKAGE__::FETCHERS, $1;
       }
   }
}


sub available_fetchers {
  return wantarray ? @__PACKAGE__::FETCHERS : \@__PACKAGE__::FETCHERS;
}

sub fetch {
   my $c = shift;
   my %a = @_;

   unless ($a{album} && ( ref($a{album}) eq 'MP3::Album') ) {
   	$@ = "Need a MP3::Album";
	return undef;
   }
   unless ( grep /^$a{method}$/, @__PACKAGE__::FETCHERS ) {
	$@ = "Need a valid method to use (".join(',',@__PACKAGE__::FETCHERS).")";
	return undef;
   }

   my $fetcher = __PACKAGE__."::$a{method}";
   eval "require $fetcher";
   if ($@) { 
	return undef;
   }

   my $f = $fetcher->fetch(%a);

   return undef unless $f;

   return wantarray ? @$f : $f;
}

1;

=head1 NAME

MP3::Album::Layout::Fetcher - Perl extension to manage fetchers of album layouts.

=head1 DESCRIPTION

This module is a fetcher manager. It searches for modules in the MP3::Album::Layout::Fetcher::* name space and registers them as available fetchers.

The fetcher modules are called by MP3::Album::Layout::Fetcher and they return lists of album layouts (MP3::Album::Layout).

This module calls the respective Fetcher->fetch() method and returns the result.

In case of error the Fetchers must return undef with the error description in $@.

The fetcher selection is made by the "method" parameter passed to the fetch() of this module.

The value of the "method" parameter must be a * part of the MP3::Album::Layout::Fetcher::* fetcher package name. (i.e. for MP3::Album::Layout::Fetcher::CDDB the method is CDDB).

=head1 BUGS

There are no known bugs, if catch one please let me know.

=head1 CONTACT AND COPYRIGHT

Copyright 2003 Bruno Tavares <bmavt@cpan.org>. All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
