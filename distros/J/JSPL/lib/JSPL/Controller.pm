package JSPL::Controller;
use strict;
use warnings;
our @ISA = qw(JSPL::Object);
use Scalar::Util();
use Carp();

sub JSPL::Context::get_controller {
    my $ctx = shift;
    my $scope = shift || $ctx->get_global;
    my $jsc;
    if($jsc = $scope->{'__PERL__'} and ref $jsc eq __PACKAGE__) {
       return $jsc;
    } else {
	die "Can't find controller\n";
    }
}

sub add {
    my $self = shift;
    my $package = shift;
    _get_stash($self->__context, $package);
}

sub added {
    my $self = shift;
    my $package = shift;
    return $self->{$package};
}

sub list {
    my $self = shift;
    return keys %{$self};
}

my %tinc = ();
my @texcep = qw(Exporter DynaLoader); # Not to be added
sub _addtweaks {
    my ($self, $package, $stash) = @_;
    my ($realfilename, $search);
    $search = $package;
    $search =~ s/::/\//g;
    my $tweaks = undef;
    ITER: {
	local $self->__context->{Restricted} = 0;
	for my $prefix (@INC) {
	    $realfilename = "$prefix/JSPL/Tweaks/$search";
	    if(-f "$realfilename.js") {
		$tweaks = $self->__context->jsc_eval(
			$stash, undef, "$realfilename.js"
		); 
		if($tweaks) {
		    while(my($k, $v) = each %{$tweaks}) { $stash->{$k} = $v; }
		}
		last ITER;
	    } elsif(-f "$realfilename.pm") {
		#TODO
	    }
	}
    }
    $tinc{$package} = $tweaks;
}

sub _chktweaks {
    my ($self, $package, $stash) = @_;
    no strict 'refs';
    return $tinc{$package} if exists $tinc{$package};
    my $tweaks;
    for my $supper ( @{ $package.'::ISA' } ) {
	next if grep $_ eq $supper, @texcep; # Excepted
	next if $self->{$supper}; # Already added
	if(my $stweaks = _chktweaks($self, $supper, $self->add($supper))) {
	    while(my($k, $v) = each %{$stweaks}) {
		$stash->{Proxy}{$k} = $v; # Install supper's tweaks in Proxy
	    }
	}
    }
    _addtweaks($self, $package, $stash);
}

sub install {
    my $self = shift;
    my $inst = 0;
    no warnings 'numeric';
    while(my $bind = shift) {
	my $package = shift;
	my $con = '';
	if(ref($package) eq 'ARRAY') {
	    $con = $package->[1];
	    $package = $package->[0];
	}
	my $stash = $self->add($package);
	my $const = ref($con) eq 'CODE' ? $con : $package->can($con || 'new');
	if($const) {
	    $self->__context->bind_value($bind => $stash->set_constructor($const));
	} elsif($con == -1) {
	    $stash->package_bind($bind);
	} elsif(!$con) {
	    $stash->class_bind($bind);
	} else {
	    Carp::croak("Invalid \$mode $con in install");
	}
	_chktweaks($self, $package, $stash);
	$inst++;
    }
    return $inst;
}

sub secure {
    my $self = shift;
    $self->__content->seal_object($self->__context);
}

$JSPL::ClassMap{perl} = __PACKAGE__;

package JSPL::Stash;
our @ISA = qw(JSPL::Object);

sub allow_from_js {
    my $self = shift;
    no strict 'refs';
    my $old = ${"$self->{'__PACKAGE__'}::_allow_js_export"};
    ${"$self->{'__PACKAGE__'}::_allow_js_export"} = shift if @_;
    return $old;
}

sub class_bind {
    my $self = shift;
    no strict 'refs';
    ${"$self->{'__PACKAGE__'}::__im_a_class"} = 1;
    $self->__context->bind_value(shift, $self);
}

sub package_bind {
    my $self = shift;
    $self->__context->bind_value(shift, $self->{Proxy});
}

sub add_properties {
    my $self = shift;
    no strict 'refs';
    local ${"$self->{'__PACKAGE__'}::_allow_js_export"} = undef;
    while(my $meth = shift) {
	$self->{$meth} = shift;
    }
    return $self;
}

sub set_constructor {
    my $self = shift;
    my $con = shift || 'new';
    my $const = ref($con) eq 'CODE' ? $con : $self->{__PACKAGE__}->can($con);
    if($const) {
	$self->{Proxy}{constructor} = $const;
    } else {
	Carp::croak("Can't find '$con' in $self->{__PACKAGE__}");
    }
    return $const;
}

package JSPL::Visitor;
our @ISA = qw(JSPL::Object);
use overload '%{}' => sub { tie my(%h),__PACKAGE__,$_[0]; \%h },
    fallback => 1;
sub TIEHASH { $_[1] }
sub DESTROY {} # This hasn't a passport
sub VALID { ${$_[0]}->[1] && ${$_[0]}->[1]->_isjsvis(${$_[0]}->[6]); }

package 
    JSPL::Any; #Hide from PAUSE

require Scalar::Util;
sub toSource {
    my $v = shift;
    my $rt = ref($v) || '';
    my $t;
    $t = tied(($rt eq 'ARRAY') ? @$v : ($rt eq 'HASH') ? %$v : $rt) if $rt;
    my $val;
    if($t && $t->isa('JSPL::Object') || 
       Scalar::Util::blessed($v) && $v->isa('JSPL::Object') && ($t=$v)
    ) {
	$val = $t->toSource();
    } elsif($rt) {
	for($rt) {
	    /^HASH$/ || /^JSPL::PerlHash$/ and do {
		$val = JSPL::PerlHash::toSource($v); last
	    };
	    /^ARRAY$/ || /^JSPL::PerlArray$/ and do {
		$val = JSPL::PerlArray::toSource($v); last
	    };
	    /^CODE$/ and do { $val = JSPL::PerlSub::toSource($v); last };
	    $val = $rt;
	}
    } elsif(Scalar::Util::looks_like_number($v)) {
	$val = "$v";
    } else {
	$val = "'$v'";
    }
    $val;
}

package
    JSPL::PerlScalar; # Hide from PAUSE

my $scalar;
our $prototype = \$scalar;

sub toString {
    my $this = shift || $JSPL::This;
    "${$this}";
}

package
    JSPL::PerlSub; # Hide from PAUSE

sub _const_sub { # Method call
    my $code = $_[1];
    my $frame = $] > 5.009 ? 1 : 2;
    JSPL::Context->check_privileges;
    my($package, $file, $line, $hints, $bitmask) = (caller $frame)[0,1,2,8,9];
    # warn sprintf("SBB: $package,$file,$line,'$code', H: %x, BM: %s\n", $hints,$bitmask);
    my $cr = eval join("\n",
	qq|package $package;BEGIN {\$^H=$hints;\${^WARNING_BITS}="$bitmask";}|,
	"#line $line $file",
	"sub {$code}") or Carp::croak("Can't compile: $@");
    return $cr;
}

sub prototype {}
our $wantarray = 1;

sub toString {
    my $code = shift || $JSPL::This;
    "sub {\n     [perl code]\n}";
}

sub toSource {
    my $code = shift || $JSPL::This;
    require B::Deparse;
    return 'sub ' . B::Deparse->new()->coderef2text($code)
}

sub call {
    my $code = $JSPL::This;
    local $JSPL::This = $_[0];
    shift unless(Scalar::Util::blessed($_[0]));
    $code->(@_);
}

sub apply {
    my $this = shift;
    my $arg = shift;
    if(ref($arg) eq 'HASH') { # Hack arround 'arguments' being an Object
	$arg = tied(%$arg);
	my @arg = map JSPL::Array::FETCH($arg, $_), 0 .. $arg->{'length'}-1;
	$arg = \@arg;
    }
    my $code = $JSPL::This;
    local $JSPL::This = $this;
    Scalar::Util::blessed($this) ? $code->($this, @{$arg} ) : $code->(@{$arg});
}

package
    JSPL::PerlArray; # Hide from PAUSE
# Some of the following methods are contrived for legacy support,
# will be simplified in 2.1
sub toString {
    my $aref = $JSPL::This;
    local $" = ',';
    no warnings 'uninitialized';
    return ref($aref) eq __PACKAGE__ ? "@{$$aref}" : "@{$aref}";
}

sub reverse {
    my $aref = $JSPL::This;
    my $legacy = ref($aref) eq __PACKAGE__;
    my @new = reverse $legacy ? @{$$aref} : @{$aref};
    ($legacy ? ${$aref} : $aref)->[$_] = $new[$_] for(0 .. $#new);
    $aref;
}

sub sort {
    my $aref = $JSPL::This;
    shift if(ref($_[0]) eq __PACKAGE__); 
    my $fun = shift;
    my $code = $fun ? sub { $fun->($a, $b) } : sub { $a cmp $b };
    my $legacy = ref($aref) eq __PACKAGE__;
    my @new = sort $code $legacy ? @{$$aref} : @{$aref};
    ($legacy ? ${$aref} : $aref)->[$_] = $new[$_] for(0 .. $#new);
    $aref;
}

sub toSource {
    my $aref = shift || $JSPL::This;
    $aref = $$aref if ref($aref) eq __PACKAGE__;
    "new PerlArray(" .  join(',', map JSPL::Any::toSource($_), @$aref) .  ")";
}

our @prototype=();

our $AUTOLOAD;
sub AUTOLOAD {
    my $aref = $JSPL::This;
    # Best efort to disambiguate legacy mode 
    shift if(ref($_[0]) eq __PACKAGE__ && ref($_[0]) eq ref($aref));
    my $method = (split('::', $AUTOLOAD))[-1];
    my $metref = JSPL::Context::current->get_global
	->{Array}->prototype->{$method};
    $metref->call($aref, @_) if($metref);
}

sub DESTROY {} # Don't autoload

*join = \&join;
*indexOf = \&indexOf;
*slice = \&slice;

package
    JSPL::PerlHash; # Hide from PAUSE
our %prototype=();

sub toSource {
    my $href = shift || $JSPL::This;
    my $cont = '';
    $href = $$href if ref($href) eq __PACKAGE__;
    while(my($k, $v) = each %{$href}) {
	$cont .= "'$k'," . JSPL::Any::toSource($v) . ',';
    }
    chop $cont if $cont;
    "new PerlHash($cont)";
}

1;
__END__

=head1 NAME

JSPL::Controller - Control which Perl namespaces can be used from JavaScript. 

=head1 SYNOPSIS

    use JSPL;
    use Gtk2 -init;	# Load your perl modules as usual

    my $ctx = JSPL->stock_context;
    my $ctl = $ctx->get_controller;
    $ctl->install(
	'Gtk2' => 'Gtk2',
	'Gtk2.Window' => 'Gtk2::Window',
	'Gtk2.Button' => 'Gtk2::Button',
        # Any more needed
    );

    $ctx->eval(q|
	var window = new Gtk2.Window('toplevel');
	var button = new Gtk2.Button('Quit');
	button.signal_connect('clicked', function() { Gtk2.main_quit() });
	window.add(button);
	window.show_all();
	Gtk2.main();
	say('Thats all folks!');
    |);

=head1 DESCRIPTION

Every context has a controller object. Context's controller object allows you to
reflect entire perl namespaces to JavaScript side and control how they can be used.

In the following discussion, we use the words "perl package" or simply "package" to
refer to a perl namespace, declared in perl with the keyword L<perlfunc/package>.

The controller object holds a list of every perl package exposed in some
form to JavaScript land. When JavaScript is made aware of a perl package
an instance of the special C<Stash> native class is created in the context. How
you can use that particular namespace from JavaScript depends on how the
C<Stash> instance or its properties are bound in JavaScript.

See L<JSPL::Stash> for details on C<Stash> instances.

This perl class allows you to make JavaScript land aware of perl packages and
provides some utilities methods.
				
=head1 INTERFACE

You obtain the instance of a context's controller calling
L<JSPL::Context/get_controller>.

    my $ctl = $context->get_controller;

With this you can use any of the following:

=head2 Instance methods

=over 4

=item add( $package_name )

    my $stash = $ctl->add('Foo::Bar');

Adds the package named I<$package_name> to the list of namespaces visible in
JavaScript, if not in there already.  Returns the L<JSPL::Stash>
object that encapsulates the associated C<Stash>.

=item added ( $package_name )

    $ctl->added('Foo::Bar');

Check if the package with the given I<$package_name> is in the list of perl
namespaces visible from JavaScript land. Returns a TRUE value
(the L<JSPL::Stash> object) if I<$package_name> is in the list, otherwise
returns a FALSE value.

Normal operation is to automatically add namespaces as needed. Packages are
added when a perl object enters javacript or you use L<JSPL::Context/bind_class>
and the package isn't already known.

=item list ( )
    
    @exported = $ctl->list();

Returns a list with the names of packages available in JavaScript land.
    
=item install ( I<BIND_OPERATION>, ... )

Performs a series of I<BIND_OPERATION>s in JavaScript land.

Every I<BIND_OPERATION> is an expression of the form:

=over 4

I<bind> => [ I<$package>, I<$mode> ]

=back

Where I<bind> is the property name to attach the package named I<$package> and
I<$mode> is the form to perform the binding.

There are three ways to bind a package: binding as a I<constructor>, as a I<static
class> or in I<indirect form>. You choose which way to use depending on the value
you give to the I<$mode> argument:

=over 4

=item * B<STRING>

When a B<STRING> is used as I<$mode>, you want to bind a I<constructor>.
The property I<bind> in JavaScript will be bound to a C<PerlSub> that references
the function named B<STRING> in the perl class associated with I<$package>.
I<bind> will then be used as a constructor.

For example

    $ctl->install(Img => [ 'GD::Simple', 'new' ]);

Binds to C<Img> a JavaScript constructor for objects of the perl class C<GD::Simple>,
so in JavaScript you can write:

    myimg = new Img(400, 250);

In perl the most common name for a constructor is C<new>, as long as you known
that your perl class I<has> a constructor named C<new>, you can use a simplified
form of the I<BIND_OPERATION>:

    $ctl->install(Img => 'GD::Simple');

=item * B<undef>

When $mode is B<undef>, you want to bind the perl package as a I<static class>.
The property I<bind> in JavaScript will be bound to the C<Stash> itself
associated with the I<$package>. See L<JSPL::Stash> for all the
implications.

You should bind in this form any perl package for which you need to make static
calls to  multiple functions (class methods).

For example:

    $ctl->install(DBI => [ 'DBI', undef ]);

Binds to C<DBI> the C<Stash> instance associated to the C<DBI> perl package,
allowing you to write in JavaScript:

    drivers = DBI->available_drivers();
    handle = DBI->connect(...);

In perl many packages work this way and/or provide constructors for I<other>
packages as static functions, but don't have a constructor for themselves.

If you know the perl class I<doesn't has> a constructor named C<new> you
can use the same simplified form of the I<BIND_OPERATION> above, and C<install>
will do the right thing.

    $ctl->install(DBI => 'DBI');

=item * B<-1>

When $mode is B<-1>, you want to bind the perl package in I<indirect> mode.
This mode allows JavaScript to resolve method calls on I<bind> to subroutines
defined in $package.

Using the I<indirect> form will make plain function calls to those subroutines
instead of static method calls.

For example:

    $ctl->install(Tests => [ 'Test::More', -1 ]);

Bind to C<Tests> an object allowing JavaScript to find all subroutines defined
in C<Test::More>. In JavaScript you'll write:

    Test.ok(...);
    Test.is(...);

A simple way to export to JavaScript a lot of new functions is to bind this way
a carefully crafted namespace.

    #!/usr/bin/perl
    # We are in 'main'
    use JSPL;

    package forjsuse;
    sub foo {...};
    sub bar {...};
    sub baz {...};

    my $ctx = JSPL->stock_context;
    $ctx->get_controller->install(Utils => ['forjsuse', -1]);
    
    $ctx->eval(q|
	Utils.bar(...);
    |);

An advantage of this method over using L<JSPL::Context/bind_function> is
that the C<PerlSub> objects associated to your perl subroutines won't get
created in JavaScript until needed.

=back

Every I<BIND_OPERATION>, search for a I<"Tweaks file"> associated to the
I<$package> added and if found loads it, see L<JSPL::Tweaks> for details.

To create a hierarchy of related properties you can pass to C<install> many
I<BIND_OPERATION>s as follows:

    $ctl->install(
	'Gtk2' => 'Gtk2',		 # Gtk lacks a 'new'. Binds a static class
	'Gtk2.Window' => 'Gtk2::Window', # Bind Gtk2::Window constructor
	'Gtk2.Button' => 'Gtk2::Button', # Bind Grk2::Button constructor
    );

=item secure ( )
    
    $ctl->secure();

Prevent further modifications to the controller's list. As a result no more perl
namespaces can be installed nor exported to the context.

=back
