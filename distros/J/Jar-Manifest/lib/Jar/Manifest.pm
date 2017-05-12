package Jar::Manifest;

#######################
# LOAD MODULES
#######################
use strict;
use warnings FATAL => 'all';
use Carp qw(croak carp);

#######################
# VERSION
#######################
our $VERSION = '1.0.1';

#######################
# EXPORT
#######################
use base qw(Exporter);
our (@EXPORT_OK);
@EXPORT_OK = qw(Dump Load);

#######################
# LOAD CPAN MODULES
#######################
use Encode qw();
use Text::Wrap qw();

#######################
# READ MANIFEST
#######################
sub Load {
    my $manifest = {
        main    => {},  # Main Attributes
        entries => [],  # Manifest entries
    };

    foreach my $para ( _split_to_paras(@_) ) {
        my $isa_entry = 0;
        my %h;
        $isa_entry = 1
          if ( lc( ( split( /\n+/, $para ) )[0] ) =~ m{^\s*name}xi );

        foreach my $line ( split( /\n+/, $para ) ) {

          next unless ( $line =~ m{.+:.+} );
            my ( $k, $v ) = map { _trim($_) } split( /\s*:\s+/, $line );
          next unless ( defined $k and defined $v );
          next if ( ( $k =~ m{^\s*$} ) or ( $v =~ m{^\s*$} ) );
            if ( defined $h{$k} ) {

                # Attribute names cannot be repeated within a section
                croak "Found duplicate attribute: $k\n";
            } ## end if ( defined $h{$k} )

            $h{$k} = $v;
        } ## end foreach my $line ( split( /\n+/...))

        if ($isa_entry) {
            push @{ $manifest->{entries} }, \%h;
        }
        else {
            $manifest->{main} = { %{ $manifest->{main} }, %h };
        }
    } ## end foreach my $para ( _split_to_paras...)

  return $manifest;
} ## end sub Load

#######################
# WRITE MANIFEST
#######################
sub Dump {
    my ($in) = @_;
    croak "Hash ref expected" unless ( ref $in eq 'HASH' );

    my $manifest = {
        main    => $in->{main}    || {},
        entries => $in->{entries} || [],
    };

    my $str = q();

    # Manifest-Version is required!
    if ( not defined $manifest->{main}->{'Manifest-Version'} ) {
        croak "Manifest-Version is not provided!\n";
    }

    # Process Main
    foreach my $main_attr ( _sort_attr( keys %{ $manifest->{main} } ) ) {
        $main_attr = _trim($main_attr);
        _validate_attr($main_attr);
        $str
          .= _wrap_line(
            "${main_attr}: " . _clean_val( $manifest->{main}->{$main_attr} ) )
          . "\n";
    } ## end foreach my $main_attr ( _sort_attr...)

    # Process entries
    foreach my $entry ( @{ $manifest->{entries} } ) {

        # Get Name
        my ($name_attr) = grep { /^name$/xi } keys %{$entry};
        $name_attr = _trim($name_attr);
        $name_attr || croak "Missing 'Name' attribute in entry";
        _validate_attr($name_attr);
        $str
          .= "\n"
          . _wrap_line(
            "${name_attr}: " . _clean_val( $entry->{$name_attr} ) )
          . "\n";

        # Process others
        foreach my $entry_attr (
            _sort_attr( grep { !/$name_attr/ } keys %{$entry} ) )
        {
            $entry_attr = _trim($entry_attr);
            _validate_attr($entry_attr);
            $str
              .= _wrap_line(
                "${entry_attr}: " . _clean_val( $entry->{$entry_attr} ) )
              . "\n";
        } ## end foreach my $entry_attr ( _sort_attr...)
    } ## end foreach my $entry ( @{ $manifest...})

    # Append 2 new lines at EOF
    $str .= "\n\n";

    # Done
  return $str;
} ## end sub Dump

#######################
# INTERNAL HELPERS
#######################

# Split to paragraphs
sub _split_to_paras {
    my $lines = join( '', @_ );
    $lines = _fix_eol($lines);
    my @paras;
    foreach (
        split(
            /(?:\n\s*){2,}/,  # Two or more new lines
            $lines
        )
      )
    {
        $_ =~ s{\n+}{\n}gx;   # Consolidate new lines
        $_ =~ s{\n\s}{}gx;    # Join multiline values
        push @paras, $_;      # Save
    } ## end foreach ( split( /(?:\n\s*){2,}/...))
  return @paras;
} ## end sub _split_to_paras

# Trim
sub _trim {
    my ($val) = @_;
  return unless defined $val;
    $val =~ s{^\s+}{}xi;
    $val =~ s{\s+$}{}xi;
  return $val;
} ## end sub _trim

# Correct EOL
sub _fix_eol {
    my ($val) = @_;
  return unless defined $val;
    $val =~ s{\r\n}{\n}mgxi;
  return $val;
} ## end sub _fix_eol

# Validate Attribute
sub _validate_attr {
    my ($attr) = @_;

    croak
      "Attributes can contain only alphanumeric, '-' or '_' characters : $attr"
      unless ( $attr =~ m{^[-0-9a-zA-Z_]+$} );

    croak "Attribute must contain at least one alphanumeric character : $attr"
      unless ( $attr =~ m{[a-zA-Z0-9]+} );

    croak "Attribute length exceeds allowed value of 70 : $attr"
      if ( length($attr) > 70 );

  return 1;
} ## end sub _validate_attr

# Clean Value
sub _clean_val {
    my ($val) = @_;

    # Get rid of line breaks
    $val = _fix_eol($val);
    $val =~ s{\n}{}gix;

    # Trim
    $val = _trim($val);

    # Return encoded
  return Encode::encode_utf8($val);
} ## end sub _clean_val

# Sort Attributes
sub _sort_attr {
    my @attr = @_;
    @attr = sort {
        ( grep { /-/ } $a ) <=> ( grep { /-/ } $b )
          || lc($a) cmp lc($b)
    } @attr;

    # Manifest-Version must be first, and in exactly that case
    my @order;
    push @order, grep { /Manifest\-Version/ } @attr;
    push @order, grep { !/Manifest\-Version/ } @attr;
  return @order;
} ## end sub _sort_attr

# Wrap Line
sub _wrap_line {

    # Wrap settings
    $Text::Wrap::unexpand = 0;
    $Text::Wrap::tabstop  = 4;
    $Text::Wrap::columns  = 72;
    $Text::Wrap::break    = '';
    $Text::Wrap::huge     = 'wrap';

    # Wrap
  return Text::Wrap::wrap( "", " ", @_ );
} ## end sub _wrap_line

#######################
1;

__END__

#######################
# POD SECTION
#######################
=pod

=head1 NAME

Jar::Manifest - Read and Write Java Jar Manifests

=head1 SYNOPSIS

    use Jar::Manifest qw(Dump Load);

    # Read a Manifest
    my $manifest_str = <<"MANIFEST";
    Manifest-Version: 1.0
    Created-By: 1.5.0_11-b03 (Sun Microsystems Inc.)
    Built-By: JAPH

    Name: org/myapp/foo/
    Implementation-Title: Test Java JAR
    Implementation-Version: 1.9
    Implementation-Vendor: JAPH

    MANIFEST

    my $manifest = Load($manifest_str);
    printf( "Jar built by -> %s\n", $manifest->{main}->{'Built-By'} );
    printf(
        "Name: %s\nVersion: %s\n",
        $_->{Name}, $_->{'Implementation-Version'}
        )
        for @{ $manifest->{entries} };

    # Write a manifest
    my $manifest = {

        # Main attributes
        main => {
            'Manifest-Version' => '1.0',
            'Created-By'       => '1.5.0_11-b03 (Sun Microsystems Inc.)',
            'Built-By'         => 'JAPH',
        },

        # Entries
        entries => [
            {
                'Name'                   => 'org/myapp/foo/',
                'Implementation-Title'   => 'Test Java JAR',
                'Implementation-Version' => '1.9',
                'Implementation-Vendor'  => 'JAPH',
            }
        ],
    };
    my $manifest_string = Dump($manifest);

=head1 DESCRIPTION

C<Jar::Manifest> provides a perl interface to read and write Manifest
files found within Java archives - typically C<META-INF/MANIFEST.MF>
within a C<.jar> file.

The Jar Manifest specification can be found here
L<http://docs.oracle.com/javase/7/docs/technotes/guides/jar/jar.html#JAR_Manifest>

=head1 METHODS

=over

=item Load($string)

    use Jar::Manifest qw(Load);
    use Data::Dumper;

    my $manifest = Load($string);
    print Dumper $manifest;

Read the manifest contents in C<$string>. Returns a I<hash-reference>
containing two keys. The I<main> key is another hash-reference to the
main attributes and corresponding values. The I<entries> key is an
array-ref of hashes containing per-entry attributes and the
corresponding values

=item Dump($manifest)

    print Dump($manifest);

Turns the C<$manifest> data structure into a string that can be printed
to a C<MANIFEST.MF> file. The C<$manifest> structure is expected to be
in the same format as the C<Load()> output.

=back

=head1 DEPENDENCIES

L<Encode>

L<Text::Wrap>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests at
L<https://github.com/mithun/perl-jar-manifest/issues>

=head1 AUTHOR

Mithun Ayachit C<mithun@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2014, Mithun Ayachit. All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>.

=cut
