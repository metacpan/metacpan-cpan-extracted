package Mac::SysProfile;

use strict;
use warnings;

use Mac::PropertyList ();
use Scalar::Util      ();

our $VERSION = '0.05';

my %conf = (
    'bin' => 'system_profiler',
    'lst' => '-listDataTypes',
    'sfw' => 'SPSoftwareDataType',
    'sfx' => 'os_overview',
    'osx' => 'os_version',
    'drw' => 'kernel_version',
    'xml' => '-xml',
);

my %types;

sub new { bless {}, shift }

sub types {
    my $pro = shift;
    for (`$conf{bin} $conf{lst}`) {
        next if m/:/;
        chomp;
        $pro->{$_} = undef unless exists $pro->{$_};
        $types{$_} = 1;
    }
    return [ keys %types ];
}

sub gettype {
    my ( $pro, $typ, $fre ) = @_;

    $pro->types() unless exists $types{$typ};

    if ( !exists $types{$typ} ) {
        delete $pro->{$typ};
        return;
    }

    return $pro->{$typ} if $pro->{$typ} && !$fre;

    my $data  = Mac::PropertyList::parse_plist( $pro->xml($typ) );
    my $items = $data->[0]{_items};

    # Workaround for types that have multiples (e.g. SPMemoryDataType)
    if ( defined $items->[0] && exists $items->[0]{'_items'} ) {
        $items = $items->[0]{'_items'};
    }

    my $hdr;
    foreach my $item ( @{$items} ) {
        my $res;

        my $name = '';

        # not used to keep from making the already complex structure arbitrarily more complex
        # would also need done in _structify_val()
        # my $name = delete $item->{'_name'} || '';
        #         if ( ref($name) ) {
        #             $name = $name->value();
        # }

        while ( my ( $key, $value ) = each %{$item} ) {
            my $val = $value->value();
            my $end_val;

            if ( ref($val) ) {
                $end_val = $val->value();
            }
            else {
                $end_val = $val;
            }

            if ($name) {
                $res->{$name}{$key} = _structify_val($end_val);
            }
            else {
                $res->{$key} = _structify_val($end_val);
            }
        }

        push @{ $pro->{$typ} }, $res;
    }

    $pro->{$typ} ||= [];

    return $pro->{$typ};
}

# recursive fixer upper: Storable::dclone() does not do it, Mac::PropertyList::plist_as_perl() does not seem to work-patches welcome!
sub _structify_val {
    my ($val) = @_;
    my $ref = Scalar::Util::reftype($val);
    return $val if !$ref;
    if ( $ref eq 'ARRAY' ) {
        my @arr;
        for my $item ( @{$val} ) {
            push @arr, _structify_val($item);
        }
        return \@arr;
    }
    elsif ( $ref eq 'SCALAR' ) {
        return $val->value();
    }
    elsif ( $ref eq 'HASH' ) {
        my %hsh;
        while ( my ( $k, $v ) = each %{$val} ) {
            $hsh{$k} = _structify_val($v);
        }
        return \%hsh;
    }
    else {
        die "Do not know $ref";
    }
}

sub osx {
    my $pro = shift;
    my $fre = shift || '';
    return $pro->{_osx_version} if $pro->{_osx} && !$fre;
    $pro->gettype( $conf{sfw}, $fre );
    ( $pro->{_osx_version} ) = $pro->{ $conf{sfw} }->{ $conf{sfx} }->{ $conf{osx} } =~ m/\s(\d+(\.\d+)*)\D/;
    return $pro->{_osx_version};
}

sub darwin {
    my $pro = shift;
    my $fre = shift || '';
    return $pro->{_darwin_version} if $pro->{_darwin_version} && !$fre;
    $pro->gettype( $conf{sfw}, $fre );
    ( $pro->{_darwin_version} ) = $pro->{ $conf{sfw} }->{ $conf{sfx} }->{ $conf{drw} } =~ m/\s(\d+(\.\d+)*)\D/;
    return $pro->{_darwin_version};
}

sub state_hashref {
    my $pro = shift;
    my %x   = %{$pro};
    return \%x;
}

sub xml {
    my $pro = shift;
    my $key = shift;
    my $fh  = shift || '';
    my $raw = exists $types{$key} ? `$conf{'bin'} $conf{'xml'} $key` : undef;
    print $fh $raw if ref $fh eq 'GLOB' && defined $raw;
    if ( $fh && !ref $fh ) {
        open XML, ">$fh" or return;
        print XML $raw;
        close XML;
    }
    return $raw;
}

1;

__END__

=head1 NAME

Mac::SysProfile - Perl extension for OS X system_profiler

=head1 SYNOPSIS

  use Mac::SysProfile;
  my $pro = Mac::SysProfile->new(); 
  print 'OS X Version ' . $pro->osx() . "\n";
  print 'Darwin Version ' . $pro->darwin() . "\n";

=head1 DESCRIPTION

OO interface to your Mac's system_profiler

=head1 METHODS

=head2 $pro->types() 

Returns an array ref of the datatypes available  use for $pro->gettype()

=head2 $pro->gettype()

Returns a data structure of the given type's data.

  my $soft = $pro->gettype('SPSoftwareDataType');

Once you call it for a type it returns the cached data on the next call unless the second argument is true.

  my $soft = $pro->gettype('SPSoftwareDataType',1);

The data structure is an array ref of hashes. These hashes can be arbitrarily complex. 

A hash at any point in that structure may or may not have a '_name' key. It is left in place to keep from making the already complex structure arbitrarily more complex.

Use it or ignore it as appropriate to your needs.

=head2 $pro->osx()

Returns the system's OSX version. The first time it is called it finds it and stores it in the object for less overhead:

  if($pro->osx() eq '10.3.9') { # initially finds it
     print 'Do you want to upgrade from ' . $pro->osx() . "\n"; # already processed so it returns the cached value (IE Fast)
  } 
  print 'Your current version is: ' . $por->osx() . "\n";  # already processed so it returns the cached value (IE Fast)

You can make it reprocess and find it again fresh by giving it a true value:

  if($pro->osx() eq '10.3.9') { # initially finds it
     print 'Do you want to upgrade from ' . $pro->osx(1) . "\n"; # finds it again from scratch instead of the cached value (IE slower)
  } 
  print 'Your current version is: ' . $por->osx(1) . "\n";  # finds it again from scratch instead of the cached value (IE slower)

=head2 $pro->darwin()

Same useage as $pro->osx() but returns the version of the system's Darwin.

=head2 $pro->state_hashref()

Returns a hashref of the entire object so far. Anything that has not been called it undef.

=head2 $pro->xml()

Returns an xml document of the type specified. An optional file handle or file to write the output to can be specified as the second argument.
If you put it in a file that has a .spx extension then it will be an XML file which can be opened by System Profiler.app

  my $raw = $pro->xml('SPSoftwareDataType');
  $pro->xml('SPSoftwareDataType','./software.spx') or die "Could not create xml file: $!";
  $pro->xml('SPSoftwareDataType',\*FH);

=head1 SAMPLE

  # create xml files for each type in ./10.3.9/
  use Mac::SysProfile;
  my $pro = Mac::SysProfile->new();
  mkdir $pro->osx() or die "Could not mkdir: $!" if !-d $pro->osx();
  for(@{ $pro->types() }) {
     $pro->xml($_, $pro->osx() . "/$_.spx") or warn "$_.spx failed: $!";
  }

=head1 Pre v0.04 caveat

The data structure format is changed in 0.04 since parsing the non-XML output reliably is impossible (but seems to work fine at first glance).

=head1 MISC

It doesn't currently use the "detailLevel" option.

=head1 AUTHOR

Daniel Muey, L<http://drmuey.com/cpan_contact.pl>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Daniel Muey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
