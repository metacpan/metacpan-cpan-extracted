=pod

=head1 NAME

Getopt::XML - Provide the user input arguments to Getopt::Long as an XML document

=head1 SYNOPSIS

Read in a list of XML elements and process them as the input arguments to the
Getopt::Long module

    use XML::TreePP;
    use Getopt::Long;
    use Getopt::XML qw(GetXMLOptions);
    use Data::Dump qw(dump);
    #
    # Set the XML Data
    my $xmldata=<<"EOF_XMLDATA";
    <apple>
        <color>red</color>
        <type>red delicious</type>
        <isAvailable/>
        <cityGrown>Macomb</cityGrown>
        <cityGrown>Peoria</cityGrown>
        <cityGrown>Galesburg</cityGrown>
    </apple>
    EOF_XMLDATA
    #
    # Parse the XML data using XML::TreePP module
    my $tpp     = XML::TreePP->new();
    my $tree    = $tpp->parse( $xmldata );
    #
    # Read the XML data in as arguments to Getopt::Long
    my %options;
    GetXMLOptions (
            xmldoc   => $tree,
            xmlpath  => '/apple',
            Getopt_Long     =>
            [
            \%options,
                    'isAvailable',
                    'color=s',
                    'type=s',
                    'cityGrown=s@'
            ]
    );
    dump(\%options);

This is the output:

    {
      cityGrown => ["Macomb", "Peoria", "Galesburg"],
      color => "red",
      isAvailable => 1,
      type => "red delicious",
    }

Alternately, the XML data can be in a file.
The above code would be rewritten as this:

    use Getopt::Long;
    use Getopt::XML qw(GetXMLOptions);
    use Data::Dump qw(dump);
    #
    my %options;
    GetXMLOptions (
            xmlfile  => '/path/to/xml_file.xml',
            xmlpath  => '/apple',
            Getopt_Long     =>
            [
            \%options,
                    'isAvailable',
                    'color=s',
                    'type=s',
                    'cityGrown=s@'
            ]
    );
    dump(\%options);

=head1 DESCRIPTION

This is simply another way to pass in user defined arguments to an application
using Getop::Long. The module provides a way to pass in user arguments from an
XML file into Getopt::Long.

In this way, the user can provide input to an application via an XML file. And
this can be useful if the application is ran at a regular interval. Or it may
be useful if the input to the application can change between multiple
executions, but the provided content is consistant over time based on the
context of the execution.

This input method may be desired for an application which has default values
for options the author wishes to exist, but the author wants those default
values to be changed by the user without having to edit the application code.

Or perhaps the application will reside in a multi-user environment, and this
module would be used to store the input options as part of the user preferences.

And finally, perhaps the options to be passed into the application resides
somewhere else in XML or another storage format that can be transformed into
XML as input to an application.

=head1 REQUIREMENTS

The following perl modules are depended on by this module:
( I<Note: Dependency on Params::Validate was removed in version 0.52> )

=over 4

=item *     XML::TreePP

=item *     XML::TreePP::XMLPath

=item *     Getopt::Long            # Getopt::Long 2.37 or greater is required

=back

Both XML::TreePP and XML::TreePP::XMLPath required modules are Pure PERL
implementations.

Getopt::Long version 2.37 introduces the GetOptionsFromArray() method. Versions
of Getopt::Long previous to 2.37 do not contain the GetOptionsFromArray() method.

The process of transforming XML data into options that can be passed into
Getopt::Long is performed with the GetOptionsFromArray() method.

=head1 IMPORTABLE METHODS

When the calling application invokes this module in a use clause, the following
methods can be imported into its space.

=over 4

=item *     C<GetXMLOptions>

=item *     C<GetXMLOptionsFromFile>

=back

Example:

    use Getopt::XML qw( GetXMLOptions GetXMLOptionsFromFile );

=head1 METHODS

=cut

package Getopt::XML;

use 5.008001;
use strict;
use warnings;
use Exporter;
use Carp;
use Getopt::Long qw(GetOptionsFromArray);  # requires Getopt::Long 2.37 or greater
use XML::TreePP;
use XML::TreePP::XMLPath qw(filterXMLDoc);


BEGIN {
    use vars      qw(@ISA @EXPORT @EXPORT_OK);
    @ISA        = qw(Exporter);
    @EXPORT     = qw();
    @EXPORT_OK  = qw(&GetXMLOptions &GetXMLOptionsFromFile);

    use vars      qw($REF_NAME);
    $REF_NAME   = "Getopt::XML";  # package name

    use vars      qw( $VERSION );
    $VERSION    = '0.53';
}


=pod

=head2 new

Create a new object instances of this module.

=over 4

=item * I<returns>

An object instance of this module.

=back

    my $glx = new Getopt::XML();

=cut

# new
#
# It is not necessary to create an object of this module.
# However, if you choose to do so any way, here is how you do it.
#
#    my $obj = new Getopt::XML;
#
# You will have problems with the methods if you call them in an object
# oriented mannor. So you are better off not creating an object instance of
# this module, unless you are sure you know what you are doing.
#
sub new {
    my $pkg     = shift;
    my $class   = ref($pkg) || $pkg;
    my $self    = bless {}, $class;
    return $self;
}


=pod

=head2 XMLToGetoptArgsArray

This method formats a subtree of an XML document into an array that is 
acceptable to be passed in to the Getopt::Long::GetOptionsFromArray() method.

=over 4

=item * B<XMLTree>

The hash reference of a parsed XML file, which has been parsed
by XML::TreePP::parse()

=item * I<returns>

A reference to an array which an acceptable array input to the
Getopt::Long::GetOptionsFromArray() method.

=back

    my $ha_list = XMLToGetoptArgsArray ( $XMLTree )

=cut

# XMLToGetoptArgsArray
# @param    xmltree     the XML::TreePP XML Tree
# @return   [options]   an array reference of options suitable for GetOpt::Long::GetoptionsFromArray()
sub XMLToGetoptArgsArray ($);
sub XMLToGetoptArgsArray ($) {
    my $self    = shift if ref($_[0]) eq $REF_NAME || undef;
    if (@_ != 1) { carp 'method XMLToGetoptArgsArray($) requires one argument.'; return undef; }
    my $xmltree = shift;
    my @options;

    if (ref $xmltree eq "ARRAY") {
        # If the XMLPath filters to more than one node, we accept all results
        foreach my $xml_e (@{$xmltree}) {
            my $sopt = XMLToGetoptArgsArray($xml_e);
            next if !defined $sopt;
            push (@options,@{$sopt});
        }
        return \@options;
    } elsif (ref $xmltree ne "HASH") {
        return undef;
    }
    while (my ($key,$val) = each(%{$xmltree})) {
        # We include attribute in the <tag>
        if ($key =~ /^\-/) {
            $key =~ s/^\-//;
        }
        if (! defined $val) {
            push(@options,('--'.$key));
            next;
        } elsif (ref $val eq "ARRAY") {
            foreach my $a (@{$val}) {
                push(@options,('--'.$key));
                push(@options,$a);
            }
        } elsif (ref $val eq "HASH") {
            push(@options,('--'.$key));
            foreach (my ($skey,$sval) = each %{$val}) {
                push(@options,($skey.'='.$sval));
            }
        } elsif (ref $val eq "SCALAR") {
            push(@options,('--'.$key));
            push(@options,${$val});
        } else {
            push(@options,('--'.$key));
            push(@options,$val);
        }
    }
    return \@options;
}


=pod

=head2 GetXMLOptions

Read a XML::TreePP parsed XML document, retrieve the XML data located at the
specified XML subtree, and transform it into an acceptable argument array that
can be passed into to the Getopt::Long::GetOptionsFromArray() method.

=over 4

=item * B<xmldoc>

The hash reference of a parsed XML file, which has been parsed
by XML::TreePP::parse()

=item * B<xmlpath> - I<optional>

The XML Path as recognized by the XML::TreePP::XMLPath module.
Note that XMLPath is NOT an XPath, although it has similarities.

=item * B<Getopt_Long>

The hash array of a Getopt::Long configuration which is a definition
of the expected Getopt::Long::GetOptions() input options.

=back

    GetXMLOptions ( xmldoc => $XMLTree, xmlpath => $XMLPath, Getopt_Long => \@options )

=cut

# GetXMLOptions
# @param    xmldoc      the XML::TreePP parsed XML file as a HASH
# @param    xmlpath     an XPath-like string used to retrieve a XML child element for the parsing, instead of the XML root
# @param    Getopt_Long input for the Getopt::Long::GetOptions(@) method used in this method for input
# @return   the result of Getopt::Long() using the 'xmldoc' as input (as opposed to @ARGV as input)
#
# This method does not look at nor touch @ARGV, but instead parses the XML
# document 'xmldoc', starting at 'path', and uses that in place of @ARGV.
# Thus, the returning data is from the result of 
# Getopt::Long::GetOptionsFromArray(<parsed-xml-file>,@{'Getopt_Long'})
#
sub GetXMLOptions (@) {
    my $self    = shift if ref($_[0]) eq $REF_NAME || undef;
    if (! @_ >= 1) { carp 'method GetXMLOptions(@) requires at least one argument.'; return undef; }
    my %args    = @_;  # xmldoc, dtddoc, xmlpath, Getopt_Long,
    my $tree    = $args{'xmldoc'};
    # not yet supported # @param  dtddoc   (optional) the DTD doc to validate the XML doc    
    #my %args    =   validate ( @_,  {   xmldoc      => { optional => 0 },
    #                                    dtddoc      => { optional => 1 },
    #                                    xmlpath     => { type => SCALAR, optional => 1 },
    #                                    Getopt_Long => { type => ARRAYREF, optional => 1 }
    #                                }
    #                         );
    my $subtree;

    if (defined $args{'xmlpath'}) {
        $subtree = filterXMLDoc($tree,$args{'xmlpath'});
    } else {
        $subtree = $tree;
    }
    if (! defined $subtree) {
        return undef;
    }
    my $xmlargs = XMLToGetoptArgsArray($subtree);
    return GetOptionsFromArray($xmlargs,@{$args{'Getopt_Long'}});
}


=pod

=head2 GetXMLOptionsFromFile

This method is a wrapper around the Getopt::XML::GetXMLOptions() method.
Parse a XML file with the XML::TreePP::parsefile() method, then call the
GetXMLOptions() method with the resulting XML::TreePP parsed XML document and
other parameters passed in from the caller.

=over 4

=item * B<xmlfile>

The XML file which will be parsed by XML::TreePP::parse() into a hash reference.

=item * B<xmlpath> - I<optional>

The XML Path as recognized by the XML::TreePP::XMLPath module.
Note that XMLPath is NOT an XPath, although it has similarities.

=item * B<Getopt_Long>

The hash array of a Getopt::Long configuration which is a definition
of the expected Getopt::Log::GetOptions() input options.

=back

    GetXMLOptionsFromFile ( xmlfile => $XMLFile, xmlpath => $XMLPath, Getopt_Long => \@options )

=cut

# GetXMLOptionsFromFile
# @param    xmlfile     the XML file
# @param    xmlpath     an XPath-like string used to retrieve a XML child element for the parsing, instead of the XML root
# @param    Getopt_Long input for the Getopt::Long::GetOptions(@) method used in this method for input
# @return   the result of Getopt::Long() using the 'xmlfile' as input (as opposed to @ARGV as input)
#
# See GetXMLOptions method.
#
sub GetXMLOptionsFromFile (@) {
    my $self    = shift if ref($_[0]) eq $REF_NAME || undef;
    if (! @_ >= 1) { carp 'method GetXMLOptionsFromFile(@) requires at least one argument.'; return undef; }
    my %args    = @_;  # xmlfile, dtdfile, xmlpath, Getopt_Long,
    # not yet supported # @param  dtdfile   (optional) the DTD file to validate the XML file
    #my %args    =   validate ( @_,  {   xmlfile     => { optional => 0 },
    #                                    dtdfile     => { optional => 1 },
    #                                    xmlpath     => { type => SCALAR, optional => 1 },
    #                                    Getopt_Long => { type => ARRAYREF, optional => 0 }
    #                                }
    #                         );

    my $tpp     = XML::TreePP->new();
    my $tree    = $tpp->parsefile( $args{'xmlfile'} );

    return GetXMLOptions(
                         xmldoc         => $tree,
                         xmlpath        => $args{'xmlpath'},
                         Getopt_Long    => $args{'Getopt_Long'}
                         );
}

1;
__END__

=pod

=head1 EXAMPLES

=head2 Method: new

It is not necessary to create an object of this module.
However, if you choose to do so any way, here is how you do it.

    my $obj = new Getopt::XML;

This module supports being called by two methods.

=over 4

=item 1.  By importing the functions you wish to use, as in:

    use Getopt::XML qw( function1 function2 );
    function1( args )

See IMPORTABLE METHODS section for methods available for import

=item 2.  Or by calling the functions in an object oriented mannor, as in:

    my $glx = new Getopt::XML;
    $glx->function1( args )

=back

Using either method works the same and returns the same output.

=head2 Method: XMLToGetoptArgsArray

    use Getopt::Long qw(GetOptionsFromArray); # requires Getopt::Long 2.37 or greater
    use Getopt::XML qw(XMLToGetoptArgsArray);
    use XML::TreePP;    
    
    my $tpp     = XML::TreePP->new();
    my $tree    = $tpp->parsefile( '/path/to/xml_file.xml' );
    my $xmlargs = XMLToGetoptArgsArray($tree);
    my %options;
    my @Getopt_Long = (
                       \%options,
                       'opt1',
                       'opt2=s',
                       'opt3=s@'
                       );
    GetOptionsFromArray($xmlargs,@Getopt_Long);
    # data from XML is now in %options

Where the XML file looks like this:

    <opt1/>             <!-- true or false -->
    <opt2>argA</opt2>   <!-- single value option -->
    <opt3>argB</opt3>   <!-- multi-value option -->
    <opt3>argC</opt3>
    <opt3>argD</opt3>
    etc...

=head2 Method: GetXMLOptions

Parse an XML file with XML::TreePP::parsefile() and pass in the resulting
parsed XML::TreePP document which will be used to create the arguments that
would be passed in to the Getopt::Long::GetOptionsFromArray() method.

    use Getopt::Long;
    use Getopt::XML qw(GetXMLOptions);
    use XML::TreePP;    
    # Parse the XML file into an XML::TreePP document
    my $tpp     = XML::TreePP->new();
    my $tree    = $tpp->parsefile( '/path/to/xml_file.xml' );
    # Define %options, and populate it with options found in the XML document
    my %options;
    GetXMLOptions (
            xmldoc   => $tree,
            xmlpath  => '/xmlconfig/options',
            Getopt_Long     =>
            [
            \%options,
                    'verbose',
                    'single_option=s',
                    'multiple_options=s@'
            ]
    );

Where the file '/path/to/xml_file.xml' contains the following content:

        <xmlconfig>
            <options>
                <verbose/>
                <single_option>argument1A</single_option>
                <multiple_options>argument2A</multiple_options>
                <multiple_options>argument2B</multiple_options>
                <multiple_options>argument2C</multiple_options>
            </options>
        </xmlconfig>

=head2 Method: GetXMLOptionsFromFile

Parse an XML file to create the arguments that would be passed in to
the Getopt::Long::GetOptionsFromArray() method.
With the Getopt::XML module, you can now put the would be user
input into an XML file like the example below.

    use Getopt::Long;
    use Getopt::XML qw(GetXMLOptionsFromFile);
    # Define %options, and populate it with options found in the XML file
    my %options;
    GetXMLOptionsFromFile (
            xmlfile  => '/path/to/xml_file.xml',
            xmlpath  => '/xmlconfig/options',
            Getopt_Long     =>
            [
            \%options,
                    'verbose',
                    'single_option=s',
                    'multiple_options=s@'
            ]
    );

Where the file '/path/to/xml_file.xml' contains the following content:

        <xmlconfig>
            <options>
                <verbose/>
                <single_option>argument1A</single_option>
                <multiple_options>argument2A</multiple_options>
                <multiple_options>argument2B</multiple_options>
                <multiple_options>argument2C</multiple_options>
            </options>
        </xmlconfig>

=head2 General

The sample XML file '/path/to/xml_file.xml' contains the following content:

    <xmlconfig>
        <options>
            <verbose/>
            <single_option>argument1A</single_option>
            <multiple_options>argument2A</multiple_options>
            <multiple_options>argument2B</multiple_options>
            <multiple_options>argument2C</multiple_options>
        </options>
    </xmlconfig>

B<What you are used to doing with the Getopt::Long module>

With the Getopt::Long module alone, you performed this to retrieve user input.
This prints out what the user passed in for the --single_option option on the
command line.

    use Getopt::Long;
    my %options;
    GetOptions (    %options,
                    'verbose',
                    'single_option=s',
                    'multiple_options=s@'
               );
    print $options{'single_option'},"\n";

B<What you can do using XML>

With the Getopt::XML module, you can now put the would be user input into
an XML file like the sample XML file above.
This prints out the value of the <single_option></single_option> element as
found in the XML file.

    use Getopt::Long;
    use Getopt::XML qw(GetXMLOptionsFromFile);
    my %options;
    GetXMLOptionsFromFile (
            xmlfile  => '/path/to/xml_file.xml',
            xmlpath  => '/xmlconfig/options',
            Getopt_Long     =>
            [
            \%options,
                    'verbose',
                    'single_option=s',
                    'multiple_options=s@'
            ]
    );
    print $options{'single_option'},"\n";

B<What you can do using both methods>

Now try doing both. You can provide the XML file to give all the defaults for
the input to your application, then you can overwrite the defaults with user
provided input.
This prints out what the user passed in for the --single_option option on the
command line. However, if the user did not provide such input, then the value
for this option as found in the XML file is what is printed out.

    use Getopt::Long;
    use Getopt::XML qw(GetXMLOptionsFromFile);
    # Read in the default arguments for your options from the XML file:
    my %options;
    GetXMLOptionsFromFile (
            xmlfile  => '/path/to/xml_file.xml',
            xmlpath  => '/xmlconfig/options',
            Getopt_Long     =>
            [
            \%options,
                    'verbose',
                    'single_option=s',
                    'multiple_options=s@'
            ]
    );
    # Then overwrite those defaults with user provided input
    GetOptions (    %options,
                    'verbose',
                    'single_option=s',
                    'multiple_options=s@'
               );
    print $options{'single_option'},"\n";

B<Passing in XML:TreePP parsed XML, instead of a file>

Optionally, if you are using the XML::TreePP module for your XML files, you can
pass in the parsed XML::TreePP XML document instead of the actual file.

    use Getopt::Long;
    use Getopt::XML qw(GetXMLOptions);
    use XML::TreePP;    
    # Parse the XML file using XML::TreePP module
    my $tpp     = XML::TreePP->new();
    my $tree    = $tpp->parsefile( '/path/to/xml_file.xml' );
    my %options;
    # Read the XML data in as arguments to Getopt::Long
    GetXMLOptions (
            xmldoc   => $tree,
            xmlpath  => '/xmlconfig/options',
            Getopt_Long     =>
            [
            \%options,
                    'verbose',
                    'single_option=s',
                    'multiple_options=s@'
            ]
    );

Leveraging the capabilites of XML::TreePP, you can also fetch the XML file
from the internet via a HTTP GET request

    use Getopt::Long;
    use Getopt::XML qw(GetXMLOptions);
    use XML::TreePP;    
    # Parse the XML file using XML::TreePP module
    my $tpp     = XML::TreePP->new();
    my $tree    = $tpp->parsehttp( GET => "http://config.mydomain.com/myapp/default_settings.xml" );
    my %options;
    # Read the XML data in as arguments to Getopt::Long
    GetXMLOptions (
            xmldoc   => $tree,
            xmlpath  => '/xmlconfig/options',
            Getopt_Long     =>
            [
            \%options,
                    'verbose',
                    'single_option=s',
                    'multiple_options=s@'
            ]
    );

=head1 AUTHOR

Russell E Glaue, http://russ.glaue.org

=head1 SEE ALSO

C<Getopt::Long>

C<XML::TreePP>

C<XML::TreePP::XMLPath>

Getopt::XML on Codepin: http://www.codepin.org/project/perlmod/Getopt-XML

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008-2009 Center for the Application of Information Technologies.
All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

