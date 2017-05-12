package Lib::ModuleSymbol;
# $Id: ModuleSymbol.pm,v 1.7 2004/03/28 00:27:53 kiesling Exp $

# Copyright © 2001-2004 Robert Kiesling, rkies@cpan.org.
#
# Licensed under the same terms as Perl.  Refer to the file,
# "Artistic," for information.

$VERSION=0.54;
use vars qw( @ISA @EXPORT @EXPORT_OK $VERSION );
push @ISA, qw( Exporter DB );

sub new {
  my $proto = shift;
  my $class = ref( $proto ) || $proto;
  my $self = {
	      pathname => undef,
	      packagename => undef,
	      version => undef,
	      };
  bless( $self, $class);
  return $self;

}

my @scannedpackages;

sub scannedpackages {
  if( @_ ) { @scannedpackages = @_ }
  return @scannedpackages;
}

sub array_as_str {
    my @a = $_[0];
    return (join ("\n", @a));
}

sub text_symbols {
    my $p = shift;
    my (@text) = @_;
    my $text = array_as_str (@text);
    my (@ver) = grep /VERSION.*\=/, @text;
    my ($package) = ($text =~ /^package\s+(.*?)\;/ms);
    $p -> {packagename} = $package if $package;
    $p -> {version} = $ver[0];
}

sub pathname {
    my $self = shift;
    if (@_) { $self -> {pathname} = shift; }
    return $self -> {pathname}
}

sub packagename {
    my $self = shift;
    if (@_) { $self -> {packagename} = shift; }
    return $self -> {packagename}
}

sub version {
    my $self = shift;
    if (@_) { $self -> {version} = shift; }
    return $self -> {version}
}


1;

