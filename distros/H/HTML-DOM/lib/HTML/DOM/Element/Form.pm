package HTML::DOM::Element::Form;

use strict;
use warnings;

no Carp();
use URI;

require HTML::DOM::Element;
require HTML::DOM::NodeList::Magic;
#require HTML::DOM::Collection::Elements;

our $VERSION = '0.058';
our @ISA = qw'HTML::DOM::Element';

use overload fallback => 1,
'@{}' => sub { shift->elements },
'%{}' => sub {
	my $self = shift;
	$self->isa(scalar caller) || caller->isa('HTML::DOM::_TreeBuilder')
		and return $self;
	$self->elements;
};

my %elem_elems = (
	input    => 1,
	button   => 1,
	select   => 1,
	textarea => 1,
);
sub elements {
	my $self = shift;
	my $collection = $self->{_HTML_DOM_elems} ||= do {
		my $collection = HTML::DOM::Collection::Elements->new(
		my $list = HTML::DOM::NodeList::Magic->new(
		   sub {
		     no warnings 'uninitialized';
		     grep(
		      $elem_elems{tag $_} && attr $_ 'type', ne 'image',
		      $self->descendants
		     ),
		     @{ $self->{_HTML_DOM_mg_elems}||[] }
		    } 
		));
		$self->ownerDocument-> _register_magic_node_list($list);
		$collection;
	};
	weaken $self;
	if (wantarray) {
		@$collection
	}
	else {
		$collection;
	}
}
sub add_element { # helper routine that formies use to add themselves to
 my $self = shift;  # the elements list
 push @{ $self->{_HTML_DOM_mg_elems} ||= [] }, shift
  if $elem_elems{ $_[0]->tag };
 return;
}
sub remove_element { # and this is how formies remove themselves when they
 my $self = shift;   # get moved around the DOM
 my $removee = shift;
 @{ $self->{_HTML_DOM_mg_elems} }
  = grep $_ != $removee, @{ $self->{_HTML_DOM_elems} ||= [] }
}

sub length        { shift->elements              -> length }
sub name          { no warnings; shift->_attr( name          => @_) . ''  }
sub acceptCharset { shift->_attr('accept-charset' => @_)    }
sub action        {
	my $self = shift;
	(my $base = $self->ownerDocument->base)
		or return $self->_attr('action', @_);
	(new_abs URI
		$self->_attr('action' => @_),
		$self->ownerDocument->base)
	 ->as_string
}
sub enctype       {
	my $ret = shift->_attr('enctype'        => @_);
	defined $ret ? $ret : 'application/x-www-form-urlencoded'
}
*encoding=*enctype;
sub method        {
	my $ret = shift->_attr('method'         => @_);
	defined $ret ? lc $ret : 'get'
}
sub target        { shift->_attr('target'         => @_)    }

sub submit { shift->trigger_event('submit') }

sub reset {
	shift->trigger_event('reset');
}

sub trigger_event {
	my ($a,$evnt) = (shift,shift);
	$a->SUPER::trigger_event(
		$evnt,
		submit_default =>
			$a->ownerDocument->
				default_event_handler_for('submit'),
		reset_default => sub {
			$_->_reset for shift->target->elements
		},
		@_,
	);
}

# ------ HTML::Form compatibility methods ------ #

sub inputs {
	my @ret;
	my %pos;
	my $self = shift;
	# This used to use ‘$self->elements’, but ->elements no longer
	# includes image buttons.
	for(
	 grep($elem_elems{tag $_}, $self->descendants),
	 @{ $self->{_HTML_DOM_mg_elems}||[] }
	) {
	  #next if (my $tag = tag $_) eq 'button'; # HTML::Form doesn't deal
	                                          # with <button>s.
	  # NOW IT DOES :)
	  my $tag = tag $_;

	  no warnings 'uninitialized'; # for 5.11.0
	  if(lc $_->attr('type') eq 'radio') {
	    my $name = name $_;
	    exists $pos{$name} ? push @{$ret[$pos{$name}]}, $_
	      :( push(@ret, [$_]),
	          $pos{$name} = $#ret );
	    next
	  }
	  push @ret, $tag eq 'select'
	    ? $_->attr('multiple')
	      ? $_->find('option')
	      : scalar $_->options
	    : $_
	}
	map ref $_ eq 'ARRAY' ? new HTML::DOM::NodeList::Radio $_ : $_,
		@ret
}

sub click  # 22/Sep/7: stolen from HTML::Form and modified (particularly
{          # the last line) so I don't have to mess with Hook::LexWrap
    my $self = shift;
    my $name;
    $name = shift if (@_ % 2) == 1;  # odd number of arguments

    # try to find first submit button to activate
    for ($self->inputs) {
        my $type = $_->type; my $tag = eval { $_->tag } || '';
        next unless $tag eq 'input'  && $type =~ /^(?:submit|image)\z/
	         || $tag eq 'button' && ($type || 'submit') eq 'submit';
        next if $name && $_->name ne $name;
	next if $_->disabled;
	$_->click($self, @_);return
    }
    Carp::croak("No clickable input with name $name") if $name;
    $self->trigger_event('submit');
}

# These three were shamelessly stolen from HTML::Form:
sub value
{
    package
     HTML::Form;
    my $self = shift;
    my $key  = shift;
    my $input = $self->find_input($key);
    Carp::croak("No such field '$key'") unless $input;
    local $Carp::CarpLevel = 1;
    $input->value(@_);
}


sub find_input
{
    package
	HTML::Form; # so caller tricks work
    my($self, $name, $type, $no) = @_;
    if (wantarray) {
	my @res;
	my $c;
	for ($self->inputs) {
	    if (defined $name) {
		next unless defined(my $n = $_->name);
		next if $name ne $n;
	    }
	    next if $type && $type ne $_->type;
	    $c++;
	    next if $no && $no != $c;
	    push(@res, $_);
	}
	return @res;
	
    }
    else {
	$no ||= 1;
	for ($self->inputs) {
	    if (defined $name) {
		next unless defined(my $n = $_->name);
		next if $name ne $n;
	    }
	    next if $type && $type ne $_->type;
	    next if --$no;
	    return $_;
	}
	return undef;
    }
}

sub param {
	package
		HTML::Form;
    my $self = shift;
    if (@_) {
        my $name = shift;
        my @inputs;
        for ($self->inputs) {
            my $n = $_->name;
            next if !defined($n) || $n ne $name;
            push(@inputs, $_);
        }

        if (@_) {
            # set
            die "No '$name' parameter exists" unless @inputs;
	    my @v = @_;
	    @v = @{$v[0]} if @v == 1 && ref($v[0]);
            while (@v) {
                my $v = shift @v;
                my $err;
                for my $i (0 .. @inputs-1) {
                    eval {
                        $inputs[$i]->value($v);
                    };
                    unless ($@) {
                        undef($err);
                        splice(@inputs, $i, 1);
                        last;
                    }
                    $err ||= $@;
                }
                die $err if $err;
            }

	    # the rest of the input should be cleared
	    for (@inputs) {
		$_->value(undef);
	    }
        }
        else {
            # get
            my @v;
            for (@inputs) {
		if (defined(my $v = $_->value)) {
		    push(@v, $v);
		}
            }
            return wantarray ? @v : $v[0];
        }
    }
    else {
        # list parameter names
        my @n;
        my %seen;
        for ($self->inputs) {
            my $n = $_->name;
            next if !defined($n) || $seen{$n}++;
            push(@n, $n);
        }
        return @n;
    }
}


my $ascii_encodings_re;
my $encodings_re;

sub _encoding_ok {
	my ($enc,$xwfu) =@ _;
	$enc =~ s/^(?:x-?)?mac-?/mac/i;
	($enc) x (Encode'resolve_alias($enc)||return)
		=~ ($xwfu ? $ascii_encodings_re : $encodings_re ||=qr/^${\
			join'|',map quotemeta,
				encodings Encode 'Byte'
		}\z/);
}

sub _apply_charset {
	my($charsets,$apply_to) = @_; # array refs
	my ($charset,@ret);
	for(@$charsets) {
#use DDS; Dump $_ if @$apply_to == 1;
		eval {
			@ret = ();
			# Can’t use map here, because it could die. (In
			# perl5.8.x, dying inside a map is a very
			# bad idea.)
			for my $applyee(@$apply_to) {
				push @ret, ref $applyee
					? $applyee
					: Encode::encode(
						$_,$applyee,9
					); # 1=croak, 8=leave src alone
			}                                         
			# Phew, we survived!
			$charset = $_;
		} && last;
	}
	unless($charset) {
		# If none of the charsets applied, we just use the first
		# one in the list (or fall back to utf8, since that’s the
		# sensible thing to do these days), replacing unknown
		# chars with ?
		my $fallback;
		$charset = $$charsets[0]||(++$fallback,'utf8');
		@ret = map ref$_ ? $_ : Encode'encode($charset,$_),
			@$apply_to;
		$fallback and $charset = 'utf-8';
	}
	$charset,\@ret;
}

# ~~~ This does not take non-ASCII file names into account, but I can’t
#     really do that yet, since perl itself doesn’t support those properly
#     yet, either.
# This one was stolen from HTML::Form but then modified extensively.
sub make_request
{
    my $self = shift;
    my $method  = $self->method;
    my $uri     = $self->action;
    my $xwfu = $method eq 'get'
        || $self->enctype !~ /^multipart\/form-data\z/i;
    my @form    = $self->form;

    # Get the charset and encode the form fields, if necessary. The HTML
    # spec says that the a/x-w-f-u MIME type only accepts ASCII, but we’ll
    # be more forgiving, for the sake of realism.  But to be compliant with
    # the spec in cases where it can apply  (e.g.,  a UTF-16 page with just
    # ASCII in its form data),  we only accept ASCII-based  encodings  for
    # this enctype.
    my @charsets;
    { push @charsets, split ' ', $self->acceptCharset||next}
    require Encode;
    @charsets = map _encoding_ok($_, $xwfu),
                @charsets;
    unless(@charsets){{
        # We only revert to the doc charset when accept-charset doesn’t
        # have any usable encodings (even encodings which will cause char
        # substitutions are considered usable; it’s non-ASCII with GET that
        # we don’t want).
        push @charsets, _encoding_ok(
            ($self->ownerDocument||next)->charset || next, $xwfu
        )
    }}

    if ($method ne "post") {
	require HTTP::Request;
	$uri = URI->new($uri, "http");
	$uri->can('query_form')
	 and $uri->query_form(@{_apply_charset \@charsets, \@form});
	return HTTP::Request->new(GET => $uri);
    }
    else  {
	require HTTP::Request::Common;
        if($xwfu) {
            my($charset,$form) = _apply_charset \@charsets, \@form;
            return HTTP::Request::Common::POST($uri, $form,
              Content_Type =>
                "application/x-www-form-urlencoded; charset=\"$charset\"");
        }
        else {
            my @new_form;
            while(@form) {
                my($name,$val) = (shift @form, shift @form);
#my $origval = $val;
                (my $charset, $val) = _apply_charset \@charsets, [$val];
#use DDS; Dump [$origval,$val, ];
                my $enc = $name;
                $enc = Encode'encode('MIME-B', $enc) if $enc =~ /[^ -~]/;
                push @new_form, $enc,
                    ref $$val[0] ? $$val[0] : [(undef)x2,
                        Content_Type => "text/plain; charset=\"$charset\"",
                        Content => @$val,
                    ];
            }
            return HTTP::Request::Common::POST($uri, \@new_form,
                Content_Type => 'multipart/form-data'
            );
        }
    }
}

sub form
{
    package
	HTML::Form; # so caller tricks work
    my $self = shift;
    map { $_->form_name_value($self) } $self->inputs;
}




package HTML::DOM::NodeList::Radio; # solely for HTML::Form compatibility
                                    # Usually ::Input is used, but ::Radio
                                    # is for a set of radio buttons.
use Carp 'croak';
require HTML::DOM::NodeList;

our $VERSION = '0.058';
our @ISA = qw'HTML::DOM::NodeList';

sub type { 'radio' }

sub name { 
	my $ret = (my $self = shift)->item(0)->attr('name');
	if (@_) {
		$self->item($_)->attr(name=>@_) for 0..$self->length-1;
	}
	$ret
}

sub value { # ~~~ do case-folding and what-not, as in HTML::Form::ListInput
	my $self = shift;

	my $checked_elem;
	for (0..$self->length-1) {
		my $btn = $self->item($_);
		$btn->checked and
			$checked_elem = $btn, last;
	}

	if (@_) { for (0..$self->length-1) {
		my $btn = $self->item($_);
		$_[0] eq $btn->attr('value') and
		  $btn->disabled && croak(
		    "The value '$_[0]' has been disabled for field '${\
		     $self->name}'"
		  ),
		  $btn->checked(1),
		  last;
	}}

	$checked_elem && $checked_elem->attr('value')
}

sub possible_values {
	my $self = shift;
	map $self->item($_)->attr('value'), 0..$self->length-1
}

sub disabled {
	my $self = shift;
	for(@$self) {
		$_->disabled or return 0
	}
	return 1
}

sub form_name_value
# Pilfered from HTML::Form with slight changes.
{
    package
	HTML::Form::Input;
    my $self = shift;
    my $name = $self->name;
    return unless defined $name && length $name;
    return if $self->disabled;
    my $value = $self->value;
    return unless defined $value;
    return ($name => $value);
}


package HTML::DOM::Collection::Elements;

use strict;
use warnings;

use Scalar::Util 'weaken';

our $VERSION = '0.058';

require HTML::DOM::Collection;
our @ISA = 'HTML::DOM::Collection';

# Internals: \[$nodelist, $tie]

# Field constants:
sub nodelist(){0}
sub tye(){1}
sub seen(){2}     # whether this key has been seen
sub position(){3} # current (array) position used by NEXTKEY
sub ids(){4}      # whether we are iterating through ids
{ no warnings 'misc';
  undef &nodelist; undef &tye; undef &seen; undef &position;
}

sub namedItem {
	my($self, $name) = @_;
	my $list = $$self->[nodelist];
	my $elem;
	my @list;
	for(0..$list->length - 1) {
		no warnings 'uninitialized';
		push @list, $elem if 
			($elem = $list->item($_))->id eq $name
			  or
			$elem->attr('name') eq $name;
	}
	if(@list > 1) {
		# ~~~ Perhaps this should cache the new nodelist
		#     and return the same one each item. (Incident-
		#     ally, Firefox returns the same one but Safari
		#     makes a new one each time.)
		my $ret = HTML::DOM::NodeList::Magic->new(sub {
			no warnings 'uninitialized';
			grep $_->id eq $name ||
			     $_->attr('name') eq $name, @$list;
		});
		return $ret;
	}
	@list ? $list[0] :()
}



# ----------------- Docs ----------------- #

=head1 NAME

HTML::DOM::Element::Form - A Perl class for representing 'form' elements in an HTML DOM tree

=head1 VERSION

Version 0.058

=head1 SYNOPSIS

  use HTML::DOM;
  $doc = HTML::DOM->new;
  $elem = $doc->createElement('form');

  $elem->method('GET') # set attribute
  $elem->method;       # get attribute
  $elem->enctype;
  $elem->tagName;
  # etc

=head1 DESCRIPTION

This class implements 'form' elements in an HTML::DOM tree. It 
implements the HTMLFormElement DOM interface and inherits from 
L<HTML::DOM::Element> (q.v.).

A form object can be used as a hash or an array, to access its input 
fields, so S<<< C<< $form->[0] >> >>> and S<<< C<< $form->{name} >> >>>
are shorthand for
S<<< C<< $form->elements->[0] >> >>> and
S<< C<<< $form->elements->{name} >>> >>, respectively.

This class also tries to mimic L<HTML::Form>, but is not entirely 
compatible
with its interface. See L</WWW::Mechanize COMPATIBILITY>, below.

=head1 DOM METHODS

In addition to those inherited from HTML::DOM::Element and 
HTML::DOM::Node, this class implements the following DOM methods:

=over 4

=item elements

Returns a collection (L<HTML::DOM::Collection::Elements> object) in scalar 
context,
or a list in list context, of all the input
fields this form contains. This differs slightly from the C<inputs> method
(part of the HTML::Form interface) in that it includes 'button' elements,
whereas C<inputs> does not (though it does include 'input' elements with
'button' for the type).

=item length

Same as C<< $form->elements->length >>.

=item name

=item acceptCharset

=item action

=item enctype

=item method

=item target

Each of these returns the corresponding HTML attribute (C<acceptCharset>
corresponds to the 'accept-charset' attribute). If you pass an
argument, it will become the new value of the attribute, and the old value
will be returned.

=item submit

This triggers the form's 'submit' event, calling the default event handler
(see L<HTML::DOM/EVENT HANDLING>). It is up to the default event handler to
take any further action. The form's C<make_request> method may come in 
handy.

This method is actually just short for $form->trigger_event('submit'). (See
L<HTML::DOM::EventTarget>.)

=item reset

This triggers the form's 'reset' event.

=item trigger_event

This class overrides the superclasses' method to trigger the default event
handler for form submissions, when the submit event occurs, and reset the
form when a reset event occurs.

=back

=head1 WWW::Mechanize COMPATIBILITY

In order to work with L<WWW::Mechanize>, this module mimics, and is 
partly compatible with the
interface of, L<HTML::Form>.

HTML::Form's class methods do not apply. If you call
C<< HTML::DOM::Element::Form->parse >>, for instance, you'll just get an
error, because it doesn't exist.

The C<dump> and C<try_others> methods do not exist either.

The C<click> method behaves differently from HTML::Form's, in that it does
not call C<make_request>, but triggers a 'click' event if there is a
button to click, or a 'submit' event otherwise.

The C<method>, C<action>, C<enctype>, C<attr>, C<inputs>, C<find_input>,
C<value>, C<param>, C<make_request> and C<form>
methods should
work as expected.

=head1 SEE ALSO

L<HTML::DOM>

L<HTML::DOM::Element>

L<HTML::DOM::Collection::Elements>

L<HTML::Form>

=cut


# ------- HTMLSelectElement interface ---------- #

package HTML::DOM::Element::Select;
our $VERSION = '0.058';
our @ISA = 'HTML::DOM::Element';

use overload fallback=>1, '@{}' => sub { shift->options };
	# ~~~ Don't I need %{} as well?

use Scalar'Util 'weaken';

sub type      { 'select-' . qw/one multiple/[!!shift->attr('multiple')] }
sub selectedIndex   {
	# Unfortunately, we cannot cache this (as in v. 0.040 and earlier)
	# as any change to the DOM will require it to be reset.
	my $self = shift;
	my $ret;
	if(defined wantarray) {
		my $x=0;
		# ~~~ I can optimise this by using $self->traverse since
		#     I don't need the rest of the list once I've found
		#     a selected item.
		for($self->options) {
			$_->selected and
				$ret = $x,
				last;
			$x++;
		}
		defined $ret or
			$ret = -1,
	}
	@_ and ($self->options)[$_[0]]->selected(1);
	return $ret;
}
sub value   { shift->options->value(@_) }
sub length { scalar(()= shift->options ) }
sub form           { 
 my $self = shift;
 my $ret = ($self->look_up(_tag => 'form'))[0] || $$self{_HTML_DOM_f}
  if defined wantarray;
 @_ and defined $_[0]
  ? ( weaken($$self{_HTML_DOM_f} = $_[0]), shift->add_element($self) )
  : (delete $$self{_HTML_DOM_f} or return $ret || ())
     ->remove_element($self);
 $ret || ();
}
sub options { # ~~~ I need to make this cache the resulting collection obj
              #     but when I do so I need to weaken references to $self
              #     and make ::Options do the same.
	my $self = shift;
	if (wantarray) {
		return grep tag $_ eq 'option', $self->descendants;
	}
	else {
		my $collection = HTML::DOM::Collection::Options->new(
		my $list = HTML::DOM::NodeList::Magic->new(
		    sub { grep tag $_ eq 'option', $self->descendants }
		), $self);
		$self->ownerDocument-> _register_magic_node_list($list);
		$collection;
	}
}
sub disabled  {
 shift->_attr( disabled => @_ ? $_[0] ? 'disabled' : undef : () )
}
sub multiple  {
 shift->_attr( multiple => @_ ? (undef,'multiple')[!!$_[0]] : () )
}
*name = \&HTML::DOM::Element::Form::name;
sub size      { shift->_attr( size => @_) }
sub tabIndex  { shift->_attr( tabindex => @_) }

sub add {
	my ($sel,$opt,$b4) = @_;
	# ~~~ does the following always work or will an optgroup break it?
	eval{$sel->insertBefore($opt,$b4)};
	return;
}
sub remove {
	my $self = shift;
	# ~~~ and how about this one?
	eval{$self->removeChild($self->options->item(shift) || return)};
	return;
}

sub blur { shift->trigger_event('blur') }
sub focus { shift->trigger_event('focus') }
sub _reset {  my $self = shift;
               $_->_reset for $self->options  }


package HTML::DOM::Collection::Options;

use strict;
use warnings;

our $VERSION = '0.058';

use Carp 'croak';
use constant sel => 5; # must not conflict with super
{ no strict 'refs'; delete ${__PACKAGE__."::"}{sel} } # after compilation

require HTML::DOM::Exception;
require HTML::DOM::Collection;
our @ISA = qw'HTML::DOM::Collection';

sub new {
	my $self = shift->SUPER::new(shift);
	$$$self[sel] = shift;
	$self
}

sub type { 'option' }
sub possible_values {
	map $_->value, @{+shift};
}

sub value { # ~~~ do case-folding and what-not, as in HTML::Form::ListInput
	my $self = shift;

	my $sel_elem;
	for (0..$self->length-1) {
		my $opt = $self->item($_);
		$opt->selected and
			$sel_elem = $opt, last;
	}

	if (@_) { for (0..$self->length-1) {
		my $opt = $self->item($_);
		my $v = $opt->value;
		$_[0] eq $v and
		  $opt->disabled && croak(
		    "The value '$_[0]' has been disabled for field '${\
		     $self->name}'"
		  ),
		  $opt->selected(1),
		  last;
	}}

	!defined $sel_elem # Shouldn't happen in well-formed documents, but
	    and $sel_elem  # how many documents are well-formed?
	     = $self->item(0);

	$sel_elem->value;
}

sub name {
	$${+shift}[sel]->name
}

sub disabled {
	(my $self = shift)->item(0)->look_up(_tag => 'select')->disabled 
		and return 1;
	for (@$self) {
		$_->disabled || return 0;
	}
	return 1
}

sub length { # override
	my $self = shift;
	die new HTML::DOM::Exception 
		HTML::DOM::Exception::NOT_SUPPORTED_ERR,
		"This implementation does not allow length to be set"
	if @_;
	$self->SUPER::length;
}

*form_name_value = \& HTML::DOM::NodeList::Radio::form_name_value;


# ------- HTMLOptGroupElement interface ---------- #

package HTML::DOM::Element::OptGroup;
our $VERSION = '0.058';
our @ISA = 'HTML::DOM::Element';

sub label  { shift->_attr( label => @_) }
*disabled = \&HTML::DOM::Element::Select::disabled;


# ------- HTMLOptionElement interface ---------- #

package HTML::DOM::Element::Option;
our $VERSION = '0.058';
our @ISA = qw'HTML::DOM::Element';

use Carp 'croak';
require HTML::DOM::Exception;

*form = \&HTML::DOM::Element::Select::form;
sub defaultSelected   {
 shift->_attr( selected => @_ ? $_[0] ? 'selected' : undef : () )
}

sub text { 
	shift->as_text
}

sub index {
	my $self = shift;
	my $indx = 0;
	my @options = (my $sel = $self->look_up(_tag => 'select'))
		->options;
	for(@options){
		last  if $self == $_;
		$indx++;
	}
	# This should not happen, unless the tree is horribly mangled:
	defined $indx or die new HTML::DOM::Exception 
	HTML::DOM::Exception::HIERARCHY_REQUEST_ERR,
	"It seems this option element is not a descendant of its ancestor."
	;
	if ( @_ ) {{
		my $new_indx= shift;
		last if $new_indx == $indx;
		if ($new_indx == 0) {
			$sel->insertBefore($self, $options[0]);
			last;
		}
		$options[$new_indx-1]->parentNode->insertBefore(
			$self, $options[$new_indx-1]->nextSibling
		);
	}}
	$indx;
}

*disabled = \&HTML::DOM::Element::Select::disabled;
*label = \&HTML::DOM::Element::OptGroup::label;

sub selected {
	my $self = shift;
	my $ret;

	if(!defined $self->{_HTML_DOM_sel}) {
		$ret = $self->attr('selected')||0;
	}
	else {
		$ret = $self->{_HTML_DOM_sel}
	}
	if(@_ && !$ret != !$_[0]) {
		my $sel = $self->look_up(_tag => 'select');
		if(!$sel || $sel->multiple) {
			$self->{_HTML_DOM_sel} = shift;
		}
		elsif($_[0]) { # You can't deselect the only selected
		               # option if exactly one option must be 
		               # selected at any given time.
			$self->{_HTML_DOM_sel} = shift;
			$_ != $self and $_->{_HTML_DOM_sel} = 0
				for $sel->options;
		}
	}
	$ret
}

sub value { # ~~~ do case-folding and what-not, as in HTML::Form::ListInput

	my $self = shift;
	my $ret;

	if(caller =~ /^(?:HTML::Form(?:::Input)?|WWW::Mechanize)\z/) {
		# ~~~ I can optimise this to call ->value once.
		$ret = $self->selected ? $self->value : undef;
		@_ and defined $_[0]
			? $_[0] eq $self->value
				? $self->selected(1)
				: croak "Invalid value '$_[0]' for option "
					. $self->name
			: $self->selected(0);
		return $ret;
	}

	defined($ret = $self->attr(value => @_)) or
		$ret = $self->text;

	return $ret;
}

sub type() { 'option' }

sub possible_values {
	(undef, shift->value)
}

sub name {
	shift->look_up(_tag => 'select')->name
}

sub _reset { delete shift->{_HTML_DOM_sel} }

*form_name_value = \& HTML::DOM::NodeList::Radio::form_name_value;


# ------- HTMLInputElement interface ---------- #

package HTML::DOM::Element::Input;
our $VERSION = '0.058';
our @ISA = qw'HTML::DOM::Element';

use Carp 'croak';

sub defaultValue   { shift->_attr( value => @_) }
sub defaultChecked {
 shift->_attr( checked => @_ ? $_[0] ? 'checked' : undef : () )
}
*form = \&HTML::DOM::Element::Select::form;
sub accept         { shift->_attr( accept => @_) }
sub accessKey      { shift->_attr( accesskey => @_) }
sub align          { lc shift->_attr( align => @_) }
sub alt            { shift->_attr( alt => @_) }
sub checked        {
	my $self = shift;
	my $ret;
	if(!defined $self->{_HTML_DOM_checked}) {
		$ret = $self->defaultChecked
	}
	else {
		$ret = $self->{_HTML_DOM_checked}
	}
	if(  @_ && !$ret != not $self->{_HTML_DOM_checked} = shift
	 and !$ret and $self->type eq 'radio'  ) {
		if(
		 my $form = $self->form and defined(my $name = $self->name)
		) {
			no warnings 'uninitialized';
			$_ != $self && $_->type eq 'radio'
			 && $_->name eq $name
			  and $_->{_HTML_DOM_checked} = 0
				for $form->elements;
		}
	}
	return $ret;
}
*disabled = \&HTML::DOM::Element::Select::disabled;
sub maxLength { shift->_attr( maxlength => @_) }
*name = \&HTML::DOM::Element::Form::name;
sub readOnly { shift->_attr(readonly => @_ ? $_[0]?'readonly':undef : ()) }
*size = \&HTML::DOM::Element::Select::size;
sub src       { shift->_attr( src => @_) }
*tabIndex = \&HTML::DOM::Element::Select::tabIndex;
sub type      {
	my $ret = shift->_attr('type', @_);
	return defined $ret ? lc $ret : 'text'
}
sub useMap    { shift->_attr( usemap => @_) }
sub value        {
	my $self = shift;
	my($ret,$type);

	if(caller =~ /^(?:HTML::Form(?:::Input)?|WWW::Mechanize)\z/ and
	    ($type = $self->type) =~ /^(?:button|reset)\z/ && return ||
	     $type eq 'checkbox') {
		# ~~~ Do case-folding as in HTML::Input::ListInput
		my $value = $self->value;
		length $value or $value = 'on';
		$ret = $self->checked
			? $value
			: undef;
		@_ and defined $_[0]
			? $_[0] eq $value
				? $self->checked(1)
				: croak
				   "Invalid value '$_[0]' for checkbox "
				   . $self->name
			: $self->checked(0);
		return $ret;
	}

# ~~~ shouldn't I make sure that modifying the value attribute 
#     (=defaultValue) leaves the value alone, even if the value has not
#     yet been accessed? (The same goes for checked and $option->selected)
	if(!defined $self->{_HTML_DOM_value}) {
		$ret = $self->defaultValue
	}
	else {
		$ret = $self->{_HTML_DOM_value}
	}
	@_ and $self->{_HTML_DOM_value} = shift;
	no warnings;
	return "$ret";
}
sub _reset {
	my $self = shift;
	$self->checked($self->defaultChecked);
	$self->value($self->defaultValue);
}

*blur = \&HTML::DOM::Element::Select::blur;
*focus = \&HTML::DOM::Element::Select::focus;
sub select { shift->trigger_event('select') }
sub click { for(shift){
	my(undef,$x,$y) = @_;
	defined or $_ = 1  for $x, $y;
	local($$_{_HTML_DOM_clicked}) = [$x,$y];
	$_->type eq 'checkbox' && $_->checked(!$_->checked);
	$_->trigger_event('click');
	return;
}}

sub trigger_event {
	my ($a,$evnt) = (shift,shift);
	my $input_type = $a->type;
	$a->SUPER::trigger_event(
		$evnt,
		$input_type =~ /^(?:(submi)|rese)t\z/
			?( DOMActivate_default =>
				# I’m not using a closure here, because we
				# don’t want the overhead of cloning it
				# when it might not even be used.
				(sub { (shift->target->form||return)
					->trigger_event('submit') },
				 sub { (shift->target->form||return)
					->trigger_event('reset') })
				  [!$1]
			) :(),
		@_
	);
}

sub possible_values {
	$_[0]->type eq 'checkbox' ? wantarray ? (undef, shift->value) : 2
	: ()
}
sub form_name_value
{
    my $self = shift;
    my $type = $self->type;
    if ($type =~ /^(image|submit)\z/) {
        return unless $self->{_HTML_DOM_clicked};
        if($1 eq 'image') {
            my $name = $self->name;
            $name = length $name ? "$name." : '';
            return "${name}x" => $self->{_HTML_DOM_clicked}[0],
                   "${name}y" => $self->{_HTML_DOM_clicked}[1]
        }
    }
    return $type eq 'file'
        ? $self->HTML_Form_FileInput_form_name_value(@_)
        : $self->HTML_Form_Input_form_name_value(@_);
}

# These two were stolen from HTML::Form with a few tweaks:
sub HTML_Form_Input_form_name_value
{
    package
	HTML::Form::Input;
    my $self = shift;
    my $name = $self->name;
    return unless defined $name && length $name;
    return if $self->disabled;
    my $value = $self->value;
    return unless defined $value;
    return ($name => $value);
}

sub HTML_Form_FileInput_form_name_value {
    package
	HTML::Form::ListInput;
    my($self, $form) = @_;
    return $self-> HTML_Form_Input_form_name_value($form)
	if uc $form->method ne "POST" ||
	   lc $form->enctype ne "multipart/form-data";

    my $name = $self->name;
    return unless defined $name;
    return if $self->{disabled};

    my $file = $self->file;
    my $filename = $self->filename;
    my @headers = $self->headers;
    my $content = $self->content;
    if (defined $content) {
	$filename = $file unless defined $filename;
	$file = undef;
	unshift(@headers, "Content" => $content);
    }
    elsif (!defined($file) || length($file) == 0) {
	return;
    }

    # legacy (this used to be the way to do it)
    if (ref($file) eq "ARRAY") {
	my $f = shift @$file;
	my $fn = shift @$file;
	push(@headers, @$file);
	$file = $f;
	$filename = $fn unless defined $filename;
    }

    return ($name => [$file, $filename, @headers]);
}



*file = \&value;

sub filename {
    my $self = shift;
    my $old = $self->{_HTML_DOM_filename};
    $self->{_HTML_DOM_filename} = shift if @_;
    $old = $self->file unless defined $old;
    $old;
}

sub headers { } # ~~~ Do I want to complete this?

sub content {
    my $self = shift;
    my $old = $self->{_HTML_DOM_content};
    $self->{_HTML_DOM_content} = shift if @_;
    $old;
}



# ------- HTMLTextAreaElement interface ---------- #

package HTML::DOM::Element::TextArea;
our $VERSION = '0.058';
our @ISA = qw'HTML::DOM::Element';

sub defaultValue { # same as HTML::DOM::Element::Title::text
	($_[0]->firstChild or
		@_ > 1 && $_[0]->appendChild(
			shift->ownerDocument->createTextNode(shift)
		),
		return '',
	)->data(@_[1..$#_]);
}
*form = \&HTML::DOM::Element::Select::form;
*accessKey = \&HTML::DOM::Element::Input::accessKey;
sub cols      { shift->_attr( cols       => @_) }
*disabled = \&HTML::DOM::Element::Select::disabled;
*name = \&HTML::DOM::Element::Select::name;
*readOnly = \&HTML::DOM::Element::Input::readOnly;
sub rows {shift->_attr( rows      => @_) }
*tabIndex = \&HTML::DOM::Element::Select::tabIndex;
sub type { 'textarea' }
sub value        {
	my $self = shift;
	my $ret;

	if(!defined $self->{_HTML_DOM_value}) {
		$ret = $self->defaultValue
	}
	else {
		$ret = $self->{_HTML_DOM_value}
	}
	@_ and $self->{_HTML_DOM_value} = shift;
	return $ret;
}
*blur = \&HTML::DOM::Element::Select::blur;
*focus = \&HTML::DOM::Element::Select::focus;
*select = \&HTML::DOM::Element::Input::select;

sub _reset {
	my $self = shift;
	$self->value($self->defaultValue);
}

*form_name_value = \& HTML::DOM::NodeList::Radio::form_name_value;


# ------- HTMLButtonElement interface ---------- #

package HTML::DOM::Element::Button;
our $VERSION = '0.058';
our @ISA = qw'HTML::DOM::Element';

*form = \&HTML::DOM::Element::Select::form;
*accessKey = \&HTML::DOM::Element::Input::accessKey;
*disabled = \&HTML::DOM::Element::Select::disabled;
*name = \&HTML::DOM::Element::Form::name;
*tabIndex = \&HTML::DOM::Element::Select::tabIndex;
sub type       { no warnings 'uninitialized'; lc shift->attr('type') }
sub value      { shift->attr( value       => @_) }

sub form_name_value
{
    my $self = shift;
    my $type = $self->type;
    return unless !$type or $type eq 'submit';
    return unless $self->{_HTML_DOM_clicked};
    my $name = $self->name;
    return unless defined $name && length $name;
    return if $self->disabled;
    my $value = $self->value;
    return ($name => defined $value ? $value : '');
}


sub click { for(shift){
	local($$_{_HTML_DOM_clicked}) = 1;
	$_->trigger_event('click');
	return;
}}

sub trigger_event {
	my ($a,$evnt) = (shift,shift);
	my $input_type = $a->type || 'submit';
	$a->SUPER::trigger_event(
		$evnt,
		$input_type =~ /^(?:(submi)|rese)t\z/
			?( DOMActivate_default =>
				# I’m not using a closure here, because we
				# don’t want the overhead of cloning it
				# when it might not even be used.
				(sub { (shift->target->form||return)
					->trigger_event('submit') },
				 sub { (shift->target->form||return)
					->trigger_event('reset') })
				  [!$1]
			) :(),
		@_
	);
}

sub _reset {}

# ------- HTMLLabelElement interface ---------- #

package HTML::DOM::Element::Label;
our $VERSION = '0.058';
our @ISA = qw'HTML::DOM::Element';

*form = \&HTML::DOM::Element::Select::form;
*accessKey = \&HTML::DOM::Element::Input::accessKey;
sub htmlFor { shift->_attr( for       => @_) }

# ------- HTMLFieldSetElement interface ---------- #

package HTML::DOM::Element::FieldSet;
our $VERSION = '0.058';
our @ISA = qw'HTML::DOM::Element';

*form = \&HTML::DOM::Element::Select::form;

# ------- HTMLLegendElement interface ---------- #

package HTML::DOM::Element::Legend;
our $VERSION = '0.058';
our @ISA = qw'HTML::DOM::Element';

*form = \&HTML::DOM::Element::Select::form;
*accessKey = \&HTML::DOM::Element::Input::accessKey;
*align = \*HTML::DOM::Element::Input::align;


no warnings;
!+~()#%$-*
