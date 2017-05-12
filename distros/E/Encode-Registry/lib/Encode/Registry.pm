package Encode::Registry;

use strict;
use XML::Parser::Expat;
use IO::File;
use File::Spec;
use MIME::Base64;
require Exporter;

our $VERSION = 0.05;    #   MJPH    31-JAN-2005     Use Encode for non Win32 default numeric mappings
# our $VERSION = 0.04;    #   MJPH    19-FEB-2004     Map internal mappings to numeric perhaps
# our $VERSION = 0.03;    #   MJPH    19-FEB-2004     Try harder to find a mapping

our @ISA = qw(Exporter);
our @EXPORT = qw(encode decode find_encoding);
our %types;
our %mappings;
our %aliases;
our %fonts;
our %encodings;
our %internal_mappings;
our $base_class = 'Encode';
our $Registry;
our $dontDie;

if ($] > 5.007)
{
    require Encode;
#    import Encode;
}

sub encode($$;$)
{
    my ($name, $str, $check) = @_;
    my ($enc) = find_encoding($name, -check => $check);
    unless ($enc)
    {
        unless ($check)
        { return undef; }
        else
        { die "Unable to load map $name"; }
    }
    return $enc->encode($str, $check);
}

sub decode($$;$)
{
    my ($name, $str, $check) = @_;
    my ($enc) = find_encoding($name, -check => $check);
    unless ($enc)
    {
        unless ($check)
        { return undef; }
        else
        { die "Unable to load map $name"; }
    }
    return $enc->decode($str, $check);
}


sub import
{
    my ($class) = @_;
    my ($regfile, $i);

    for ($i = 0; $i <= $#_; $i++)
    {
        if ($_[$i] eq 'file')
        {
            $regfile = $_[$i+1];
            splice(@_, $i, 2);
            last;
        }
    }
    $regfile ||= $class->find_registry;
    $class->read_file($regfile) if ($regfile);
    internal_mappings();
    return Encode::Registry->export_to_level(1, @_);
}

sub find_registry
{
    my (@path, $p, $file);
    
    if ($^O eq 'MSWin32')
    {
        require Win32::TieRegistry;
        Win32::TieRegistry->import(Delimiter => '/');

        $file = $Registry->{"LMachine/SOFTWARE/SIL/EncodingConverterRepository//Registry"};
        return $file if (-f $file);
    }

    @path = (split(/;\s*/, $ENV{'MAPPINGPATH'}), '~/.SIL/Converters/registry.xml', '/etc/SIL/Converters/registry.xml');     # use environment
    $p = join('', (File::Spec->splitpath($INC{'Encode/Registry.pm'}))[0..1]) . '/REGISTRY.XML';
    push (@path, $p);
    foreach $p (@path)
    { return $p if (-f $p); }
    return undef;
}
        
sub read_file
{
    my ($class, $fname) = @_;
    my ($xml) = XML::Parser::Expat->new();
    my ($curr_plat, $curr_map, $curr_enc, $curr_font, $rev, $base_enc, $enc_isuni);
    
    undef %fonts; undef %aliases; undef %mappings; undef %encodings; undef %types;

    $xml->setHandlers('Start' => sub {
        my ($xml, $tag, %attrs) = @_;
        
        if ($tag eq 'platform')
        { $curr_plat = $attrs{'name'}; }
        elsif ($tag eq 'implement' && $curr_plat eq 'Encode::Registry')
        { $types{$attrs{'type'}} = [$attrs{'use'}, $attrs{'priority'}]; }
        elsif ($tag eq 'mapping')
        { $curr_map = $attrs{'name'}; }
        elsif ($tag eq 'spec')
        { push (@{$mappings{$curr_map}{'specs'}}, [$attrs{'path'}, $attrs{'type'}]); }
        elsif ($tag eq 'fontMapping')
        { 
            $mappings{$curr_map}{'ffonts'}{$attrs{'name'}} = $attrs{'assocFont'};
            $mappings{$curr_map}{'rfonts'}{$attrs{'assocFont'}} = $attrs{'name'} if ($attrs{'assocFont'});
        }
        elsif ($tag eq 'encoding')
        { 
            $curr_enc = $attrs{'name'};
            $enc_isuni = $attrs{'isUnicode'} eq 'true';
        }
        elsif ($tag eq 'defineMapping' && $curr_enc)
        {
            if ($enc_isuni)
            { $base_enc = $attrs{'becomes'}; }
            else
            { $encodings{$curr_enc} = [$attrs{'name'}, $attrs{'reverse'}, $encodings{$curr_enc}[2]]; }
        }
        elsif ($tag eq 'rangeCoverage' && $base_enc && $attrs{'cpg'})
        { $encodings{$base_enc} = [$encodings{$base_enc}[0], $encodings{$base_enc}[1], $attrs{'cpg'}]; }
        elsif ($tag eq 'alias' && $curr_enc)
        { $aliases{$attrs{'name'}} = $curr_enc; }
        elsif ($tag eq 'font')
        { $curr_font = $attrs{'name'}; }
        elsif ($tag eq 'fontEncoding' && $attrs{'unique'} eq 'true')
        { $fonts{$curr_font}{'encoding'} = $attrs{'name'}; }
    },
    'End' => sub {
        my ($xml, $tag) = @_;
        
        if ($tag eq 'platform')
        { $curr_plat = ''; }
        elsif ($tag eq 'mapping')
        { $curr_map = ''; }
        elsif ($tag eq 'encoding')
        { $curr_enc = ''; $base_enc = ''; }
        elsif ($tag eq 'font')
        { $curr_font = ''; }
    },
    'ExternEnt' => sub {
        my ($xml, $base, $sys, $pub) = @_;
        my ($fname) = File::Spec->rel2abs($sys, $base);
        my ($fh) = IO::File->new("> $fname");
        return $fh;
    });

#    $DB::single = 1;
    $xml->parsefile($fname);
    
    foreach $curr_font (keys %fonts)
    {
        next unless (defined $fonts{$curr_font} && defined $encodings{$fonts{$curr_font}{'encoding'}});
        ($curr_map, $rev) = @{$encodings{$fonts{$curr_font}{'encoding'}}};
        $rev = ($rev eq 'true') ? 'r' : 'f';
        $fonts{$curr_font}{'assocFont'} = $mappings{$curr_map}{"${rev}fonts"}{$curr_font}
                if (defined $mappings{$curr_map}{"${rev}fonts"}{$curr_font});
    }

    internal_mappings();
}


sub add_handler
{
    my ($class, $type, $handler, $priority) = @_;

    $types{$type} = [$handler, $priority];
}


sub find_encoding($;$)
{
    my ($name, %opts) = @_;
    my (@h, $h, $res, $enc);

    while (defined $aliases{$name})
    { $name = $aliases{$name}; }

    $enc = $encodings{$name};
    if ($enc)
    {
        @h = (sort {$types{$b->[1]}[1] <=> $types{$a->[1]}[1]} @{$mappings{$enc->[0]}{'specs'}});

        foreach $h (@h)
        {
            my $h1 = $types{$h->[1]}[0];
            my ($h2) = $h1;
            $h1 =~ s|::|/|og;
            if (eval { require "$h1.pm"; })
            {
                $res = "$h2"->new($h->[0], -reverse => ($enc->[0] eq 'true'), %opts);
                return $res;
            }
        }
    }
    elsif ($name =~ m/^[0-9]+$/o)
    {
        if ($^O eq 'MSWin32' and eval { require Encode::Win32; } and $res = Encode::Win32->new($name))
        { return $res; }
        else
        { $name = "cp$name"; }
    }
    return Encode::find_encoding($name) if ($] > 5.007);
    return undef;
}

sub find_font
{
    my ($name, %opts) = @_;
    
    if ($fonts{$name})
    { return ($fonts{$name}{'encoding'}, $fonts{$name}{'assoc_font'}, $encodings{$fonts{$name}{'encoding'}}[2]); }
    else
    { return (undef, undef, undef); }
}    

sub find_encfont
{
    my ($encname, $fname, $dir, %opts) = @_;
    my ($enc, $res);
    my ($ftype) = $dir ? "rfonts" : "ffonts";
    
    while (defined $aliases{$encname})
    { $encname = $aliases{$encname}; }

    $enc = $encodings{$encname};
    if ($enc && defined $mappings{$enc->[0]}{$ftype}{$fname})
    { return $mappings{$enc->[0]}{$ftype}{$fname}; }
    else
    { return undef; }
}

sub internal_mappings
{
    my ($type) = 'SIL.tec.scalar';
    my ($t);
    
#    $DB::single = 1;
    eval "require Encode::TECkit";
    unless ($@)
    {
        foreach $t (keys %internal_mappings)
        {
            my ($dmap, $tp);
            
            if (defined $encodings{$t})
            {
                $dmap = $encodings{$t}[0];
            }
            else
            {
                $dmap = $t;
                $encodings{$t} = [$dmap, 0];
            }
            push (@{$mappings{$dmap}{'specs'}}, [decode_base64($internal_mappings{$t}), $type]);
            $tp = $t;
            $aliases{$tp} = $t if ($tp =~ s/^cp([0-9]+)$/$1/o);
        }
        $types{$type} = ['Encode::Registry::TECkit_Scalar', 3] unless defined $types{$type};

	    package Encode::Registry::TECkit_Scalar;
#        require Encode::TECkit;
        $INC{"Encode/Registry/TECkit_Scalar.pm"} = $INC{"Encode/TECkit"};
        sub new
        {
            my ($class, $str, %opts) = @_;
            return Encode::TECkit->new_scalar($str, %opts);
        }
    }
}

%internal_mappings = (
'cp1252' => <<'EOT'
elFtcAAAE8R4nO3YBZBVZRzG4e9d1i7s1msnumCjIiJ2YWA32IqL3d2J3WJ3d3d3d3eLLaLic+7d
EWdER50xh2/m4e6yy957z9nvf86Pvkuv21qaSkop65Rqpf5nc9tHlbnpxjKs1vi+5n4eh+/V2rHT
HJ18zwg9+2zca4ve65fS7mcfN5d0LN06dOnp51c/sqUMWS2Nz4dI/bkGf9/29ep5q3/Vru21DFc9
HyMwIiMxMqMwKqMxOmPQnjEZi7EZh3EZj/GZgAmZiImZhEmZjMmpMQVTMhVTMw3TMh3TMwMzMhMz
04FZmLXx3kpHOjEbszMHczJX2/Gch87My3zMTxcWoCsLth3zhejOwizCoizG4izBkizF0m3nZ1l6
sBzLswIr0pOVWJlVWLXtXK7OGqzJWqzdOL9lXdajF71xOssGbMhGbMwmbMpmbE4ftqCVvmzJVmzN
NmzLdmzPDuzITuzMLuzKbg7/hR738Oj85AiPzkvNsa85LzXnpeluj45xvM6a45jqfR7isfoZh9HP
3zvHNee45tzWnNuac1nzu1Dzu9D0otPr83iPNecg1TE62aPnT/XaTuU0TucMzuQszuYczuU8zucC
qtd7ERdzCZdyGZdzBVdyFVdzDddyHddzAzdyEzdzC7dyG7dzB3dyF953uYd7uY/7eYAHeYiHeYRH
eYzHeYIneYqneYZneY7neQHHo7zEy7zCq7zG67zBm7zF27zDu7zH+3zAh3zEx3zCAD7lMz7nC77k
K77mGwbyLYP4jmrf/8Dgnh26dGvMizGqfVMt53qUlsbnQzTmhT2cpsG/tdo1/+aX//PLUWgyJZtN
yOFNxxFNxpFNxVFNxNFNw/Ym4Vim4Dgm4Him3wQm30Sm3iQm3mSmXc2km9KUm9qEm9Z0m95km9FU
m9lEm8U0azHJOplis5tgc5pec5tcnU2t+UysLqZVV5OqmynV3YRaxHRazGRawlRaykRaxjTqYRIt
bwqtaAKtZPqsYvKsZuqsYeKsZdqsY9KsZ8r0NmE2MF02Mlk2MVU2M1H6mCatJsmWpsjWJsi2psf2
JseOpsbOJsaupsXujVkx1LUne5W9f+WrpexT/3Pfsl/ZvxxQDiwHlYPNkUPNkH7l8HJEObIcVY4u
x5Rjy3Hl+HJCObGcZE6cUvqbEKeZDmeYDGeZCueYCOeZBheYBBeZApeYAJfZ/VfY+VfZ9dfY8dfZ
7TfY6TfZ5bfY4bfZ3XfY2XfZ1ffY0ffZzQ/YyQ/ZxY/YwY/ZvU/YuU/Ztc/Ysc/ZrS/YqS/Zpa/Y
oa/ZnW/YmW/96rv7N62363Nj6Ovd+iz5/ev9nz76oD55fs/66A89w7A1bP259fEf+N5P/rJXMbQ1
oH5FrtZnrsmNK/JXbVfjgfUrcbUGDeVffveLv/m+fqX+v6/B//QL+PtW/ukXMGz96VXdONdDvboh
dt8cxRzFHMUcxRzFHMUcxRzFHMUcxRzFHMUcxZz2KOYo5qikqKQo5ijmKOaoqaipVEWmmKOqoqqi
zKKYU0OZpaoqxRzFHMUc1RbFHMUcxRzFHMUcxRzFHMUcxZyWUv1XQYlijmKOO/wo5ijmKOYo5lSl
V9WaYo5ijmKOYo5iTlcUcxRzFHMUcxRzFHMUcxRzFHMUcxRzFHMUcxRzFHN6sFyjJKsajGKOYo5i
jmKOYo5ijmKOYo5ijmKOYs7ajRKtajKKOYo5ijmKOYo5ijmKOYo5ijmKOYo5ijmKOYo5rSjmKOYo
5ijmKOYo5mzXqNIo5ijmKOYo5qp268WqmOMOOFUBq9/0o6rZU1GxUbFRsVGxUbFRsVGxUbFRsVGx
UbFRsVGxUbFRsbkUFRsVGxUbFRsVGxUbFRsVGxUbFRsVGxUbFRsVGxWbW1GxUbFRsVGxUbFRsVGx
UbFRsVGxUbFRsVGxUbFRsXkUFRsVGxUbFRsVGxUbFRsVGxUbFRsVGxUbFRsVGxWbV1GxUbFRsVGx
cbccFRt3o1GxcecZ95NRsXEvGfeJcQ2Pa3MG4JoZFRsVG9fMqNio2LhuRsVGxca1M66bcZ2MzRjX
xrh25GBO4kBOoD+Hcgp7sT/HcQzHcnip/29HVEuO5Ci0S/ZlP45GseQADuJEduf4Un4Et6OIGw==
EOT
# INTERNAL_MAPPINGS
);


1;
__END__

=head1 NAME

Encode::Registry - Registry file handling for character encodings

=head1 SYNOPSIS

    use Encode::Registry;

    $enc = Encode::Registry->find_encoding($enc_name);
    $uni_str = $enc->decode($byte_str);
    $byte_str = $enc->encode($uni_str);

=head1 DESCRIPTION

The C<Encode> module provides a Perl interface to the cross-architecture
registry of character encoding information. This registry takes the form of an
XML file containing information about encoding files, their types and handlers
for different file types on different platforms (or programming environments).

=head2 Encoding Types

=head2 Locating the Registry file

Having a central registry for encodings is very useful, assuming you can find it.
But tracking down such a registry given that it may be shared by many programming
environments, is not easy.

On the Windows platform, this module will look for the registry file in the system
registry under the following key

    HKEY_LOCAL_MACHINE\SOFTWARE\Mapping\Registry\File

which is held as a string.

Failing this, and on other systems, the module will examine the C<MAPPINGPATH>
environment variable and look in each directory listed for a file C<REGISTRY.xml>.
Directories in the environment variable are separated by a ;

=head1 MODULE

To use the module, simply C<use> it.

    use Encode::Registry

This will cause the C<import> subroutine to run which will search for a REGISTRY.xml
and read it. If nothing is found, then nothing will be read.

To load the highest priority implementation of an encoding, use:

    $enc = Encode::Registry->find_encoding($enc_name);
    $utf8 = $enc->decode($bytes);
    $bytes = $enc->encode($utf8);

=head2 Methods

=head3 Encode::Registry->find_registry

Returns an absolute file name reference to the registry file, if it can find it.

=head3 Encode::Registry->read_file($fname)

Reads and processes the given XML file adding the information to the internal
data structures of this class.

=head3 Encode::Registry->find_encoding($name)

Returns an object capable of processing data of the given encoding. The object
is created by calling

    $handler->new($system_file)

Where C<$handler> is the associated handler for the given file type of
C<$system_file>. The C<$handler> with the highest priority is chosen.

=head3 Encode::Registry->add_handler($type, $handler, $priority)

Adds the given type to be handled by the handler module when using Perl. The
priority is also set this way.

