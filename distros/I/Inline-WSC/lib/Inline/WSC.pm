
package Inline::WSC;

use strict;
use warnings;
use Win32::OLE;
use Digest::MD5 'md5_hex';

our $VERSION      = 0.02;
my $WSC_DIR      = $ENV{TMP} || $ENV{TEMP} || 'C:\Windows\Temp';
die "Temporary directory '$WSC_DIR' does not exist" unless -d $WSC_DIR;
die "Temporary directory '$WSC_DIR' is not writable" unless -w $WSC_DIR;
our $WSC_PREFIX   = 'InlineWin32COM.WSC';
my @ToDelete      = ();
my %MethodMapping = ();

#==============================================================================
# Called when this module is 'use'd:
sub import
{
  my ($s, $language, $code) = @_;
  return unless 
    ( defined($language) && defined($code) ) && 
    ( length($language) && length($code) );
  my $caller = caller;
  my @methods = $s->_init( $language, $code );
  $s->_export_methods( $caller, \@methods );
}# end import()


#==============================================================================
# Alias to import:
*compile = \&import;


#==============================================================================
# Writes the *.wsc file to disk:
sub _init
{
  my ($s, $language, $code) = @_;
  
  my $md5       = md5_hex($code);
  my $classname = "$WSC_PREFIX\_$md5.wsc";
  my @methods   = $s->_get_method_names( $code );
  
  # Die when we encounter function redefinitions:
  foreach( @methods )
  {
    die "Method '$_' was already defined in file '$MethodMapping{$_}'"
      if $MethodMapping{$_};
    $MethodMapping{$_} = $classname;
  }# end foreach()
  
  my $wsc_code = $s->_make_wsc_code( $language, $code, $classname, \@methods );
  my $filename = "$WSC_DIR\\$classname";
  push @ToDelete, $filename;
  open my $ofh, '>', $filename;
  print $ofh $wsc_code;
  close($ofh);
  
  return @methods;
}# end _init()


#==============================================================================
# Assembles the *.wsc code:
sub _make_wsc_code
{
  my ($s, $language, $code, $classname, $methods) = @_;
  
  my $methodcode = join("\n",
    map qq{<method name="$_" />}, @$methods
  );
  
  return <<"EOF";
<?xml version="1.0"?>
<component>
        <registration
                description = "Inline::WSC Class"
                progid = "$classname"
                version = "1.0"
        >
        </registration>
        <public>
$methodcode
        </public>
        <implements type="ASP" id="ASP"/>
        <script language="$language">
<![CDATA[
$code
]]>
        </script>
</component>
EOF
}# end _make_wsc_code()


#==============================================================================
# Scans the code for declarations of functions and subs.
sub _get_method_names
{
  my ($s, $code) = @_;
  my @out = ();
  FUNC: while($code =~ m/\s*(function|sub)\s+([a-z0-9_]+)\s*(?:\(.*?\))?/isgx)
  {
    local $^W = 0;
    push @out, $2;
  }# end while()
  return @out;
}# end _get_method_names()


#==============================================================================
# Pollute the caller's namespace with the methods defined in the various code 
# fragments we were passed.
sub _export_methods
{
  my ($s, $caller, $methods) = @_;
  no strict 'refs';
  foreach my $method ( @$methods )
  {
    my $WscClass = $MethodMapping{$method};
    my $ob = Win32::OLE->GetObject("script:$WSC_DIR\\$WscClass")
      or die "Couldn't create OLE '$WscClass':\n" . Win32::GetLastError . " ";
    # The sub exists as a closure - saves us the call to GetObject() every time
    # the method is called:
    *{"$caller\::$method"} = sub {
      return $ob->$method(@_);
    };
  }# end foreach()
}# end _export_methods()

1;# return true:

__END__

=pod

=head1 NAME

Inline::WSC - Use JavaScript and VBScript from within Perl

=head1 SYNOPSIS

  use Inline::WSC VBScript => <<'MyVBScript';
  
    ' Say hello:
    Function Hello( ByVal Name )
      Hello = "Hello, " & Name
    End Function
    
    ' Handy method here:
    Function AsCurrency( ByVal Amount )
      AsCurrency = FormatCurrency( Amount )
    End Function
  
  MyVBScript
  
  print Hello("John") . " gets " . AsCurrency( 100000 ) . "\n";
  
  # You may also use the 'compile' method directly:
  Inline::WSC->compile( JScript => q~
    function greet( name ) {
      return "Hello, " + name + "!";
    }// end greet( name )
  ~);
  print greet( 'John' ) . "\n";

=head1 DISCUSSION

C<Inline::WSC> was originally intended to add a scriptable runtime to a larger
project.  

Code fragments may be written in VBScript, JavaScript, JScript or PerlScript.
PerlScript is only an option if you have installed the PerlScript COM extension
that ships with ActiveState's ActivePerl distribution for Windows.

=head1 HOW IT WORKS

C<Inline::WSC> creates a Windows Script Component (WSC) using the code you pass 
it, and creates Perl stubs to access the methods in the WSC from the calling class.

Functions and subroutines defined within the code fragments are available 
within the caller's namespace.

=head1 RETURNING OBJECTS

Say you have the following VBScript:

  Function ReturnsObject()
    Dim obj : Set obj = CreateObject("Scripting.Dictionary")
    obj.Add "Age", 28
    obj.Add "Location", "Denver"
    Set ReturnsObject = obj
  End Function

If you called that function like so:

  my $obj = ReturnsObject();

You could access its elements like any other Win32::OLE object:

  print $obj->Item("Age");
  print $obj->Item("Location");

=head1 CAVEATS

=head2 Uniqueness of Function Names

Make sure all your methods have unique names.

If you pass C<Inline::WSC> fragments of code that define the same 
function/sub name more than once, you will get an error that looks like:

  Method 'foo' was already defined in file 'InlineWin32COM.WSC_...wsc'

=head2 Perl Method Visibility

Methods defined in your Perl code B<are not available> to the inlined code.

=head2 Inline-to-Inline Method Visibility

Inlined methods B<cannot> call other inlined methods.

=head2 Parameter Lists

You can only pass strings and numbers to the inlined functions.

=head2 Reserved keywords

Do not use the words "sub" or "function" in the comments within your COM code.
The regular expression used to parse out the function names is too simple and 
will result in errors that look like this:

  Couldn't create OLE 'InlineWin32COM.WSC_...wsc':
  317  at Inline/Win32COM.pm line xx.

=head1 SEE ALSO

=item * Microsoft's Windows Script Component section on MSDN:

http://msdn.microsoft.com/library/en-us/script56/html/c52b52d3-e11d-49f1-96c8-69b3c9ce8ade.asp

=head1 AUTHOR

John Drago L<jdrago_999@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 John Drago.  All rights reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

