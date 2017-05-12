# -*- perl -*-
#

require 5.004;
use strict;


package Mail::IspMailGate::Filter;

$Mail::IspMailGate::Filter::VERSION = "1.000";

sub getSign { "X-ispMailGateFilter"; };

#####################################################################
#
#   Name:     new
#
#   Purpse:   Filter constructor
#
#   Inputs:   $class - This class
#             $attr  - hash ref to the attributes
#                      1) 'direction' : 'pos' for the positive direction
#                                       'neg' for the negative direction
#
#   Returns:  Object or error message
#
#####################################################################

sub new ($$$) {
    my ($class, $attr) = @_;
    my ($self) = {};
    if (ref($attr) ne 'HASH') {
	return "Attribute reference is not a hash ref, but: " . ref($attr); 
    }
    my ($key);
    foreach $key (keys %$attr) {
	$self->{$key} = $attr->{$key};
    }

    bless($self, (ref($class) || $class));
    $self;
}

#####################################################################
#
#   Name:     filterFile
#
#   Purpse:   do the filter process for one file
#
#   Inputs:   $self   - This class
#             $attr   - hash-ref to filter attribute
#                       1. 'body'
#                       2. 'parser'
#                       3. 'head'
#                       4. 'globHead' the header of the whole Mail
#
#   Returns:  error message, if any
#
#####################################################################

sub filterFile ($$$) {
    my ($self, $attr) = @_;
    if (ref($attr) ne 'HASH') {
	die "No hash ref of attributes but: " . ref($attr);
    }
    my ($body) = $attr->{'body'};
    my ($ifile) = $body->path();
    if (!(-f $ifile)) {
	return "The file $ifile does not exist";
    }
    '';
}

#####################################################################
#
#   Name:     setEncoding
#
#   Purpse:   set a reasonable encoding type, for the filtered mail
#
#   Inputs:   $self   - This class
#             $entity - The entity 
#
#   Returns:  error-message if any
#    
#####################################################################

sub setEncoding ($$$) {
    my ($self, $entity) = @_;
    my ($head) = $entity->head();

    '';
}

#####################################################################
#
#   Name:     mustFilter
#
#   Purpose:   determines wether this message must be filtered and
#             allowed to modify $self the message and so on
#
#   Inputs:   $self   - This class
#             $entity - the whole message
#
#
#   Returns:  1 if it must be, else 0
#
#####################################################################

sub mustFilter ($$) {
    my($self, $entity) = @_;
    return 1;
}

#####################################################################
#
#   Name:     hookFilter
#
#   Purpose:   a function which is called after the filtering process
#             
#   Inputs:   $self   - This class
#             $entity - the whole message
#                       
#
#   Returns:  errormessage if any
#    
#####################################################################

sub hookFilter ($$) {
    my($self, $entity) = @_;
    '';
}


#####################################################################
#
#   Name:     doFilter
#
#   Purpose:   does the filtering process
#
#   Inputs:   $self   - This class
#             $attr   - a hash ref to the attributes 
#                       Following things are needed !!!!
#                       1) 'entity': a ref to the Entity object
#                       2) 'parser': a ref to a Parser object
#
#   Returns:  error message, if any
#    
#####################################################################

sub doFilter ($$) {
    my($self, $attr) = @_;
    my ($entity) = $attr->{'entity'};
    if(!$self->mustFilter($entity)) {
	'';
    } else {
	$self->recdoFilter($attr) . $self->hookFilter($entity);
    }
}


#####################################################################
#
#   Name:     recdoFilter
#
#   Purpse:   does the filtering process recursively by manipulating the
#             given entity  
#
#   Inputs:   $self   - This class
#             $attr   - a hash ref to the attributes 
#                       Following things are needed !!!!
#                       1) 'entity': a ref to the Entity object
#                       2) 'parser': a ref to a Parser object
#
#   Returns:  error message, if any
#    
#####################################################################

sub recdoFilter ($$) {
    my ($self, $attr) = @_;
    if (ref($attr) ne 'HASH') {
	die "Attributes are not a hash ref, but: " . ref($attr);
    }
    my ($entity) = $attr->{'entity'};
    my ($parser) = $attr->{'parser'};

    my($globHead) = exists($attr->{'globHead'}) ? $attr->{'globHead'} : $entity->head();
    
    my ($mult) = $entity->is_multipart();
    if (!defined($mult)) {
	die "Could not determine if the Entity is multipart or not";
    } elsif ($mult) {
	my (@parts) = $entity->parts;
	my ($part);
	my ($retstr) = '';
	foreach $part (@parts) {
	    my($result) = $self->recdoFilter({ 'entity' => $part,
			      'parser' => $parser,
			      'globHead' => $globHead,
			      'main' => $attr->{'main'}});
	    if (defined($result)) {
		$retstr .= $result;
	    }
	}
	$entity->parts(\@parts);
	return ($retstr);
    }

    my ($head) = $entity->head();
    my ($sign) = $head->get($self->getSign());
    if (!defined($sign)) {
	$sign = '';
    }
   
    my ($bodyh) = $entity->bodyhandle;
    my ($ifile);
    if (!defined($ifile = $bodyh->path())) {
	die "message body is not stored in a file";
    }
    my ($fattr) = { 'head' => $head,
		    'body' => $bodyh,
		    'globHead' => $globHead,
		    'parser' => $parser,
		    'main' => $attr->{'main'}};
    my ($err) = $self->filterFile($fattr, $parser);
    if ($err) {
	return "Error filtering $ifile: $err";
    }
#    $self->setEncoding($entity);
#    $head->replace($self->getSign(), $self->{'direction'});

    '';
} 


sub IsEq ($$) {
    my($self, $cmp) = @_;
    ref($self) eq ref($cmp);
}


package Mail::IspMailGate::Filter::InOut;

@Mail::IspMailGate::Filter::InOut::ISA = qw(Mail::IspMailGate::Filter);


#####################################################################
#
#   Name:     mustFilter
#
#   Purpose:  Based on the filter configuration and the message
#             header, determine whether we are running in input
#             ('positive') or output ('negative') mode.
#             
#   Inputs:   $self   - This class
#             $entity - the whole message
#
#   Returns:  TRUE is filtering must occurr, FALSE otherwise.
#             In the former case the attribute
#             $self->{'recDirection'} is set to either 'pos' or
#             'neg'.
#    
#####################################################################

sub mustFilter ($$) {
    my($self, $entity) = @_;
    my($head) = $entity->head();
    my($sign) = $head->get($self->getSign());
    my($direction);
    if (!defined($sign)) {
	$sign = '';
    }
    if (defined($direction = $self->{'direction'})) {
	if (($self->{'direction'} eq $sign)  ||
	    ($self->{'direction'} eq 'neg'  &&  $sign eq '')) {
	    return 0;
	}
    } else {
	$direction = ($sign eq 'pos') ? 'neg' : 'pos';
    }
    $self->{'recDirection'} = $direction;
    1;
}


#####################################################################
#
#   Name:     hookFilter
#
#   Purpse:   a function which is called after the filtering process
#             
#   Inputs:   $self   - This class
#             $entity - the whole message
#
#   Returns:  errormessage if any
#    
#####################################################################

sub hookFilter ($$) {
    my($self, $entity) = @_;
    my($head) = $entity->head;
    $head->set($self->getSign(), $self->{'recDirection'});
    delete $self->{'recDirection'};
    '';
}


sub IsEq ($$) {
    my($self, $cmp) = @_;
    if (ref($self) eq ref($cmp)) {
	if ($self->{'direction'}) {
	    if ($cmp->{'direction'}) {
		return $self->{'direction'} eq $cmp->{'direction'};
	    }
	} else {
	    return !$cmp->{'direction'};
	}
    }
    return 0;
}

1;


__END__

=pod

=head1 NAME

Mail::IspMailGate::Filter - An abstract base class of mail filters

=head1 SYNOPSIS

 # Create a filter
 my($filter) = Mail::IspMailGate::Filter->new({});

 # Call him for filtering a given mail (aka MIME::Entity)
 my ($attr) = {
     'entity' => $entity,    # a MIME::Entity object
     'parser' => $parser     # a MIME::Parser object
 };
 my($res) = $filter->doFilter($attr); 


=head1 VERSION AND VOLATILITY

    $Revision 1.0 $
    $Date 1998/04/05 18:19:45 $

=head1 DESCRIPTION

This class is the abstract base class of email filters. It implements the
main functionality every email filter should have, such as recursive
filtering on multipart MIME-message. You create a new filter by deriving
a subclass from Mail::IspMailGate::Filter. Usually you only need to
implement your own versions of the C<getSign>, C<filterFile> and
C<IsEq> methods.

Most filters are in/out filters. For example the packer module can do
compression or decompression and the PGP module can do encryption and
decryption. These filters are derived from Mail::IspMailGate::Filter::InOut,
which is itself derived from Mail::IspMailGate::Filter. The main idea of
these filters is that they have two directions, a 'positive' direction
(or 'in' mode) and a negative direction (or 'out' mode).

=head1 PUBLIC INTERFACE

=over 4

=item I<new $ATTR>

I<Class method.> Create a new filter instance; by passing the hash ref
ATTR you configure the filters behaviour. For example, the PGP filter
typically needs a user ID, the virus scanner needs a path to the external
virus scanning binary and so on.

The method returns an object for success or an error message otherwise.

=item I<getSign>

I<Instance method.> Returns a header name, that will be inserted into
the MIME entities head. For example, the base class inserts a header
field "X-ispMailGateFilter". Note that more than one header line will
be inserted if you apply multiple filters.

You should override this method.

=item I<filterFile $ATTR>

I<Instance method.> This method is called for modifying a given, single
part of the MIME entity. You can rely on the following attributes being
set in the hash ref ATTR:

=over 8

=item body

The MIME::Body object representing the part. The true data is stored as
a file on disk. (It's a MIME::Body::File object, to be precise.) In
particular this means that you can create a handle referring to the
object with

 $fh = $ATTR->{'body'}->open("r") or die $!;

If you need to work with external binaries you might use

 $path = $ATTR->{'body'}->path();

If the external binaries create a new file and you want to replace the
old file, use

 $ATTR->{'body'}->path($newPath);

See L<MIME::Body(3)> for detailed information.

=item head

The MIME::Head object representing this parts head. See L<MIME::Head(3)>
for detailed information.

=item globHead

The MIME::Head object of the top level MIME entity. If you are working
on a single part entity, this is just the same as the 'head' attribute.

=item parser

The Mail::IspMailGate::Parser object used for parsing the entity.
This is mostly usefull for using the logging methods

  $ATTR->{'parser'}->Debug("A debugging message");
  $ATTR->{'parser'}->Error("An error message");
  $ATTR->{'parser'}->Fatal("A fatal error message");

Note that the latter will abort the currently running thread, use is
discouraged. Instead you should throw a Perl exception by calling
C<die>.

=back

The filterFile method returns an empty string for success or an
error message otherwise. You should override this function, but calling

 $self->SUPER::filterFile($ATTR)

at the beginning is strongly encouraged.

=item I<mustFilter $ENTITY>

I<Instance method.> This method determines, whether the C<doFilter> method
ought to be executed. Usually it looks at the headers of the MIME entity
$ENTITY, for example the InOut class supresses filtering twice. The method
returns FALSE to supress filtering, TRUE otherwise.

=item I<hookFilter $ENTITY>

I<Instance method.> If filtering was needed (see I<doFilter>) and done,
this method is called, mainly for modifying the headers of the MIME entity
$ENTITY. When overriding this method, you should usually start with calling

 $self->SUPER::hookFilter($ENTITY);

=item I<doFilter $ATTR>

I<Instance method.> This method builds the frame of the filtering process.
It calls C<mustFilter>. If this method returns TRUE, the C<recdoFilter>
and C<hookFilter> methods are executed.

The hash ref $ATTR contains attributes 'entity', 'parser' correspond to
the same attributes of the C<filterFile> method.


=item I<recdoFilter $ATTR>

I<Instance method.> Called by C<doFilter> for filtering a MIME entity.
It calls the C<filterFile> method for singlepart entities. For multipart
entities, it calls itself recursively for any part.

The hash ref $ATTR corresponds to the arguments of C<doFilter>.

=item I<IsEq $CMP>

I<Instance method.> The IspMailGate program can handle multiple recipients
at the same time, which is obviously important for performance reasons.
For any recipient, a list of filters is built that the mail is fed into.
In most cases these filter lists or at least parts of them are equivalent,
so there's no need to pass the mail into both filter lists.

This method is called for determining whether two filter objects ($self
and $CMP) are equivalent. In other words: If I feed a mail into both
objects, the method tells me whether I can expect the same result. For
example, a simple implementation of IsEq would just look at the
filter object classes and return TRUE, if both objects are of the
same classes, but FALSE otherwise:

  sub IsEq ($$) {
      my($self, $CMP) = @_;
      ref($self) eq ref($CMP);
  }

The above is the default implementation, so it's quite likely that
you need to override this method.

=cut
