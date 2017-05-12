#######################################################################
# Created on:  Apr 20, 2006
# Package:     HoneyClient::Util::Config
# File:        Config.pm
# Description: Generic access to the HoneyClient configuration file.
#
# CVS: $Id: Config.pm 781 2007-07-27 19:15:54Z kindlund $
#
# @author kindlund, flindiakos
#
# Copyright (C) 2007 The MITRE Corporation.  All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation, using version 2
# of the License.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301, USA.
#
#######################################################################

=pod

=head1 NAME

HoneyClient::Util::Config - Perl extension to provide a generic interface
to the HoneyClient global configuration file.

=head1 VERSION

This documentation refers to HoneyClient::Util::Config version 0.98.

=head1 SYNOPSIS

  use HoneyClient::Util::Config qw(getVar);

  my $address = undef;
  
  # Fetch the value of "address" using the default namespace.
  $address = getVar(name => "address");

  # Fetch the value of "address" using the "HoneyClient::Agent::Driver" namespace.
  $address = getVar(name      => "address", 
                    namespace => "HoneyClient::Agent::Driver");

  # Fetch the value of "address" using the "HoneyClient::Manager" namespace.
  $address = getVar(name      => "address", 
                    namespace => "HoneyClient::Manager");

  # Set the value of "address" using the default namespace
  setVar( name  => 'address',
          value => 'new_address' );

  # Set the value using a specified namespace
  setVar( name      => 'address',
          namespace => 'HoneyClient::Agent::Driver',
          value     => 'new_address' );

=head1 DESCRIPTION

This library allows any HoneyClient module to quickly access the
global configuration options, associated with this program.

This library makes extensive use of the XML::XPath module.

=cut

package HoneyClient::Util::Config;

use strict;
use warnings;
use Carp ();
use XML::XPath;
use XML::Tidy;
use Log::Log4perl qw(:easy);
use Sys::Syslog;
use Data::Dumper;
use Log::Dispatch::Syslog;

#######################################################################
# Module Initialization                                               #
#######################################################################

BEGIN {
    # Defines which functions can be called externally.
    require Exporter;
    our (@ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS, $VERSION);

    # Set our package version.
    $VERSION = 0.98;

    @ISA = qw(Exporter);

    # Symbols to export automatically
    @EXPORT = qw(getVar setVar);

    # Items to export into callers namespace by default. Note: do not export
    # names by default without a very good reason. Use EXPORT_OK instead.
    # Do not simply export all your public functions/methods/constants.

    # This allows declaration use HoneyClient::Util::Config ':all';
    # If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
    # will save memory.

    %EXPORT_TAGS = (
        'all' => [ qw(getVar setVar) ],
    );

    # Symbols to autoexport (when qw(:all) tag is used)
    @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

    $SIG{PIPE} = 'IGNORE'; # Do not exit on broken pipes.
}
our (@EXPORT_OK, $VERSION);

=pod

=begin testing

# Make sure Log::Log4perl loads
BEGIN { use_ok('Log::Log4perl', qw(:nowarn))
        or diag("Can't load Log::Log4perl package. Check to make sure the package library is correctly listed within the path.");
       
        # Suppress all logging messages, since we need clean output for unit testing.
        Log::Log4perl->init({
            "log4perl.rootLogger"                               => "DEBUG, Buffer",
            "log4perl.appender.Buffer"                          => "Log::Log4perl::Appender::TestBuffer",
            "log4perl.appender.Buffer.min_level"                => "fatal",
            "log4perl.appender.Buffer.layout"                   => "Log::Log4perl::Layout::PatternLayout",
            "log4perl.appender.Buffer.layout.ConversionPattern" => "%d{yyyy-MM-dd HH:mm:ss} %5p [%M] (%F:%L) - %m%n",
        });
}
require_ok('Log::Log4perl');
use Log::Log4perl qw(:easy);

# Make sure the module loads properly, with the exportable
# functions shared.
BEGIN { use_ok('HoneyClient::Util::Config', qw(getVar setVar)) 
        or diag("Can't load HoneyClient::Util::Config package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('HoneyClient::Util::Config');
can_ok('HoneyClient::Util::Config', 'getVar');
can_ok('HoneyClient::Util::Config', 'setVar');
use HoneyClient::Util::Config qw(getVar setVar);

# Suppress all logging messages, since we need clean output for unit testing.
Log::Log4perl->init({
    "log4perl.rootLogger"                               => "DEBUG, Buffer",
    "log4perl.appender.Buffer"                          => "Log::Log4perl::Appender::TestBuffer",
    "log4perl.appender.Buffer.min_level"                => "fatal",
    "log4perl.appender.Buffer.layout"                   => "Log::Log4perl::Layout::PatternLayout",
    "log4perl.appender.Buffer.layout.ConversionPattern" => "%d{yyyy-MM-dd HH:mm:ss} %5p [%M] (%F:%L) - %m%n",
});

# Make sure XML::XPath loads.
BEGIN { use_ok('XML::XPath') 
        or diag("Can't load XML::XPath package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('XML::XPath');
can_ok('XML::XPath', 'findnodes');
use XML::XPath;

# Make sure XML::Tidy loads
BEGIN { use_ok('XML::Tidy')
        or diag("Can't load XML::Tidy package. Check to make sure the package library is correctly listed within the path."); }
require_ok('XML::Tidy');
can_ok('XML::Tidy','tidy');
can_ok('XML::Tidy','write');
use XML::Tidy;

# Make sure Sys::Syslog loads
BEGIN { use_ok('Sys::Syslog')
        or diag("Can't load Sys::Syslog package. Check to make sure the package library is correctly listed within the path."); }
require_ok('Sys::Syslog');
use Sys::Syslog;

# Make sure Data::Dumper loads
BEGIN { use_ok('Data::Dumper')
        or diag("Can't load Data::Dumper package. Check to make sure the package library is correctly listed within the path."); }
require_ok('Data::Dumper');
use Data::Dumper;

# Make sure Log::Dispatch::Syslog loads
BEGIN { use_ok('Log::Dispatch::Syslog')
        or diag("Can't load Log::Dispatch::Syslog package. Check to make sure the package library is correctly listed within the path."); }
require_ok('Log::Dispatch::Syslog');
use Log::Dispatch::Syslog;

=end testing

=cut

#######################################################################

# Global Configuration Variables

# Relative path to the Global Configuration.
# Note: We leave this path relative, so that
# corresponding unit testing can work before
# we actually install the configuration
# file into /etc.
our $CONF_FILE = "etc/honeyclient.xml";

# The XPath object that points to the config file
our $xp;

# Temporarily Initialize Logging Subsystem
# Note: We use these sane values initially, until we can reinitialize
#       the logger with values from the global configuration file.
Log::Log4perl->init_once({
    "log4perl.rootLogger"                               => "INFO, Screen",
    "log4perl.appender.Screen"                          => "Log::Log4perl::Appender::ScreenColoredLevels",
    "log4perl.appender.Screen.stderr"                   => 0,
    "log4perl.appender.Screen.Threshold"                => "INFO",
    "log4perl.appender.Screen.layout"                   => "Log::Log4perl::Layout::PatternLayout",
    "log4perl.appender.Screen.layout.ConversionPattern" => "%d{yyyy-MM-dd HH:mm:ss} %5p [%M] (%F:%L) - %m%n",
});

# The global logging object.
our $LOG = get_logger();

# Make Dumper format more terse.
$Data::Dumper::Terse = 1;
$Data::Dumper::Indent = 0;

#######################################################################
# Private Methods Implemented                                         #
#######################################################################

# Helper function designed to read the global configuration file
#
# Inputs: config
# Outputs: None
sub _parseConfig {

    # Extract arguments.
    my ($class, $config) = @_;

    # Sanity check.  Make sure the file exists.
    if (!-f $config) {
        # Okay, if the relative path didn't work, try the absolute
        # path.
        $config = "/" . $config;
        if (!-f $config) {
            $LOG->fatal("Unable to parse global configuration file ($CONF_FILE)!");
            Carp::croak("Error: Unable to parse global configuration file ($CONF_FILE)!");
        }
        # The absolute path worked, update the global variable to reflect this.
        $CONF_FILE = $config;
    }

    # Read in the configuration settings.
    eval {
        $xp = XML::XPath->new(filename => $CONF_FILE);
    };

    # Sanity check
    if ($@ || !$xp->exists("HoneyClient")) {
        $LOG->fatal("Unable to parse global configuration file ($CONF_FILE)!" . $@);
        Carp::croak("Error: Unable to parse global configuration file ($CONF_FILE)!" . $@);
    }
}

# Helper function designed to check the arguments passed to getVar()
#
# Inputs: $args
# Outputs: None
sub _checkArgs{
    # Hashref of arguments
    our ($args) = @_;

    # Make sure we have args
    if (!%$args) {
        $LOG->fatal("No variables specified!");
        Carp::croak("Error: No variables specified!");
    }

    # Process the args
    #   If you do not specify a default value, it will croak if undefined
    _process('name');
    _process('namespace', caller(1)); # We want the namespace of the caller to getVar(),
                                      # not of the caller to _checkArgs(); hence, we
                                      # use caller(1).

    # Add any special statements to check for depending on the caller
    # Just specify the calling sub in the regex and any operations in the do{}
    #   Why can't perl actually have switch statements :(
    for((split(/::/,((caller(1))[3])))[-1]){
        /getVar/    && do {  };
        /setVar/    && do { _process('value') };
    }


    # Accepts the key to check and the default value.
    # If no default value is given, undef will be used
    sub _process{ 
        my ($name, $val) = @_;
        if ( !defined($args->{$name} )) { 
            $args->{$name} = $val; 

            # Sanity checking after
            unless( $args->{$name} ) { 
                $LOG->fatal("No variable $name specified!"); 
                Carp::croak("Error: No variable $name specified!"); 
            }
        } 
    }
}

#######################################################################
# Public Methods Implemented                                          #
#######################################################################

=pod

=head1 EXPORTS

=head2 getVar(name => $varName, namespace => $caller, attribute => $attribute)

=over 4

If $attribute is undefined or not specified, then this function will
attempt to retrieve the contents of the B<element> $varName, as it is set
within the HoneyClient global configuration file.

If $attribute is defined, then this function will attempt to retrieve 
specified B<attribute> listed within the contents the contents of the
element $varName, as it is set within the HoneyClient global configuration
file.

If $caller is undefined or not specified, then this function may return
different values, depending upon which module is calling this function.

For example, if module HoneyClient::Agent::Driver calls this function
as getVar(name => "address"), then this function will attempt to search for
a value like the following, within the global configuration file:

  <HoneyClient>
      <Agent>
          <Driver>
              <address>localhost</address>
          </Driver>
      </Agent>
  </HoneyClient>

If the "address" value is not found at this level within the XML tree,
then the function will attempt to locate values, like the following:

# First try:

  <HoneyClient>
      <Agent>
          <address>localhost</address>
      </Agent>
  </HoneyClient>

# Last try:

  <HoneyClient>
      <address>localhost</address>
  </HoneyClient>

This function will stop its recursive search at the first value found,
closest to the child module's XML namespace.

Even after performing a recursive search, if no variable name exists,
then the function will issue a warning and return undef.

If the variable found is an element that contains child elements, then
a corresponding hashtable will be returned.  For example, if we perform
a getVar(name => "foo") on the following XML:

  <HoneyClient>
      <foo>
          <bar>123</bar>
          <bar>456</bar>
          <yok>789</yok>
          <yok>xxx</yok>
      </foo>
  </HoneyClient>

Then the following $hashref will be returned:

  $hashref = {
      'bar' => [ '123', '456' ],
      'yok' => [ '789', 'xxx' ],
  }

I<Inputs>:
 B<$varName> is the variable name to search for, within the global 
configuration file.
 B<$caller> is an optional argument, signifying the module namespace 
to use, when searching for the variable's value.
 B<$attribute> is an optional argument, signifying that the function
should return the attribute associated with the variable's element.

I<Output>: The variable's element/attribute value or hashtable (for 
multi-value elements), if found; warns and returns undef otherwise.

B<Note>: If the target variable to return is an element that contains
B<combinations> of text and sub-elements, then only the text within
the sub-elements will be returned in the previously mentioned
$hashref format.

For example, if we perform a getVar(name => "foo") on the following XML:

  <HoneyClient>
      <foo>
          THIS_TEXT_WILL_BE_LOST
          <bar>123</bar>
          <bar>456</bar>
          <yok>789</yok>
          <yok>xxx</yok>
          <yok><CHILD>zzz</CHILD></yok>
      </foo>
  </HoneyClient>

Then the following $hashref will be returned:

  $hashref = {
      'bar' => [ '123', '456' ],
      'yok' => [ '789', 'xxx', 'zzz' ],
  }

Notice how the B<THIS_TEXT_WILL_BE_LOST> string got dropped and that
the B<E<lt>CHILDE<gt>> tags were silently stripped from the B<zzz>
string.  In other words, in each target element, B<don't mix text
with sub-elements> and B<don't nest sub-elements> if you want the 
nested structure preserved when a getVar() is called on the
B<grandparent element>.

=back

=begin testing

my $value = getVar(name => "address", namespace => "HoneyClient::Util::Config::Test");
is($value, "localhost", "getVar(name => 'address', namespace => 'HoneyClient::Util::Config::Test')") 
    or diag("The getVar() call failed.  Attempted to get variable 'address' using namespace 'HoneyClient::Util::Config::Test' within the global configuration file.");

$value = getVar(name => "address", namespace => "HoneyClient::Util::Config::Test", attribute => 'default');
is($value, "localhost", "getVar(name => 'address', namespace => 'HoneyClient::Util::Config::Test', attribute => 'default')") 
    or diag("The getVar() call failed.  Attempted to get attribute 'default' for variable 'address' using namespace 'HoneyClient::Util::Config::Test' within the global configuration file.");

# This check tests to make sure getVar() is able to use valid output
# from undefined namespaces (but where some of the parent namespace is
# partially known).
$value = getVar(name => "address", namespace => "HoneyClient::Util::Config::Test::Undefined::Child", attribute => 'default');
is($value, "localhost", "getVar(name => 'address', namespace => 'HoneyClient::Util::Config::Test::Undefined::Child', attribute => 'default')") 
    or diag("The getVar() call failed.  Attempted to get attribute 'default' for variable 'address' using namespace 'HoneyClient::Util::Config::Test::Undefined::Child' within the global configuration file.");

# This check tests to make sure getVar() returns the expected hashref
# when getting data from a target element that contains child sub-elements.
$value = getVar(name => "Yok", namespace => "HoneyClient::Util::Config::Test");
my $expectedValue = {
    'childA' => [ '12345678', 'ABCDEFGH' ],
    'childB' => [ '09876543', 'ZYXVTUWG' ],
};
is_deeply($value, $expectedValue, "getVar(name => 'Yok', namespace => 'HoneyClient::Util::Config::Test')") 
    or diag("The getVar() call failed.  Attempted to get variable 'Yok' using namespace 'HoneyClient::Util::Config::Test' within the global configuration file.");

=end testing

=cut

sub getVar {

    # Get the arguments and check their validity
    my (%args) = @_;
    _checkArgs(\%args);

    # Log resolved arguments.
    $LOG->debug(sub {
        # Make Dumper format more terse.
        $Data::Dumper::Terse = 1;
        $Data::Dumper::Indent = 0;
        Dumper(\%args);
    });
    
    # Get a copy of the original namespace.
    my $namespace = $args{namespace};

    # Fix the namespace so it is compatible with XPath
    $namespace =~ s/::/\//g; # Turn package delim :: into XPath delim /

    # Split the namespace into an array.
    my @ns = split(/\//, $namespace);

    # Check to make sure the namespace exists within our XML configuration.
    # XML::XPath does not know how to deal with unknown paths (even if the parent
    # path is known).  Thus, we recursively check the path's existance, providing
    # the first valid ancestor path found.
    while (!$xp->exists($namespace) and
           (scalar(@ns) > 1)) {
        pop(@ns);
        $namespace = join('/', @ns);
        @ns = split(/\//, $namespace);
    }

    # Get the nodeset that we need
    # The first string is the path that matches the node we want and all ancestors
    # The second string tells us whether to get the text() or an attribute
    my $exp = $namespace . "/ancestor-or-self::*/$args{name}" .
        (defined $args{attribute} ? "/attribute::" . $args{attribute} : "");
    my $nodeset = $xp->findnodes($exp);

    # The list of nodes required.  Because this is a top down list of the results,
    # if there are multiple results, we want the bottom one (most specific)
    if ($nodeset->size() == 0) {
        $LOG->warn("Warning: Unable to locate specified value in variable '" . 
                   $args{'name'} . "' using namespace '" . $args{'namespace'} . 
                   "' within the global configuration file ($CONF_FILE)!");
        return;
    }
    
    # Figure out if the (most specific) node has any children.
    my $parent = $nodeset->pop();
    $nodeset = $xp->findnodes("*", $parent);
    my $val = undef;
    if ($nodeset->size() <= 0) {
        # There are no child elements, thus stingify
        # all textual components.

        $val = $parent->string_value();

        # Trail leading and trailing whitespace 
        $val =~ s/^\s+|\s+$//g;
    } else { 

        # There are child elements; return a
        # hashtable accordingly.
        my @children = $nodeset->get_nodelist();

        # Now, build the hashtable of array references.
        $val = {};
        foreach my $child (@children) {
            push  (@{$val->{$child->getName()}}, $child->string_value());
        }
    }

    return $val;
}

=pod

=head2 setVar(name => $varName, namespace => $caller, attribute => $attribute, value => $value)

=over 4

This will set the desired value.
If the required attribute or element does not exist, it (and any parents) will be created

I<Inputs>:
 B<$varName> is the variable name to search for, within the global 
configuration file.
 B<$caller> is an optional argument, signifying the module namespace 
to use, when searching for the variable's value.
 B<$attribute> is an optional argument, signifying that the function
should return the attribute associated with the variable's element.
 B<$value> is the value to set the element or attribute to

=back

=begin testing

# Test setting an existing value
my $oldval = getVar(name => 'address', namespace => 'HoneyClient::Util::Config::Test' );
setVar(name => 'address', namespace => 'HoneyClient::Util::Config::Test', value => 'foobar' );
my $value = getVar(name => 'address', namespace => 'HoneyClient::Util::Config::Test' );
is($value, 'foobar', "setVar(name => 'address', namespace => 'HoneyClient::Util::Config::Test', value => 'foobar' )") 
    or diag("The setVar() call failed.  Attempted to set variable 'address' using namespace 'HoneyClient::Util::Config::Test' to 'foobar' within the global configuration file.");
setVar(name => 'address', namespace => 'HoneyClient::Util::Config::Test', value => $oldval );

# Test setting an attribute
$oldval = getVar(name => 'address', attribute => 'default', namespace => 'HoneyClient::Util::Config::Test' );
setVar(name => 'address', namespace => 'HoneyClient::Util::Config::Test', attribute => 'default', value => 'foobar' );
$value = getVar(name => 'address', attribute => 'default', namespace => 'HoneyClient::Util::Config::Test' );
is($value, 'foobar', "setVar(name => 'address', namespace => 'HoneyClient::Util::Config::Test', attribute => 'default', value => 'foobar' )")
    or diag("The setVar() call failed.  Attempted to set 'default' attribute of variable 'address' using namespace 'HoneyClient::Util::Config::Test' to 'foobar' within the global configuration file.");
setVar(name => 'address', namespace => 'HoneyClient::Util::Config::Test', attribute => 'default', value => $oldval );

# Test creating a value
setVar(name => 'zingers', namespace => 'HoneyClient::Util::Config::Test', value => 'foobar');
$value = getVar(name => 'zingers', namespace => 'HoneyClient::Util::Config::Test' );
is($value, 'foobar', "setVar(name => 'zingers', namespace => 'HoneyClient::Util::Config::Test', value => 'foobar' )") 
    or diag("The setVar() call failed.  Attempted to create variable 'zing' using namespace 'HoneyClient::Util::Config::Test' with a value of 'foobar' within the global configuration file.");

# Test creating an attribute
setVar(name => 'address', namespace => 'HoneyClient::Util::Config::Test', attribute => 'zing', value => 'foobar');
$value = getVar(name => 'address', attribute => 'zing', namespace => 'HoneyClient::Util::Config::Test' );
is($value, 'foobar', "setVar(name => 'address', namespace => 'HoneyClient::Util::Config::Test', attribute => 'zing', value => 'foobar' )")
    or diag("The setVar() call failed.  Attempted to create attribute 'zing' using namespace 'HoneyClient::Util::Config::Test' with a value of 'foobar' within the global configuration file.");

# Creating new namespaces
setVar(name => 'address', namespace => 'HoneyClient::Util::Config::Test::Foo::Bar', value => 'baz');
$value =  getVar(name => 'address', namespace => 'HoneyClient::Util::Config::Test::Foo::Bar');
is($value, 'baz', "setVar(name => 'address', namespace => 'HoneyClient::Util::Config::Test::Foo::Bar', value => 'baz')")
    or diag("The setVar() call failed.  Attempted to create attribute 'address' using namespace 'HoneyClient::Util::Config::Test::Foo::Bar' with a value of 'baz' within global configuration file.");

=end testing

=cut

sub setVar {
    # Get the arguments and check their validity
    my (%args) = @_;
    _checkArgs(\%args);

    # Log resolved arguments.
    $LOG->debug(sub {
        # Make Dumper format more terse.
        $Data::Dumper::Terse = 1;
        $Data::Dumper::Indent = 0;
        Dumper(\%args);
    });

    # Fix the namespace so it is compatible with XPath
    my $namespace = $args{namespace};
    $namespace =~ s/::/\//g; # Turn package delim :: into XPath delim /

    # Get the nodeset that we need
    # The first string is the path that matches the node we want
    # The second string tells us whether to get the text() or an attribute
    my $exp = $namespace . "/$args{name}" .
        (defined $args{attribute} ? "/attribute::" . $args{attribute} : "");
    if(!$xp->exists($exp)){
        $xp->createNode($exp);
    }
    $xp->setNodeText($exp,$args{value});

    # Create the tidy object with our document root and write out the stuff to the new conf_file
    my $tidy_obj = XML::Tidy->new(context => $xp->find('/'));
    $tidy_obj->tidy('    ');
    $tidy_obj->write($CONF_FILE);

    # Parse the conf_file again just for good measure
    _parseConfig(undef, $CONF_FILE);
}

#######################################################################

# Parse the global configuration file, upon using the package.
_parseConfig(undef, $CONF_FILE);

# Reinitialize Logging Subsystem
# TODO: Need to account for absolute "/etc" directories!
Log::Log4perl->init(getVar(name => "log_config"));

# Initialize Syslog Support
$Sys::Syslog::host = getVar(name => "syslog_address");

1;

#######################################################################
# Additional Module Documentation                                     #
#######################################################################

__END__

=head1 BUGS & ASSUMPTIONS

This module assumes the HoneyClient global configuration file is located
in: /etc/honeyclient_log.conf

The getVar($varName) function will attempt to get a module-specific
variable setting, first.  If that setting is not specified, the function
call will recursively search for the same variable located within any 
parent (or global) regions of the configuration file.

Furthermore, getVar() returns hashrefs for target elements that contain
additional child sub-elements.  However, the format of this hashref
is B<NOT> necessarily intuitive.  See the getVar() documentation for 
further details.

=head1 SEE ALSO

L<http://www.honeyclient.org/trac>

XML::XPath

=head1 REPORTING BUGS

L<http://www.honeyclient.org/trac/newticket>

=head1 AUTHORS

Darien Kindlund, E<lt>kindlund@mitre.orgE<gt>

Fotios Lindiakos, E<lt>flindiakos@mitre.orgE<gt>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2007 The MITRE Corporation.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation, using version 2
of the License.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
02110-1301, USA.


=cut

<!--
    vim: foldmarker==pod,=cut
-->
