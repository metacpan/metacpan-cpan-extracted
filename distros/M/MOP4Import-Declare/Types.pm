package MOP4Import::Types;
use 5.010;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;

use MOP4Import::Pairs -as_base, qw/Opts/;
use MOP4Import::Declare::Type -as_base;

use constant DEBUG => $ENV{DEBUG_MOP4IMPORT};

sub import {
  my $myPack = shift;

  my Opts $opts = Opts->new([caller])->take_hash_maybe(\@_);

  $myPack->dispatch_pairs_as(type => $opts, $opts->{destpkg}, @_);
}

1;

__END__

=head1 NAME

MOP4Import::Types - create multiple inner-classes at once.

=head1 SYNOPSIS

Create inner-classes C<MyApp::Artist> and C<MyApp::CD>
using L<MOP4Import::Types>.

  package MyApp;
  use MOP4Import::Types
    (Artist => [[fields => qw/artistid name/]]
     , CD   => [[fields => qw/cdid artistid title year/]]);

Then you can use above types like following with static checking of L<fields>.

  sub print_artist_cds {
    (my $self, my Artist $artist) = @_;
    my @cds = $self->DB->select(CD => {artistid => $artist->{artistid}});
    foreach my CD $cd (@cds) {
      print tsv($cd->{title}, $cd->{year}), "\n";
    }
  }

=head1 DESCRIPTION

MOP4Import::Types is yet another protocol implementation
of L<MOP4Import|MOP4Import::Intro> family.

In contrast to MOP4Import::Declare, which is designed to
modify target module itself,
this module is designed to add new inner-classes to target module.

With "inner-class", I mean class declared in some module
and not directly exposed as "require" able module.

=head2 "MetaObject Protocol for Import" in this module

C<import()> method of MOP4Import::Types briefly does following:

  sub import {
    my ($myPack, @pairs) = @_;
  
    my $callpack = caller;
    my $opts = +{};
  
    while (my ($typename, $pragma_list) = splice @pairs, 0, 2) {
  
      my $innerClass = join("::", $callpack, $typename);
  
      $myPack->declare___type($opts, $callpack, $typename, $innerClass);
  
    }
  }
