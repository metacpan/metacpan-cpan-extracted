package Getopt::Yath::Util;
use strict;
use warnings;

use Carp qw/confess longmess croak/;
use Cpanel::JSON::XS();
use Importer Importer => 'import';
use File::Temp qw/ tempfile /;

our $VERSION = '2.000007';

our @EXPORT_OK = qw{
    decode_json
    encode_json
    encode_json_file
    decode_json_file

    fqmod
    mod2file
};

my $json   = Cpanel::JSON::XS->new->utf8(1)->convert_blessed(1)->allow_nonref(1);
my $ascii  = Cpanel::JSON::XS->new->ascii(1)->convert_blessed(1)->allow_nonref(1);

sub decode_json { my $out; eval { $out = $json->decode(@_);   1} // confess($@); $out }
sub encode_json { my $out; eval { $out = $ascii->encode(@_);  1} // confess($@); $out }

sub encode_json_file {
    my ($data) = @_;
    my $json = encode_json($data);

    my ($fh, $file) = tempfile("$$-XXXXXX", TMPDIR => 1, SUFFIX => '.json', UNLINK => 0);
    print $fh $json;
    close($fh);

    return $file;
}

sub decode_json_file {
    my ($file, %params) = @_;

    open(my $fh, '<', $file) or die "Could not open '$file': $!";
    my $json = do { local $/; <$fh> };

    if ($params{unlink}) {
        unlink($file) or warn "Could not unlink '$file': $!";
    }

    return decode_json($json);
}

sub mod2file {
    my ($mod) = @_;
    confess "No module name provided" unless $mod;
    my $file = $mod;
    $file =~ s{::}{/}g;
    $file .= ".pm";
    return $file;
}

sub fqmod {
    my ($input, $prefixes, %options) = @_;

    croak "At least 1 prefix is required" unless $prefixes;

    $prefixes = [$prefixes] unless ref($prefixes) eq 'ARRAY';

    croak "At least 1 prefix is required" unless @$prefixes;
    croak "Cannot use no_require when providing multiple prefixes" if $options{no_require} && @$prefixes > 1;

    if ($input =~ m/^\+(.*)$/) {
        my $mod = $1;
        return $mod if $options{no_require};
        return $mod if eval { require(mod2file($mod)); 1 };
        confess($@);
    }

    my %tried;
    for my $pre (@$prefixes) {
        my $mod = $input =~ m/^\Q$pre\E/ ? $input : "$pre\::$input";

        if ($options{no_require}) {
            return $mod;
        }
        else {
            return $mod if eval { require(mod2file($mod)); 1 };
            ($tried{$mod}) = split /\n/, $@;
            $tried{$mod} =~ s{^(Can't locate \S+ in \@INC).*$}{$1.};
        }
    }

    my @caller = caller;

    die "Could not locate a module matching '$input' at $caller[1] line $caller[2], the following were checked:\n" . join("\n", map { " * $_: $tried{$_}" } sort keys %tried) . "\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Getopt::Yath::Util - Utility functions for L<Getopt::Yath>

=head1 DESCRIPTION

Collection of utility functions for Getopt::Yath.

=head1 SYNOPSIS

    use Getopt::Yath qw{
        fqmod
        mod2file
        decode_json
        encode_json
        encode_json_file
        decode_json_file
    };

=head1 EXPORTS

=over 4

=item $module = fqmod($name, $prefix)

=item $module = fqmod($name, $prefix, no_require => $BOOL)

=item $module = fqmod($name, \@prefixes)

=item $module = fqmod($name, \@prefixes, no_require => $BOOL)

Look for a module named "${prefix}::${name}" for each provided prefix. Will
returns the first one it finds that can be loaded. If C<< no_require => 1 >> is
provided it will not attempt to load any and will usually just return using the
first prefix.

If $name starts with a '+' then it is assumed to already be a fully qualified
module name and the module name will be returned with the '+' removed.

If $name starts with one of the prefixes, no prefix will be added and the
original $name will be returned.

This function will throw an exception if it cannot find a valid module.

=item $file = mod2file($module)

Convert a module name to a filename.

=item $data = decode_json($json)

Decode a json string to perl data.

=item $json = encode_json($data)

Encode perl data into a json string using only ascii characters.

=item $file = encode_json_file($data)

Encode the data to a json file. A new tempfile filename is returend.

=item $data = decode_json_file($path)

Decode json from specified filename.

=back

=head1 SOURCE

The source code repository for Getopt-Yath can be found at
L<http://github.com/Test-More/Getopt-Yath/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut
