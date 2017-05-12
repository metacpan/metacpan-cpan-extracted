package Glade::PerlXML;
require 5.000; use strict 'vars', 'refs', 'subs';

# Copyright (c) 1999 Dermot Musgrove <dermot.musgrove@virgin.net>
#
# This library is released under the same conditions as Perl, that
# is, either of the following:
#
# a) the GNU General Public License as published by the Free
# Software Foundation; either version 1, or (at your option) any
# later version.
#
# b) the Artistic License.
#
# If you use this library in a commercial enterprise, you are invited,
# but not required, to pay what you feel is a reasonable fee to perl.org
# to ensure that useful software is available now and in the future. 
#
# (visit http://www.perl.org/ or email donors@perlmongers.org for details)

BEGIN {
    use XML::Parser   qw(  );               # for new, parse, parsefile
    use Glade::PerlRun qw(:METHODS :VARS);
    # Uncomment the line below if you are using european characters 
    # NB you will also have to uncomment line 183 and comment out line 181
#    use Unicode::String qw(utf8 latin1);    # To read ISO-8859-1 chars
    use vars          qw( 
                            @ISA 
                            @EXPORT @EXPORT_OK %EXPORT_TAGS 
                            $PACKAGE $VERSION $AUTHOR $DATE
                       );
    # Tell interpreter who we are inheriting from
    @ISA            = qw( Glade::PerlRun );
    $PACKAGE      = __PACKAGE__;
    $VERSION      = q(0.61);
    $AUTHOR       = q(Dermot Musgrove <dermot.musgrove@virgin.net>);
    $DATE         = q(Sun Nov 17 03:21:11 GMT 2002);
}

sub DESTROY {
    # This sub will be called on object destruction
} # End of sub DESTROY

#===============================================================================
#=========== Utilities to read XML and build the Proto                ==========
#===============================================================================
sub Proto_from_File {
    my ($class, $filename, $repeated, $special, $encoding) = @_;
    my $me = "$class->Proto_from_File";
    my $xml = $class->string_from_File($filename);
#print "$filename - $xml\n";
    return $class->Proto_from_XML($xml, $repeated, $special, $encoding );
}

sub Proto_from_XML {
    my ($class, $xml, $repeated, $special, $encoding) = @_;
    my $me = "$class->Proto_from_XML";
    my $xml_encoding;
    if ($xml =~ s/\<\?xml.*\s*encoding\=["'](.*?)['"]\?\>\n*//) {
        $xml_encoding = $1
    } else {
        $xml_encoding = $encoding;
    }
    my $tree = new XML::Parser(
        Style =>'Tree', 
        ProtocolEncoding => $xml_encoding,
        ErrorContext => 2)->parse($xml );
    my $proto = $class->Proto_from_XML_Parser_Tree(
        $tree->[1], 0, $repeated, $special, $xml_encoding );
    return $xml_encoding, $proto;
}

sub Proto_from_XML_Parser_Tree {
    my ($class, $self, $depth, $repeated, $special, $encoding) = @_;
    my $me = "$class->Proto_from_XML_Parser_Tree";
    # Tree[0]      contains fileelement name
    # Tree[1]      contains fileelement contents
    
    # Tree[1][n]      contains element name
    # Tree[1][n+1]    contains element contents
    # Tree[1][n+1][0] contains ref to hash of element attributes
    # Tree[1][n+1][1] contains '0' ie next element is text
    # Tree[1][n+1][2] contains text before subelement

    # Tree[1][n+1][3] contains subelement name
    # Tree[1][n+1][4] contains subelement contents
    # Tree[1][n+1][5] contains '0' ie next element is text
    # Tree[1][n+1][6] contains text before subelement
    #        recursed
    
    # Tree[3] cannot exist since the fileelement must enclose everything
# FIXME make this general for all encodings
    if ($encoding && ($encoding eq 'ISO-8859-1')) {
        eval "use Unicode::String qw(utf8 latin1)";
        undef $encoding if $@;  # We can't use encodings correctly
    } else {
        undef $encoding;        # We don't recognise the encodings name
    }
    my ($tk, $i, $ilimit );
    my ($count, $np, $key, $work );
    my $limit = scalar(@$self);
    my $child;
    $key = 0;
    for ($count = 3; $count < $limit; $count += 4) {
        $key++;
        $ilimit = scalar @{$self->[$count+1]};
        if (" $repeated " =~ / $self->[$count] /) {
            # this is a repeated container so use a sequence no to preserve order
            if ($ilimit <= 3)  {
#                $class->diag_print(4, "Found a scalar called '".
#                    "$self->[$count]' which contains '$self->[$count+1][2]'".
#                    " in a repeated container type element !" );
                $np->{$self->[$count]} = ($self->[$count+1][2]);

            } else {
                # call ourself to expand nested xml but use sequence no
                $work = $class->Proto_from_XML_Parser_Tree($self->[$count + 1], 
                    ++$depth, $repeated, $special, $encoding );
                $work->{&typeKey} = $self->[$count];
                # prefix with tilde to force to end (alphabetically)
                $tk = "~$self->[$count]-".sprintf(&keyFormat, $key, $self->[$count] );
#print "$tk\n";
                $np->{$tk} = $work;
            }

        } elsif (" $special " =~ / $self->[$count] /) {
            # this is a unique container definition (eg Glade <project>) 
            # so just expand and store it without a sequence no
            $work = $class->Proto_from_XML_Parser_Tree($self->[$count + 1], 
                ++$depth, $repeated, $special, $encoding );
            $work->{&typeKey} = $self->[$count];
            $np->{$self->[$count]} = $work;

        } elsif ($ilimit > 3) {
            # We have several (widget) attributes to store
            $work = {};
            for ($i = 3; $i < $ilimit; $i += 4) {
                $work->{$self->[$count+1][$i]} = $self->[$count+1][$i+1][2];
            }
            $work->{&typeKey} = $work->{'class'} || $self->[$count];
            # prefix with tilde to force to end (alphabetically)
            $tk = "~$self->[$count]-".
                sprintf(&keyFormat, $key, $self->[$count] );
            $np->{$tk} = $work;

        } elsif ($ilimit == 1) {
            # this is an empty (nul string) element
            $np->{$self->[$count]} = '';

        } else {
            # this is a simple element to add with 
            # key in $self->[$count] and val in $self->[$count+1][2]
# FIXME make this general for all encodings
            if ($encoding && ($encoding eq 'ISO-8859-1')) {
                # We use line below if you are using european characters
                $np->{$self->[$count]} = &utf8($self->[$count+1][2])->latin1;
            } else {
                # We use the line below if you are NOT using european characters
                $np->{$self->[$count]} = $self->[$count+1][2];
            }
        }
    }
    return $np;
}

1;

__END__
