use strict;

use vars qw($VERSION);
$VERSION = sprintf("%d.%02d", q$Revision: 1.0 $ =~ /(\d+)\.(\d+)/);

### ######################################################################
### ######################################################################
#
# see? http://www.yy.ics.keio.ac.jp/~suzuki/project/uxf/uxf.html
#
# see Philip Crow > UML-Sequence-0.04 > UML::Sequence
#
### ######################################################################
### ######################################################################


### ######################################################################
### ######################################################################
package Devel::Package; # A UML "package", which is (several) Perl modules
sub new {
    my $self = bless { 'Name' => $_[1], 'Classes' => {}, '_filename' => $_[2] };
    return $self;
}


### ######################################################################
### ######################################################################
package Devel::Class; # A UML "class" is a Perl "package"
sub new {
    my $self = bless { 'Name' => $_[1], 'Attributes' => {}, 'Operations' => {} };
    return $self;
}


### ######################################################################
### ######################################################################
package Devel::Attribute; # Discovered by pattern matching
sub new {
    my $self = bless { 'Name' => $_[1], 'Type' => $_[2], 'Visibility' => $_[3] };
    return $self;
}


### ######################################################################
### ######################################################################
package Devel::Operation; # Discovered as "sub something {"
sub new {
    my $self = bless { 'Name' => $_[1], 'Type' => $_[2], 'Visibility' => $_[3] };
    return $self;
}


### ######################################################################
### ######################################################################


### ######################################################################
### ######################################################################
### ######################################################################
### ######################################################################
### ######################################################################
package Devel::Diagram; # A container for all the stuff we'll discover here.
use FileHandle;

### ######################################################################
sub new {
    my $self = bless { 'Name' => $_[1], 'Packages' => {}, '_isDiscovered' => 0 }, shift;
    
    for ( @_ ) {
        my $filnam = $_;
        $filnam =~ s{::}{/}g;
        my $moduleName = $filnam;
        $moduleName =~ s{/$}{}; $moduleName =~ s{/}{::}g;
        
        my $foundIt = 0;
        for my $lib (@INC) {
            if ( -f "$lib/$filnam.pm" ) {
                $moduleName = "$filnam"; $moduleName =~ s{/$}{}; $moduleName =~ s{/}{::}g;
                $self->{'Packages'}->{$moduleName} = new Devel::Package($moduleName, "$lib/$filnam.pm");
                $self->{'Packages'}->{$moduleName}->{'_filename'} = "$lib/$filnam.pm";
                $foundIt = 1;
            }
            
            if ( -d "$lib/$filnam" ) { # e.g. HTML/ - HTML has no HTML.pm file.
                $filnam .= '/' unless $filnam =~ m{/$}; # include the module's folder.
                my $fh = new FileHandle;
                opendir $fh, "$lib/$filnam";
                while ( my $fil = readdir $fh ) {
                    if ( $fil =~ s{\.pm$}{} ) {
                        $moduleName = "$filnam$fil"; $moduleName =~ s{/$}{}; $moduleName =~ s{/}{::}g;
                        my $subModule = new Devel::Diagram($moduleName);
                        # Merge the "packages" of the sub-module into ours.
                        for ( keys %{$subModule->{'Packages'}} ) {
                            if ( $self->{'Packages'}->{$_} ) {
                                warn <<EOT;
$moduleName contains new or redefined operations/attributes of $_.
Devel::Diagram is not yet robust enough to merge these two definitions, so
operations/attributes of $_ that are defined in $moduleName will be lost.
EOT
                            } else {
                                $self->{'Packages'}->{$_} = $subModule->{'Packages'}->{$_};                            
                            }
                        }
                    }
                }
                closedir $fh;
                $foundIt = 1;
            }
            last if $foundIt;
        }
    }
    return $self;
}


### # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _discoverClasses {
    my $self = shift;
    
    for ( keys %{$self->{'Packages'}} ) {
        my $moduleName = $_; # '$_' is read-only.
        my $module = $self->{'Packages'}->{$_};
        
        my $filnam = $module->{'Name'};
        $filnam =~ s{::}{/}g;
        $filnam =~ s{'}{/}g;
        $self->_discoverClass($module);
        
        # Now recurse into any module that this one ISA.
        for my $uses ( sort keys %{$self->{'Packages'}->{$moduleName}->{'_uses'}} ) {
            # Only if the named package is based on one we've done before, then recurse into it.
            for ( keys %{$self->{'Packages'}} ) {
                if ( $uses =~ m{^$_} ) {
                    my $fil = $_;
                    $fil =~ s{::}{/}g;
                    $fil =~ s{'}{/}g;
                    $self->_discoverClass($fil);
                }
            }
        }
    }
}


### # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _discoverClass {
    my ($self, $module) = @_;
    my $filnam = $module->{'_filename'};
    my $moduleName = $module->{'Name'};

    my $packages = $self->{'Packages'};

#    for my $pkgName ( keys %$packages ) {
        # Slurp the whole file.
#        next unless $filnam; # Where do these blank filenames come from?
        open MOD, "<$filnam" or do { warn "Can't read '$filnam': $!"; return; };
        my $mod = join '', <MOD>; close MOD;

        $self->FindAnnotations(\$mod);  # Find any annotations we can discover.
        $self->CleanUpCode(\$mod);      # Clean up code, e.g., remove comments.

        #while ( $mod =~ m{\n\s*package\s+(.*?);(.*?)(\n\s*package|$)}gs ) {
        for my $pckg ( $self->FindPackages(\$mod) ) {
            my ($className, $cod) = @$pckg;

            next if $className eq 'main';
            
            my $thisModule = $packages->{$moduleName};
            $thisModule->{'Classes'}->{$className} = new Devel::Class($className)
                unless defined $thisModule->{'Classes'}->{$className};
            my $thisClass = $thisModule->{'Classes'}->{$className};
            $thisClass->{'_filnam'} = $filnam;  # The source file of this package.

            # Find other class components by investigating use's, use base's, etc.
            $self->FindOtherComponents($thisClass, \$cod);

            # Find base classes by investigating @ISA's.
            $self->FindBaseClasses($thisClass, \$cod);

            # Find methods by investigating sub's.
            $self->FindMethods($thisClass, \$cod);

            # Find properties by investigating "$self->{}".
            $self->FindPropertys($thisClass, \$cod);
        }
#    }
}

#######################################################################################
sub FindAnnotations {
    my ($self, $mod) = @_;
}

#######################################################################################
sub CleanUpCode {
    my ($self, $mod) = @_;
    
    # Remove comments.
    $$mod =~ s{\#.*?\n}{\n}gs;
    $$mod =~ s{=(pod|item|head\d).*?=cut}{}gs;
    $$mod =~ s{\_\_END\_\_.*$}{}gs;
   
}

#######################################################################################
sub FindPackages {
    my ($self, $mod) = @_;
    my @mods;
    while ( $$mod =~ m{(?:^|\n)\s*package\s+(\w[^\s]+?)\s*;(.*?)(?=\n\s*package|$)}gs ) {
        my ($nam, $cod) = ($1,$2);
        push @mods, [$nam,$cod];
    }
    return @mods;
}

#######################################################################################
sub FindOtherComponents {
    my ($self, $packag, $cod) = @_;

    # Find other package components by investigating use's.
    while ( $$cod =~ m{use\s+([^;]+)\s*;}gs ) {
        my $usee = $1;
        next if $usee =~ m{^(vars|constant)};
        $packag->{'_uses'}->{$usee} = 1;
    }

}

#######################################################################################
sub FindBaseClasses {
    my ($self, $packag, $cod) = @_;
    
    # Find base classes by investigating @ISA's and use base's, etc.
    while ( $$cod =~ m{\@ISA\s*=\s*qw\(\s*([^)]+?\s*)\)\s*;}gs ) {
        my $isa = $1;
        for ( split /\s+/,$isa ) {
            #print "ISA $_\n";
            $packag->{_isa}->{$_} = 1;
            #$packages->{$packag}->{_uses}->{$_} = 1;
        }
    }
    # TODO: Find base classes by investigating "use base".
}

#######################################################################################
sub FindMethods {
    my ($self, $clas, $cod) = @_;
    
    # Find methods by investigating sub's.
    my $methods = $clas->{'Operations'};
    while ( $$cod =~ m{\n\s*sub\s+([^\{ \n]+)\s*\{(.*?)(\n\s*sub|$)}gs ) {
        $methods->{$1} = new Devel::Operation($1);
    }
}

#######################################################################################
sub FindPropertys {
    my ($self, $packag, $cod) = @_;
    
    # Find properties by investigating "$self->{}".
    my $attributes = $packag->{'Attributes'};
    while ( $$cod =~ m{\$self->\{['"]?([_a-zA-Z0-9\*]+)["']?\}}gs ) { 
        my $attr = $1;
        $attributes->{$attr} = new Devel::Attribute($attr) unless $attributes->{$attr};
        $attributes->{$attr}->{'Visibility'} = ($attr =~ m{^_})?'private':'public'; 
        
    }
}



#######################################################################################
#######################################################################################
sub Render {
    my ($self, $renderType, $transform) = @_;

    die "Unrecognized rendering type '$renderType'" unless $renderType =~ m{^(UXF20)$};
    
    $self->_discoverClasses() unless $self->{'_isDiscovered'};

    my $render;
    eval "require Devel::Diagram::Render::$renderType; 
         \$render = Render Devel::Diagram::Render::$renderType(\$self)";
    return $render if $@;

    if ( $transform ) {
        if ( $transform =~ m{^xsl\:(.+)$} ) {
            my $xsl = $1;
            $xsl =~ s{\.xsl$}{}i;
            for my $lib (@INC) {
                if ( -f "$lib/Devel/Diagram.pm" ) {
                    if ( -f "$lib/Devel/Diagram/xsl/$xsl.xsl" ) {
                        my $tempXml = 'develDiagram.temp.xml';
                        open TMP, ">$tempXml";
                        print TMP $render;
                        close TMP;
                        eval "  use XML::XSLT::Wrapper; 
                                my \$xslt = XML::XSLT::Wrapper->new();
                                \$render = \$xslt->transform(
                                          XMLFile => '$tempXml',
                                          XSLFile => '$lib/Devel/Diagram/xsl/$xsl.xsl');
                             ";
                        unlink $tempXml;
                        $render =~ s{^.*?<\?xml version="1.0" encoding="UTF-8"\?>\s*}{}si;
                        return $render;
                    } else {
                        eval "die 'Can not find transform file $xsl.xsl\nThis needs to be in $lib/Devel/Diagram/xsl\n'";
                        return $render;
                    }
                }
                eval "die 'Can not find root of Devel::Diagram\nYou did something with \"use lib\" or \"\@INC\"?\n'";
            }
        }
    }

    return $render;
}


#######################################################################################
#######################################################################################
sub PrintAsHtml {
    my $self = shift;
    my $packages = $self->{packages};

    open XML, ">Diagram.html";
    print XML <<EOT;
<html><head>
<style>
.tr { valign:top; }
.td { valign:top; }
</style>
</head><body>
EOT
    print XML "<table border='1'>\n";

    for my $packnam ( sort keys %$packages ) {
        print XML "<tr class='tr'><td class='td' valign='top'>$packnam</td>\n";
        print XML "<td class='td' valign='top'><table>\n";
        for my $baseclass ( sort keys %{$packages->{$packnam}->{_isa}} ) {
            print XML "<tr class='tr'><td class='td' valign='top'>$baseclass</td></tr>\n";
        }
        print XML "</table></td>\n";
        print XML "<td class='td' valign='top'><table>\n";
        for my $method ( sort keys %{$packages->{$packnam}->{_methods}} ) {
            print XML "<tr class='tr'><td class='td' valign='top'>$method</td></tr>\n";
        }
        print XML "</table></td>\n";
        print XML "<td class='td' valign='top'><table>\n";
        for my $member ( sort keys %{$packages->{$packnam}->{_members}} ) {
            print XML "<tr class='tr'><td class='td' valign='top'>$member</td></tr>\n";
        }
        print XML "</table></td></tr>\n";
    }
    print XML "</table></body></html>\n";
    close XML;
}

1;



=pod

=head1 NAME

Devel::Diagram - Discover the classes of an arbitrary suite of Perl modules

=head1 SYNOPSIS

    use Devel::Diagram;

    # Discover classes of a package anchored by a single Perl module.
    #
    $diagram = new Devel::Diagram('CGI');

    # Discover classes of a package anchored by a collection of modules in a folder.
    #
    use Devel::Diagram;
    $diagram = new Devel::Diagram('HTML/');

    # Render the result in your desired format.
    #
    print $diagram->Render('UXF20');

    # Render the result, then transform it via XSL.
    #
    print $diagram->Render('UXF20', 'xsl:uxf20toHtml');

=head1 DESCRIPTION

Devel::Diagram scans the given Perl modules attempting to discover the class structure.
It produces a hash table that can be converted to XML (or other formats) via Render().

An XSL stylesheet is included that converts the XML class diagram into HTML.

See C<eg/Diagram.pl> for a full example of use.

=head1 METHODS

The few methods you need to activate Devel::Diagram.

=head3 new( $moduleSpecifications )

Here you name the Perl module (or suite) you want to process. 
Enter the string you would specify in a 'use' or 'require' statement for this module.

You may enter as many module specifications as you like, separated by commas.

=head3 Render( $renderType [, $transformType] )

Renders the class diagram in the given format.
Currently the only format that is recognized is 'UXF20'.
These can be extended easily by creating a new C<Devel::Diagram::Render::<yourName>> module.

Render() optionally takes a second parameter specifying a transformation on the rendered
format, presumably resulting in a new format. For instance,

    Render('UXF20', 'xsl:uxf20toHtml')

renders the class diagram as UXF20, then runs it through the XSL transform named C<uxf20toHtml.xsl>.

C<Render()> expects to find the XSL stylesheet in the C<xsl> folder of C<Devel::Diagram>.
You need C<XML::XSLT::Wrapper> and an appropriate XSL transform engine to make this work.

Any warnings or errors in the rendering process can be found by investigating C<$@> on return.

=head1 TODO

These are some of the things I think can be done to extend Devel::Diagram.

=over 4

=item XMI format

Currently C<UXF> is the only XML format supported. C<XMI> is another commonly used format (but more complex).

=item Fancy HTML rendering

Perhaps with Javascript and/or server side to assist in browsing the codebase.

=item Class::Struct parsing

Class::Struct is also used to code OO Perl. Need to recognize this structure in the codebase.
There are also several other modules for class creation.

=item Parameters

What are the parameters of the operations?

=item Other parsing

The is more than one way to do it. OO Perl can be implemented in many ways; 
Devel::Diagram recognizes a few of them. 
CPAN is big, really big, so there are OO Perl techniques that Devel::Diagram will not recognize, yet.

=item Other UML diagrams

Collaboration, sequence, etc. (see C<UML::Sequence>).

=item Devel::Diagram all modules of CPAN

Anybody?

=back

=head1 AUTHOR

C<Devel::Diagram> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2003 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=cut


