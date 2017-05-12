#-----------------------------------------------------------------
# MOSES::MOBY::Base
# Author: Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer see below.
#
# $Id: Base.pm,v 1.6 2008/11/06 18:32:33 kawas Exp $
#-----------------------------------------------------------------

package MOSES::MOBY::Base;

use strict;

use HTTP::Date;

use vars qw( $VERSION $Revision $AUTOLOAD @EXPORT @ISA );
use vars qw( $LOG $LOGGER_NAME $CONFIG_NAMESPACE );

# names of attribute's types
use constant STRING   => 'string';
use constant INTEGER  => 'integer';
use constant FLOAT    => 'float';
use constant BOOLEAN  => 'boolean';
use constant DATETIME => 'datetime';

# names of attribute's properties
use constant TYPE     => 'type';
use constant POST     => 'post';
use constant ISARRAY  => 'is_array';
use constant READONLY => 'readonly';

use overload q("") => "as_string";

BEGIN { 
    @ISA = qw( Exporter );
    @EXPORT = qw( $LOG );

    $VERSION = sprintf "%d.%02d", q$Revision: 1.6 $ =~ /: (\d+)\.(\d+)/;
    $Revision  = '$Id: Base.pm,v 1.6 2008/11/06 18:32:33 kawas Exp $';

    # initiate error handling
    require Carp; import Carp qw( confess );

    # read default configuration file and import configuration
    # parameters into 'MOBYCFG namespace'
    use MOSES::MOBY::Config;
    $CONFIG_NAMESPACE = 'MOBYCFG';
    sub init_config {
	shift;   # invocant ignored
	MOSES::MOBY::Config->init (@_);
	MOSES::MOBY::Config->import_names ($CONFIG_NAMESPACE);
    }
    MOSES::MOBY::Base->init_config;

    # initiate logging
    use Log::Log4perl qw(get_logger :levels :no_extra_logdie_message);
    $LOGGER_NAME = 'services';
    sub init_logging {
	if ($MOBYCFG::LOG_CONFIG) {
	    eval { Log::Log4perl->init ($MOBYCFG::LOG_CONFIG) };
	    $LOG = get_logger ($LOGGER_NAME) and return unless $@;
	    print STDERR "Problem with configuration file '$MOBYCFG::LOG_CONFIG': $@\n";
	}
	# configuration for logging not found; make some easy logging
	my $logfile = $MOBYCFG::LOG_FILE;
	my $loglevel = $MOBYCFG::LOG_LEVEL || $ERROR;
	my $pattern = $MOBYCFG::LOG_PATTERN || '%d (%r) %p> [%x] %F{1}:%L - %m%n';
	$LOG = get_logger ($LOGGER_NAME);
	$LOG->level (uc $loglevel);
	my $appender =
	    ($logfile and $logfile !~ /^stderr$/i) ?
	     Log::Log4perl::Appender->new ("Log::Log4perl::Appender::File",
					   name     => 'Log',
					   filename => $logfile,
					   mode     => 'append') :
	     Log::Log4perl::Appender->new ("Log::Log4perl::Appender::Screen",
					   name     => 'Screen');
	$LOG->add_appender ($appender);
	my $layout = Log::Log4perl::Layout::PatternLayout->new ($pattern);
	$appender->layout ($layout);
    }
    MOSES::MOBY::Base->init_logging;
}


#-----------------------------------------------------------------
# These methods are called by set/get methods of the sub-classes. If
# it comes here, it indicates that an attribute being get/set does not
# exist.
#-----------------------------------------------------------------

{
    my %_allowed =
	(
	 );

    sub _accessible {
	my ($self, $attr) = @_;
	exists $_allowed{$attr};
    }
    sub _attr_prop {
	my ($self, $attr_name, $prop_name) = @_;
	my $attr = $_allowed {$attr_name};
	return ref ($attr) ? $attr->{$prop_name} : $attr if $attr;
	return undef;
    }
}

#-----------------------------------------------------------------
# new
#-----------------------------------------------------------------
sub new {
    my ($class, @args) = @_;
#    $LOG->debug ("NEW: $class - " . join (", ", @args)) if $LOG->is_debug;

    # create an object
    my $self = bless {}, ref ($class) || $class;

    # initialize the object
    $self->init();

    # set all @args into this object with 'set' values
    my (%args) = (@args == 1 ? (value => $args[0]) : @args);
    foreach my $key (keys %args) {
        no strict 'refs'; 
        $self->$key ($args {$key});
    }

    # done
    return $self;
}

#-----------------------------------------------------------------
# init
#-----------------------------------------------------------------
sub init {
    my ($self) = shift;
}

#-----------------------------------------------------------------
# toString
#-----------------------------------------------------------------
sub toString {
    my ($self, $something_else) = @_;
    require Data::Dumper;
    if ($something_else) {
	return Data::Dumper->Dump ( [$something_else], ['M']);
    } else {
	return Data::Dumper->Dump ( [$self], ['M']);
    }
}

#-----------------------------------------------------------------
# module_name_escape
#-----------------------------------------------------------------
sub module_name_escape {
    my ($self, $name) = @_;
    $name =~ tr/-/_/;
    return $name;
}

#-----------------------------------------------------------------
# datatype2module
#-----------------------------------------------------------------
sub datatype2module {
    my ($self, $datatype_name) = @_;
    return undef unless $datatype_name;
    return 'MOSES::MOBY::Data::' . $self->module_name_escape ($datatype_name);
}

#-----------------------------------------------------------------
# service2module
#-----------------------------------------------------------------
sub service2module {
    my ($self, $authority, $service_name) = @_;

    # default values that will be, at the end, however, rarely used
    $authority    = 'org.biomoby.service' unless $authority;
    $service_name = 'TheService' unless $service_name;

    return
	join ('::', reverse split (/\./, $self->module_name_escape ($authority))) .
	'::' .
	$service_name .
	'Base';
}

#-----------------------------------------------------------------
# escape_name
#-----------------------------------------------------------------
sub escape_name {
    my ($self, $name) = @_;
    $name =~ s/\W/_/g;
    return ($name =~ /^\d/ ? "_$name" : $name);
}


#-----------------------------------------------------------------
#
#  Error handling
#
#-----------------------------------------------------------------

my $DEFAULT_THROW_WITH_LOG   = 0;
my $DEFAULT_THROW_WITH_STACK = 1;

#-----------------------------------------------------------------
# throw
#-----------------------------------------------------------------
sub throw {
   my ($self, $msg) = @_;
   $msg .= "\n" unless $msg =~ /\n$/;

   # make an instance, if called as a class method
   unless (ref $self) {
       no strict 'refs'; 
       $self = $self->new;
   }

   # add (optionally) stack trace
   $msg ||= 'An error.';
   my $with_stack = (defined $self->enable_throw_with_stack ?
		     $self->enable_throw_with_stack :
		     $DEFAULT_THROW_WITH_STACK);
   my $result = ($with_stack ? $self->format_stack ($msg) : $msg);

   # die or log and die?
   my $with_log = (defined $self->enable_throw_with_log ?
		   $self->enable_throw_with_log :
		   $DEFAULT_THROW_WITH_LOG);
   if ($with_log) {
       $LOG->logdie ($result);
   } else {
       die ($result);
   }
}

#-----------------------------------------------------------------
# Some throwing options
#
#    These options are not set by using AUTOLOAD (as other regular
#    attributes) because AUTOLOAD could raise exception and we would be
#    in a deep..., well deep recursion.
#
#    Default values are: NO  enable_throw_with_log
#                        YES enable_throw_with_stack
#    (but they are globally changeable by calling
#     default_throw_with_log and default_throw_with_stack)
#
#-----------------------------------------------------------------
sub enable_throw_with_log {
    my ($self, $value) = @_;
    $self->{enable_throw_with_log} = ($value ? 1 : 0)
	if (defined $value);
    return $self->{enable_throw_with_log};
}

sub default_throw_with_log {
    my ($self, $value) = @_;
    $DEFAULT_THROW_WITH_LOG = ($value ? 1 : 0)
	if defined $value;
    return $DEFAULT_THROW_WITH_LOG;
}

sub enable_throw_with_stack {
    my ($self, $value) = @_;
    $self->{enable_throw_with_stack} = ($value ? 1 : 0)
	if defined $value;
    return $self->{enable_throw_with_stack};
}

sub default_throw_with_stack {
    my ($self, $value) = @_;
    $DEFAULT_THROW_WITH_STACK = ($value ? 1 : 0)
	if defined $value;
    return $DEFAULT_THROW_WITH_STACK;
}

#-----------------------------------------------------------------
# format_stack
#-----------------------------------------------------------------
sub format_stack {
    my ($self, $msg) = @_;
    my $stack = $self->_reformat_stacktrace ($msg);
    my $class = ref ($self) || $self;

    my $title = "------------- EXCEPTION: $class -------------";
    my $footer = "\n" . '-' x CORE::length ($title);
    return "\n$title\nMSG: $msg\n" . $stack . $footer . "\n";
}


#-----------------------------------------------------------------
# _reformat_stacktrace
#    Taken from bioperl.
#
#  Takes one argument - an error message. It uses it to remove its
#  repeated occurences from each line (not to print it).
#
#  Reformatting of the stack:
#    1. Shift the file:line data in line i to line i+1.
#    2. change xxx::__ANON__() to "try{} block"
#    3. skip the "require" and "Error::subs::try" stack entries (boring)
#  This means that the first line in the stack won't have
#  any file:line data.
#-----------------------------------------------------------------
sub _reformat_stacktrace {
    my ($self, $msg) = @_;
    my $stack = Carp->longmess;
    $stack =~ s/\Q$msg//;
    my @stack = split( /\n/, $stack);
    my @new_stack = ();
    my ($method, $file, $linenum, $prev_file, $prev_linenum);
    my $stack_count = 0;
    foreach my $i ( 0..$#stack ) {
        if ( ($stack[$i] =~ /^\s*([^(]+)\s*\(.*\) called at (\S+) line (\d+)/) ||
	      ($stack[$i] =~ /^\s*(require 0) called at (\S+) line (\d+)/) ) {
            ($method, $file, $linenum) = ($1, $2, $3);
            $stack_count++;
        } else {
            next;
        }
        if( $stack_count == 1 ) {
            push @new_stack, "STACK: $method";
            ($prev_file, $prev_linenum) = ($file, $linenum);
            next;
        }

        if( $method =~ /__ANON__/ ) {
            $method = "try{} block";
        }
        if( ($method =~ /^require/ and $file =~ /Error\.pm/ ) ||
            ($method =~ /^Error::subs::try/ ) )   {
            last;
        }
        push @new_stack, "STACK: $method $prev_file:$prev_linenum";
        ($prev_file, $prev_linenum) = ($file, $linenum);
    }
    push @new_stack, "STACK: $prev_file:$prev_linenum";

    return join "\n", @new_stack;
}

#-----------------------------------------------------------------
# Set methods test whether incoming value is of a correct type.
# Here we return message explaining that it isn't.
#-----------------------------------------------------------------
sub _wrong_type_msg {
    my ($self, $given_type_or_value, $expected_type, $method) = @_;
    my $msg = 'In method ';
    if (defined $method) {
	$msg .= $method;
    } else {
	$msg .= (caller(1))[3];
    }
    return ("$msg: Trying to set '$given_type_or_value' but '$expected_type' is expected.");
}


#-----------------------------------------------------------------
#
# Dealing with creating XML...
#
#-----------------------------------------------------------------
use MOSES::MOBY::Tags;
use XML::LibXML;
{

    # using a counter in order to avoid to clean namespaces several
    # times - there must be a better way to do it (TBD?, well but
    # how?)

    my $xml_counter = 0;

    sub increaseXMLCounter { $xml_counter++; }
    sub decreaseXMLCounter { $xml_counter--; }
    sub emptyXMLCounter { return $xml_counter == 0; }
}

# called at the end of toXML() methods: it returns $root
sub closeXML {
    my ($self, $root) = @_;
    $self->decreaseXMLCounter;
    if ($self->emptyXMLCounter) {
	my $parser = XML::LibXML::->new();
	$parser->clean_namespaces (1);
	my $doc = $parser->parse_string ($root->toString());
	return $doc->documentElement;
    } else {
	return $root;
    }
}

# creates a prefixed LibXML::Element given a name, in the MOBY XML
# namespace
sub createXMLElement {
    my ($self, $elementName) = @_;
    my $element = XML::LibXML::Element->new ($elementName);
    $element->setNamespace (MOBY_XML_NS, MOBY_XML_NS_PREFIX);
    return $element;
}

# set $value as an (MOBY namespaced) XML attribute $name into $element
# (an XML::LibXML type); do it only if $value is not empty
sub setXMLAttribute {
    my ($self, $element, $name, $value) = @_;
    return unless $value and $name;

    # trim the value
    $value =~ s/^\s*//;
    $value =~ s/\s*$//;
    return unless $value;

    $element->setAttributeNS (MOBY_XML_NS, $name, $value);
}

# return a value of an attribute named $name from an $element (an
# XML::LibXML type); try both with and without namespaces; return
# undef if no such sttribute found
sub getXMLAttribute {
    my ($self, $element, $name) = @_;
    return
	$element->getAttribute ($name) ||
	$element->getAttributeNS (MOBY_XML_NS, $name);
}

# return an XML document: calling first toXML on the caller, then
# wraps it as an XML document
sub toXMLdocument {
    my $self = shift;
    my $doc  = XML::LibXML->createDocument;
    $doc->setDocumentElement ($self->toXML);
    return $doc;
}


#-----------------------------------------------------------------
# Deal with 'set', 'get' and 'add_' methods.
#-----------------------------------------------------------------
sub AUTOLOAD {
    my ($self, @new_values) = @_;
    my $ref_sub;
    if ($AUTOLOAD =~ /.*::(\w+)/ && $self->_accessible ("$1")) {

	# get/set method
	my $attr_name = "$1";
	my $attr_type = $self->_attr_prop ($attr_name, TYPE) || STRING;
	my $attr_post = $self->_attr_prop ($attr_name, POST);
	my $attr_is_array = $self->_attr_prop ($attr_name, ISARRAY);
	my $attr_readonly = $self->_attr_prop ($attr_name, READONLY);
	$ref_sub =
	    sub {
		local *__ANON__ = "__ANON__$attr_name" . "_" . ref ($self);
		my ($this, @values) = @_;
		return $this->_getter ($attr_name) unless @values;
		$self->throw ("Sorry, the attribute '$attr_name' is read-only.")
		    if $attr_readonly;

		# here we continue with 'set' method:
		if ($attr_is_array) {
		    my @result = (ref ($values[0]) eq 'ARRAY' ? @{$values[0]} : @values);
		    foreach my $value (@result) {
			$value = $this->check_type ($AUTOLOAD, $attr_type, $value);
		    }
		    $this->_setter ($attr_name, $attr_type, \@result);
		} else {
		    $this->_setter ($attr_name, $attr_type, $this->check_type ($AUTOLOAD, $attr_type, @values));
		}

		# call post-procesing (if defined)
		$this->$attr_post ($this->{$attr_name}) if $attr_post;

		return $this->{$attr_name};
	    };

    } elsif ($AUTOLOAD =~ /.*::add_(\w+)/ && $self->_accessible ("$1")) {

	# add_XXXX method
	my $attr_name = "$1";
	if ($self->_attr_prop ($attr_name, ISARRAY)) {
	    my $attr_type = $self->_attr_prop ($attr_name, TYPE) || STRING;
	    $ref_sub =
		sub {
		    local *__ANON__ = "__ANON__$attr_name" . "_" . ref ($self);
		    my ($this, @values) = @_;
		    if (@values) {
			my @result = (ref ($values[0]) eq 'ARRAY' ? @{$values[0]} : @values);
			foreach my $value (@result) {
			    $value = $this->check_type ($AUTOLOAD, $attr_type, $value);
			}
			$this->_adder ($attr_name, $attr_type, @result);
		    }
		    return $this;
		}
	} else {
	    $self->throw ("Method '$AUTOLOAD' is allowed only for array-type attributes.");
	}

    } else {
	$self->throw ("No such method: $AUTOLOAD");
    }

    no strict 'refs'; 
    *{$AUTOLOAD} = $ref_sub;
    use strict 'refs'; 
    return $ref_sub->($self, @new_values);
}

#-----------------------------------------------------------------
# The low level get/set methods. They are called from AUTOLOAD, and
# they are separated here so they can be overriten - as they are in
# the service skeletons, for example. Also, there may be situation
# that one can call them if other features (such as type checking) are
# not requiered.
#-----------------------------------------------------------------
sub _getter {
    my ($self, $attr_name) = @_;
    return $self->{$attr_name};
}

sub _setter {
    my ($self, $attr_name, $attr_type, $value) = @_;
    $self->{$attr_name} = $value;
}

sub _adder {
    my ($self, $attr_name, $attr_type, @values) = @_;
    push ( @{ $self->{$attr_name} }, @values );
}

#-----------------------------------------------------------------
# Keep it here! The reason is the existence of AUTOLOAD...
#-----------------------------------------------------------------
sub DESTROY {
}

#-----------------------------------------------------------------
#
# Check type of @value against $expected_type. Return checked $value
# (perhaps trimmed, or otherwise corrected - e.g. wrapped in an
# appropriate object), or undef if the $value is of a wrong type.
#
#-----------------------------------------------------------------
sub check_type {
    my ($self, $name, $expected_type, @values) = @_;
    my $value = $values[0];

    # first process cases when an expected type is a simple string,
    # integer etc. (not MOSES::MOBY::Data::String etc.) - e.g. when an ID
    # attribute is being set

    if ($expected_type eq STRING) {
	return $value;

    } elsif ($expected_type eq INTEGER) {
	$self->throw ($self->_wrong_type_msg ($value, $expected_type, $name))
	    unless $value =~ m/^\s*[+-]?\s*\d+\s*$/;
	$value =~ s/\s//g;
	return $value;

    } elsif ($expected_type eq FLOAT) {
	$self->throw ($self->_wrong_type_msg ($value, $expected_type, $name))
	    unless $value =~ m/^\s*[+-]?\s*(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?\s*$/;
	$value =~ s/\s//g;
	return $value;

    } elsif ($expected_type eq BOOLEAN) {
	return ($value =~ /true|\+|1|yes|ano/ ? '1' : '0');

    } elsif ($expected_type eq DATETIME) {
	my $iso;
	eval { 
	    $iso = (HTTP::Date::time2isoz (HTTP::Date::str2time (HTTP::Date::parse_date ($value))));
	};
	$self->throw ($self->_wrong_type_msg ($value, 'ISO-8601', $name))
	    if $@;
	return $iso;   ### $iso =~ s/ /T/;  ??? TBD

    } else {

	# Then process cases when the expected type is a name of a
	# real object (e.g. MOSES::MOBY::Data::Xref); for these cases the
	# $value[0] can be already such object - in which case nothing
	# to be done; or $value[0] can be HASH, or @values can be a
	# list of name/value pairs, in which case a new object (of
	# type $expected_type) has to be created and initialized by
	# @values; and, still in the latter case, if the @values has
	# just one element (XX), this element is considered a 'value':
	# it is treated as a a hash {value => XX}.

	return $value if UNIVERSAL::isa ($value, $expected_type);

	$value = { value => $value }
	    unless ref ($value) || @values > 1;

	my ($value_ref_type) = ref ($value);
	if ($value_ref_type eq 'HASH') {
	    # e.g. $sequence->Length ( { value => 12, id => 'IR64'} )
	    return $self->create_member ($name, $expected_type, %$value);

	} elsif ($value_ref_type eq 'ARRAY') {
	    # e.g. $sequence->Length ( [ value => 12, id => 'IR64'] )
	    return $self->create_member ($name, $expected_type, @$value);

	} elsif ($value_ref_type) {
	    # e.g. $sequence->Length ( new MOSES::MOBY::Data::Integer ( value => 12) )
	    $self->throw ($self->_wrong_type_msg ($value_ref_type, $expected_type, $name))
		unless UNIVERSAL::isa ($value, $expected_type);
	    return $value;

	} else {
	    # e.g. $sequence->Length (value => 12, id => 'IR64')
	    return $self->create_member ($name, $expected_type, @values);

	}
    }
}

#-----------------------------------------------------------------
#
#-----------------------------------------------------------------
sub create_member {
    my ($self, $name, $expected_type, @values) = @_;
    eval "require $expected_type";
    $self->throw ($self->_wrong_type_msg ($values[0], $expected_type, $name))
	if $@;
    return "$expected_type"->new (@values);
}

#-----------------------------------------------------------------
# as_string (an "" operator overloading)
#-----------------------------------------------------------------
my $DUMPER;
BEGIN {
    use Dumpvalue;
    use IO::String;
    $DUMPER = Dumpvalue->new();
#    $DUMPER->set (veryCompact => 1);
}
sub as_string {
    my $self = shift;
    my $dump_str;
    my $io = IO::String->new (\$dump_str);
    my $oio = select ($io);
    $DUMPER->dumpValue (\$self);
    select ($oio);
    return $dump_str;
}

1;
__END__

=head1 NAME

MOSES::MOBY::Base - Hash-based abstract super-class for all MOBY objects

=head1 SYNOPSIS

  use base qw( MOSES::MOBY::Base );

  $self->throw ("This is an error");

  $LOG->info ('This is an info message.');
  $LOG->error ('This is an error to be logged.');

=head1 DESCRIPTION

This is a hash-based implementation of a general Moby
super-class. Most BioMoby objects should inherit from this.

=head1 CONTACT

Re-factored by Martin Senger E<lt>martin.senger@gmail.comE<gt> from a
similar module in Bioperl (Bio::Root::Roo) created by Steve Chervitz
E<lt>sac@bioperl.orgE<gt> and others.

=head1 ACCESSIBLE ATTRIBUTES

Most of the Moby objects (and especially objects representing various
Moby data types) are just containers of other objects (attributes,
members). Therefore, in order to crete a new Moby data type object it
is often enough to inherit from this C<Moby::Base> and to list allowed
attributes. The object lists only new, additional, attributes (those
defined in its parent classes are already available).

This is done by creating a I<closure> with a list of allowed attribute
names. These names correspond with the allowed I<get> and I<set>
methods. For example:

  {
    my %_allowed =
        (
	 id         => undef,
	 namespace  => undef,
	 );
  }

The closure above allows to call:

    $obj->id;                    # a get method
    $obj->id ('my id');          # a set method

    $obj->namespace;             # a get method
    $obj->namespace ('my ns');   # a set method

Well, not yet. The closure also needs two methods that access these
(and only these - that is why it is a closure, after all)
attributes. You can copy them from the C<MobyObject>. Here they are:

  {
    my %_allowed =
	(
	 id         => undef,
	 namespace  => undef,
	 );
    sub _accessible {
	my ($self, $attr) = @_;
	exists $_allowed{$attr} or $self->SUPER::_accessible ($attr);
    }
    sub _attr_prop {
	my ($self, $attr_name, $prop_name) = @_;
	my $attr = $_allowed {$attr_name};
	return ref ($attr) ? $attr->{$prop_name} : $attr if $attr;
	return $self->SUPER::_attr_prop ($attr_name, $prop_name);
    }
  }

More about these methods in a moment.

Each attribute has also associated some properties (that is why we
need the second method in the closure, the C<_attr_prop>). For example
(these are all attributes for C<MobyObject>):

  {
    my %_allowed =
	(
	 id         => undef,
	 namespace  => undef,
	 provision  => {type => 'MOSES::MOBY::Data::ProvisionInformation'},
	 xrefs      => {type => 'MOSES::MOBY::Data::Xref', is_array => 1},
         primitive  => {type => MOSES::MOBY::Base->BOOLEAN},
	 );
    ...
  }

The recognized property names are:

=over

=item B<type>

It defines a type of its attribute. It can be a primitive type - one
of those defined as constants in C<MOSES::MOBY::Base>
(e.g. "MOSES::MOBY::Base->INTEGER") - or a name of a real object
(e.g. C<MOSES::MOBY::Data::MobyProvisionInfo>).

When an attribute new value is being set it is checked against this
type, and an exception is thrown if the value does not comply with the
type.

Default type (used also when the whole properties are undef) is
"MOSES::MOBY::Base->STRING".

=item B<is_array>

A boolean property. If set to true it allows to set more values to
this attribute. It also allows to call a method prefixed with C<add_>
to add a new value (or values) to this attribute. For example (using
the list of attributes shown above):

   use MOSES::MOBY::Data::Object;
   my $moby = new MOSES::MOBY::Data::Object;

   use MOSES::MOBY::Data::Xref;
   my $xref = new MOSES::MOBY::Data::Xref;
   $xref->description ('he is looking at you, kid');

   # set the first cross reference
   $moby->xrefs ($xref);

   # later add anothet cross reference
   my $xref2 = new MOSES::MOBY::Data::Xref;
   $xref2->description ('she is looking at you, kid');
   $moby->add_xrefs ($xref);

Default value is C<false>.

Recognized values for C<true> are: C<1>, C<yes>, C<true>, C<+> and
C<ano>. Anything else is considered C<false>.

=item B<is_array>

A boolean property. If set to true the atribute can only be read.

=item B<post>

A property containing a reference to a subroutine. This subroutine is
called after a new value was set. It allows to do some
post-processing. For example:

  {
    my %_allowed =
	(
	 value  => {post => sub { shift->{isValueCDATA} = 0; } },
	 );
    ...
  }

=back

Now we know what attribute properties are - so we can define what
these methods in closure do (even though you do not need to know -
unless C<The Law of Leaky Abstractions> starts showing).

=over

=item C<_accessible ($attr_name)>

Return 1 if the parameter C<$attr_name> is an allowed name to be
set/get in this class; otherwise, pass it to the parent class.

=item C<_attr_prop ($attr_name, $prop_name)>

Return a value of a property given by name $prop_name for given
attribute $attr_name; if such attribute does not exist here, pass it
to the parent class.

=back

=head1 THROWING EXCEPTIONS

One of the functionalities that C<MOSES::MOBY::Base> provides is the ability
to B<throw()> exceptions with pretty stack traces.

=head2 throw

Throw an exception. An argument is an error message.

=head2 format_stack

Return a nicely formatted stack trace. The resul includes also an
error message given as a scalar argument. Usually, this method is not
called directly but via C<throw> (unless C<enable_throw_with_stack>
was set to true).

    print $self->format_stack ("Something terrible happen.");

=head1 LOGGING

=head1 OTHER SUBROUTINES

=head2 new

Create an empty hash-based object. Then call B<init()> in order to do
any initializing steps. This class provides only an empty C<init()>
but sub-classes may have it richer. Finally, fill the new object with
the given arguments (name/value pairs). The filling is done via C<set>
methods - which means that only attributes allowed for this particular
object can be used.

Arguments are name/value pairs. A special case is allowed: when a
single element argument occurs, it is treated as a "value". For
example, it is allowed to write:

    $mobyint = new MOSES::MOBY::Data::Integer (42);

instead of a long way (doing the same):

    $mobyint = new MOSES::MOBY::Data::Integer (value => 42);

=head2 init

Called after an object has been created (in B<new()>) and before the
values given in the constructor have been set. No arguments.

If your sub-class implements this method, make sure that it calls also
the same method of its super class:

   sub init {
       my ($self) = shift;
       $self->SUPER::init();
       # ... here do what you wish to do
       # ...
   }


=head2 toString

Return an (almost) human-readable description of any object.

Without any parameter, it stringifies the caller object
(self). Otherwise it stringifies the object given as parameter.

    print $self->toString;

    my $good_stuff = { yes => [1,2,3],
		       no  => { net => 'R', nikoliv => 'C' },
		   };
    print $self->toString ($good_stuff);


=cut


#-----------------------------------------------------------------
# Dealing with creating XML...
#-----------------------------------------------------------------

#-----------------------------------------------------------------
# Logging...
#-----------------------------------------------------------------

#-----------------------------------------------------------------
# module_name_escape
#
#   Make sure that the given name can be used as (part of) a Perl
#   module name.
#
#-----------------------------------------------------------------

#-----------------------------------------------------------------
# datatype2module
#
#   Prefix given data type name with a package name MOSES::MOBY::DATA,
#   and call 'module_name_escape' to substitute bad characters.
#   The result is a valid Perl module name that can represent
#   the given BioMoby data type.
#
#-----------------------------------------------------------------

#-----------------------------------------------------------------
# service2module
#
# Return a Perl module name created from the given service (both from
# its authority and its name).
#
#-----------------------------------------------------------------

#-----------------------------------------------------------------
# init_config
#-----------------------------------------------------------------

=head2 init_config

Find and read given configuration files (and perhaps some
others). Import all their properties into C<MOBYCFG> namespace. More
about how to use configuration properties is in L<MOSES::MOBY::Config>
module.

But making a long story short, this is all what you need in your
service implementation to use a property (excluding the fact that you
need to know the property name):

    $self->init_config ('my.conf');
    open HELLO, $MOBYCFG::MABUHAY_RESOURCE_FILE
	or $self->throw ('Mabuhay resource file not found.');

Arguments are optional and contain the file names of the configuration
files to be read, and/or hash references with the direct configuration
arguments. The files are looking for at the paths defined in the @INC,
and - if set - by the environment variable C<BIOMOBY_CFG_DIR>.

=cut

