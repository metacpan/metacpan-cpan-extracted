package Hash::Normalize;

use 5.010;

use strict;
use warnings;

=encoding UTF-8

=head1 NAME

Hash::Normalize - Automatically normalize Unicode hash keys.

=head1 VERSION

Version 0.01

=cut

our $VERSION;
BEGIN {
 $VERSION = '0.01';
}

=head1 SYNOPSIS

    use Hash::Normalize qw<normalize>;

    normalize my %hash, 'NFC';

    $hash{café} = 'coffee'; # NFD, "cafe\x{301}"

    print $hash{café};      # NFD, "cafe\x{301}"
    # 'coffee' is printed

    print $hash{café};      # NFC, "caf\x{e9}"
    # 'coffee' is also printed

=head1 DESCRIPTION

This module provides an utility routine that augments a given Perl hash table so that its keys are automatically normalized following one of the Unicode normalization schemes.
All the following actions on this hash will be made regardless of how the key used for the action is normalized.

Since this module does not use the C<tie> mechanism, normalized hashes are indistinguishable from regular hashes as far as Perl is concerned, but this module also provides L</get_normalization> to identify them if necessary.

=cut

use Variable::Magic;
use Unicode::Normalize ();

=head1 FUNCTIONS

=head2 C<normalize>

    normalize %hash;
    normalize %hash, $mode;

Applies the Unicode normalization scheme C<$mode> onto C<%hash>.
C<$mode> defaults to C<'NFC'> if omitted, and should match C</^(?:(?:nf)?k?|fc)[cd]$/i> otherwise.

C<normalize> will first try to forcefully normalize the existing keys in C<%hash> to the new mode, but it will throw an exception if there are distinct keys that have the same normalization.
All the keys subsequently used for fetches, stores, exists, deletes and list assignments are then first passed through the according normalization procedure.
C<keys %hash> will also return the list of normalized keys.

=cut

sub _remap { $_[2] = Unicode::Normalize::normalize($_[1], "$_[2]"); undef }

my $wiz = Variable::Magic::wizard(
 data     => sub { $_[1] },
 fetch    => \&_remap,
 store    => \&_remap,
 exists   => \&_remap,
 delete   => \&_remap,
 copy_key => 1,
);

sub _validate_mode {
 my $mode = shift;

 $mode = 'nfc' unless defined $mode;
 if ($mode =~ /^(?:nf)?(k?[cd])$/i) {
  $mode = uc "NF$1";
 } elsif ($mode =~ /^(fc[cd])$/i) {
  $mode = uc "$1";
 } else {
  require Carp;
  Carp::croak('Invalid normalization');
 }

 return $mode
}

sub normalize (\%;$) {
 my ($hash, $mode) = @_;

 my $previous_mode = &get_normalization($hash);
 my $new_mode      = _validate_mode($mode);
 return $hash if defined $previous_mode and $previous_mode eq $new_mode;

 &Variable::Magic::dispell($hash, $wiz);

 if (%$hash) {
  my %dup;
  for my $key (keys %$hash) {
   my $norm = Unicode::Normalize::normalize($new_mode, $key);
   if (exists $dup{$norm}) {
    require Carp;
    Carp::croak('Key collision after normalization');
   }
   $dup{$norm} = $hash->{$key};
  }
  %$hash = %dup;
 }

 &Variable::Magic::cast($hash, $wiz, $new_mode);

 return $hash;
}

=head2 C<get_normalization>

    my $mode = get_normalization %hash;
    normalize %hash, $mode;

Returns the current Unicode normalization scheme in use for C<%hash>, or C<undef> if it is a plain hash.

=cut

sub get_normalization (\%) { &Variable::Magic::getdata($_[0], $wiz) }

=head1 NORMALIZED SYMBOL LOOKUPS

Stashes (Perl symbol tables) are implemented as plain hashes, therefore one can use C<normalize %Pkg::> on them to make sure that Unicode symbol lookups are made regardless of normalization.

    package Foo;

    BEGIN {
     require Hash::Normalize;
     # Enforce NFC normalization
     Hash::Normalize::normalize(%Foo::, 'NFC')
    }

    sub café { # NFD, "cafe\x{301}"
     return 'coffee'
    }

    sub coffee_nfc {
     café() # NFC, "cafe\x{e9}"
    }

    sub coffee_nfd {
     café() # NFD, "cafe\x{301}"
    }

    # Both coffee_nfc() and coffee_nfd() return 'coffee'

=head1 CAVEATS

Using a normalized hash is slightly slower than a plain hash, due to the normalization procedure and the overhead of magic.

If a hash is initialized from a normalized hash by list assignment (C<%new = %normalized>), then the normalization scheme will not be carried over to the new hash, although its keys will initially be normalized like the ones from the original hash.

=head1 EXPORT

The functions L</normalize> and L</get_normalization> are only exported on request by specifying their names in the module import list.

=cut

use base 'Exporter';

our @EXPORT      = ();
our %EXPORT_TAGS = ();
our @EXPORT_OK   = qw<normalize get_normalization>;

=head1 DEPENDENCIES

L<perl> 5.10.

L<Carp>, L<Exporter> (core since perl 5).

L<Unicode::Normalize> (core since perl 5.8).

L<Variable::Magic> 0.51.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-hash-normalize at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hash-Normalize>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hash::Normalize

=head1 COPYRIGHT & LICENSE

Copyright 2017 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of Hash::Normalize
