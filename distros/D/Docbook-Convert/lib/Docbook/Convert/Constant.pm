#
#  This file is part of Docbook::Convert.
#
#  This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.
#
#  This is free software; you can redistribute it and/or modify it under
#  the same terms as the Perl 5 programming language system itself.
#
#  Full license text is available at:
#
#  <http://dev.perl.org/licenses/>
#


#  Package Constants
#
package Docbook::Convert::Constant;


#  Compiler Pragma
#
use strict qw(vars);
use vars   qw($VERSION @ISA %EXPORT_TAGS @EXPORT_OK @EXPORT %Constant);    ## no critic
use warnings;
no warnings qw(uninitialized);


#  External modules
#
use Cwd qw(abs_path);
use Data::Dumper;


#  Data Dumper formatting
#
$Data::Dumper::Indent=1;
$Data::Dumper::Terse=1;


#  Version information in a format suitable for CPAN etc. Must be
#  all on one line
#
$VERSION='1.012';


#===================================================================================================


#  Get module file name and path, derive name of file where local constants stored. e.g.
#  <perl lib>/Package/Constant.local will override anything in Constant.pm
#
my $module_fn=abs_path(__FILE__);
my $constant_local_fn="${module_fn}.local";


#  Constants
#  <<<
%Constant=(

    #  XML Data array index locations
    #
    NODE_IX => 0,
    CHLD_IX => 1,
    ATTR_IX => 2,
    LINE_IX => 3,
    COLM_IX => 4,
    PRNT_IX => 5,


    #  Handler nicknames
    #
    HANDLER_HR => {

        markdown => 'Docbook::Convert::Markdown',
        md       => 'Docbook::Convert::Markdown'

    },


    #  Default handler
    #
    HANDLER_DEFAULT => 'markdown',


    #  Markdown separators
    #
    CR   => $/,
    CR2  => $/ x 2,
    SP   => ' ',
    SP4  => ' ' x 4,
    SP8  => ' ' x 8,
    NULL => \undef,


    #  Don't escape the following Docbook tags in Markdown converter
    #
    MD_DONT_ESCAPE_AR => [qw(
            command
            screen
            arg
            markup
            programlisting
            term
            code
            option
        )
    ],


    #  Anything below these tags is plaintext - don't markup further
    #
    MD_PLAINTEXT_HR => {
        map {$_ => 1}
            qw(
            table
            screen
            programlisting
            )
    },


    #  Adminition Text
    #
    ADMONITION_TEXT_HR => {
        note      => 'NOTE',
        warning   => 'WARNING',
        caution   => 'CAUTION',
        tip       => 'TIP',
        important => 'IMPORTANT'
    },


    #  Refentry Text
    #
    REFENTRY_TEXT_HR => {
        synopsis => 'SYNOPSIS',
        name     => 'NAME'
    },


    #  Tag synonyms for Markdown
    #
    MD_TAG_SYNONYM_HR => {
        _text => [qw(replaceable)]
    },


    #  Common tag synonyms
    #
    ALL_TAG_SYNONYM_HR => {
        command    => [qw(classname parameter filename markup)],
        sect1      => [qw(section)],
        refsection => [qw(refsect1)],
        para       => [qw(simpara)],
        warning    => [qw(caution important note tip)],
        code       => [qw(option varname tag)],
        link       => [qw(xref application)],
        term       => [qw(guilabel guibutton)],

        #figure     => [qw(screenshot)],
        article => [qw(refentry)],
        _text   => [qw(literallayout orgname firstname surname example qandaentry)],
        _data   => [qw(imageobject)],
        _null   => [qw(refentryinfo articleinfo tgroup)],
        _meta   => [qw(author affiliation pubdate address copyright)]
    },


    #  Delay render of mediaobject tag if any of these in parent - potentially
    #  allows more info to be build into image
    #
    MEDIAOBJECT_DELAY_RENDER_AR => [
        qw(figure)
    ],


    #  Metadata render options
    #
    META_DISPLAY_TOP           => 0,
    META_DISPLAY_BOTTOM        => 0,
    META_DISPLAY_TITLE         => undef,
    META_DISPLAY_TITLE_H_STYLE => 'h2',


    #  Default formatting/output options
    #
    NO_HTML           => 0,
    NO_IMAGE_FETCH    => 0,
    NO_WARN_UNHANDLED => 0,
    XMLSUFFIX         => '.xml',
    VERBOSE           => 0,
    DEBUG             => 0,


    #  Constants that can be set via getopt
    #
    GETOPT_CONSTANT_HR => {
        meta_display_top           => undef,
        meta_display_bottom        => undef,
        meta_display_title         => '=s',
        meta_display_title_h_style => '=s',
        md_section_num             => undef,
        no_html                    => undef,
        no_image_fetch             => undef,

        #no_warn_unhandled          => undef,
        xmlsuffix => '|x=s',
    },


    #  Other options
    #
    GETOPT_AR => [
        (
            'help|?',
            'man',
            'version|V',
            'dump',
            'dumpopt',
            'outfile|out|o=s',
            'infile|in|f=s@',
            'recurse|r',
            'recursedir|d=s',
            'markdown|md',
            'no_warn_unhandled|silent|quiet|s|q',
            'handler|h=s',
            'verbose',
            'debug'
        )
    ],


    #  Detailed backtrace ?
    #
    ERR_BACKTRACE => 0,


    #  Table/Text wrap columns size (i.e. max col width of text in a single cell)
    #
    TABLE_WRAP_COLUMNS => 40,
    TABLE_WRAP_HUGE    => 'overflow',


    #  LWP Timeout
    #
    LWP_TIMEOUT => 10,


    #  Local constants override anything above
    #
    %{do($constant_local_fn)}

);

#  >>>


#  Export constants to namespace, place in export tags
#
require Exporter;
@ISA=qw(Exporter);
foreach (keys %Constant) {${$_}=defined $ENV{$_} ? $Constant{$_}=eval($ENV{$_}) || $ENV{$_} : $Constant{$_}}    ## no critic
@EXPORT=map {'$' . $_} keys %Constant;
@EXPORT_OK=@EXPORT;
%EXPORT_TAGS=(all => [@EXPORT_OK]);
$_=\%Constant;
1;
__END__

=begin markdown

# NAME

Docbook::Convert::Constant - internal constants for Docbook::Convert

# DESCRIPTION

This module exports the parser indexes, handler maps and rendering defaults
used by the custom converter. Values may be overridden by a
`Docbook::Convert::Constant.pm.local` file, but that mechanism is retained for
compatibility rather than recommended for new applications.

Configure new conversions through the documented constructor and method
options instead.

# SEE ALSO

`Docbook::Convert`

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT

This file is part of Docbook::Convert.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>


=end markdown


=head1 NAME

Docbook::Convert::Constant - internal constants for Docbook::Convert


=head1 DESCRIPTION

This module exports the parser indexes, handler maps and rendering defaults
used by the custom converter. Values may be overridden by a
C<Docbook::Convert::Constant.pm.local> file, but that mechanism is retained for
compatibility rather than recommended for new applications.

Configure new conversions through the documented constructor and method
options instead.


=head1 SEE ALSO

C<Docbook::Convert>


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2025 by Andrew Speer. It may be distributed
under the same terms as Perl itself.

=cut
