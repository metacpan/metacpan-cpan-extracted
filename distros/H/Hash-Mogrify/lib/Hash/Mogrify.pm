package Hash::Mogrify;

use 5.006;
use strict;
use warnings;

=head1 NAME

Hash::Mogrify - Perl extension for modifying hashes

=head1 SYNOPSIS

  use Hash::Mogrify qw(kmap vmap hmap);
   # or :all
  or
  use Hash::Mogrify qw(kmap vmap hmap :force :nowarning :dieonerror);
   # to set global bitmaps
  or 
  use Hash::Mogrify qw(:all :const);
    # also get constants for setting local bitmaps.

  my %hash = ( foo  => 'bar',
               quuz => 'quux',
               bla  => 'bulb',);

  my %newhash     = kmap { $_ =~ s/foo/food/ } %hash;
  my $newhashref  = vmap { $_ =~ s/bulb/burp/ } %hash;
  my $samehashref = hmap { $_[0] =~ s/foo/food/; $_[1] =~ s/bulb/burp/ } \%hash;

  ## setting local bitmaps
  my %newhash     = kmap { $_ =~ s/foo/food/ } %hash, NOWARNING | FORCE;
  # to enable nowarning and force for this action.

  kmap { $_ =~ s/foo/food/ } \%hash, DIEONERR
  # to let kmap die on error.

  ktrans { foo => 'food' }, \%hash;
 # Change key foo into key food.
      
=head1 DESCRIPTION

Hash::Mogrify contains functions for changes parts of hashes, change/mogrify it's keys or it's values.

The functions are flexible in design.
The functions kmap, vmap and hmap return a hash/list in list context and a hash-reference in scalar context.
The first argument to these functions is a code block to mogrify the hash, the second either a hash or a hashref.

If a hash(list) is provided as an argument a new hash is created. When a hash-reference (e.a \%hash) is provided the original hash is changed.

The function ktrans works similar to kmap, except that it takes a hashref as translation table instead of a codeblock.

By default no function overwrites existing keys and warns about this when trying. 
this can be changed by setting the global or local bitmap.
The global bitmap can be set on load by the following keys:
  :nowarning  # do not warn about errors
  :dieonerror # die incase you're trying to override an existing key
  :force      # override existing keys (overrrides :dieonerror).
The local bitmap can be set by adding to the end of the function, there are the following constants:
  NOWARNING
  FORCE
  DIEONERR
The local bitmap will completely override the global bitmap.

More options might be provided in later versions.

=head2 EXPORT

None by default.

=cut 

use vars qw(@ISA %EXPORT_TAGS @EXPORT_OK @EXPORT $VERSION $GLOBALMAP);
require Exporter;

@ISA = qw(Exporter);

%EXPORT_TAGS = ( 
    'all' => [ qw(
        hmap
        kmap
        vmap
        ktrans
    ) ],
    'const'    => [ qw(
        FORCE
        NOWARNING
        DIEONERR
    ) ],
    nowarning  => [],
    force      => [],
    dieonerror => [],);

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} }, @{ $EXPORT_TAGS{'const'} });

@EXPORT = ();

$VERSION = '0.03';

sub FORCE()     { 1; }
sub NOWARNING() { 2; }
sub DIEONERR()  { 4; }

$GLOBALMAP = 0;

sub import {
    $GLOBALMAP |= FORCE     if(grep /:force/, @_);
    $GLOBALMAP |= NOWARNING if(grep /:nowarning/, @_);
    $GLOBALMAP |= DIEONERR  if(grep /:dieonerror/, @_);
    Hash::Mogrify->export_to_level(1, @_);
}

sub kmap(&@) {
    my $code = shift;
    my $hash = $_[0];
    my $bitmap;
    if(!ref $hash) {
        $bitmap = shift if((scalar @_) % 2);
        $hash = { @_ };
    }

    my $temp;
    for (keys %{$hash}) {
        my $value = $hash->{$_};
        $code->($_, $value);
        _double($temp, $_, $bitmap) or return;
        $temp->{$_} = $value;
    }
    %{$hash} = %{$temp};

    return %{$hash} if(wantarray);
    return $hash;
}

sub vmap(&@) {
    my $code = shift;
    my $hash = $_[0];
    my $bitmap; # we don't use this, but maybe once :)
    if(!ref $hash) {
        $bitmap = shift if((scalar @_) % 2);
        $hash = { @_ };
    }

    my $temp;
    for my $key (keys(%{ $hash })) {
        $_ = $hash->{$key};
        $code->($key, $_);
        $temp->{$key} = $_;
    }
    %{$hash} = %{$temp};

    return %{$hash} if(wantarray);
    return $hash;
}

sub hmap(&@) {
    my $code = shift;
    my $hash = $_[0];
    my $bitmap;
    if(!ref $hash) {
        $bitmap = shift if(@_ % 2);
        $hash = { @_ };
    }

    my $temp;
    for my $key (keys(%{ $hash })) {
        my $value = $hash->{$key};
        $code->($key, $value);
        _double($temp, $key, $bitmap) or return;
        $temp->{$key} = $value;
    }
    %{$hash} = %{$temp};

    return %{$hash} if(wantarray);
    return $hash;
}

sub ktrans($@) {
    my $table = shift;
    my $hash = $_[0];

    my $bitmap;
    if(!ref $hash) {
        $bitmap = shift if(@_ % 2);
        $hash = { @_ };
    }

    my $temp = { %{$hash} };
    for my $old (keys(%{ $table })) { 
        next if(!exists $temp->{$old});
        my $new = $table->{$old};

        _double($temp, $new, $bitmap) or return;

        my $value = $temp->{$old};
        delete $temp->{$old};
        $temp->{$new} = $value;
    }
    %{$hash} = %{$temp};

    return %{$hash} if(wantarray);
    return $hash;
}

# check if a hashkey exists, and act depending on global&local settings
sub _double {
    my ($hash, $key, $bitmap) = @_;
    my $map = defined($bitmap) ? $bitmap : $GLOBALMAP;

    return 1 if(!exists $hash->{$key});
    if(!($map & NOWARNING)) {
        warn('Attempting to override existing key, failing.') if(!$map & FORCE);
        warn('Attempting to override existing key, forcing.') if($map & FORCE);
    }
    return 1 if($map & FORCE);
    die 'Died, trying to override existing key' if($map & DIEONERR);
    return;
}
1;
__END__


=head1 SEE ALSO

L<Util::List>, L<Hash::Util>, L<Hash::MoreUtils>, L<Hash::Transform>, L<Hash::Rename>

=head1 AUTHOR

Sebastian Stellingwerff, E<lt>cpan@web.expr42.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Sebastian Stellingwerff

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
