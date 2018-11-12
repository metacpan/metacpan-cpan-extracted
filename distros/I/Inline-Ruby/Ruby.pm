package Inline::Ruby;

use strict;
use warnings;

use Carp;
require Inline;
require DynaLoader;
require Exporter;
use vars qw(@ISA $VERSION @EXPORT_OK);

$VERSION = '0.10';
@ISA = qw(Inline DynaLoader Exporter);
@EXPORT_OK = qw(rb_eval
		rb_call_function
		rb_iter
		rb_call_class_method
		rb_new_object
		rb_call_instance_method
		rb_bind_class
		rb_bind_func
	       );

# Prevent Inline's import from complaining
sub import {
    Inline::Ruby->export_to_level(1, @_);
}

sub dl_load_flags { 0x01 }
Inline::Ruby->bootstrap($VERSION);

use constant _GET_NAMESPACE => <<EOF;
Proc.new {
    ns = { 'classes' => {}, 'modules' => {}, 'functions' => {} }
    ObjectSpace.each_object(Class) do |x|
        ns['classes'][x.name] = 1
    end
    ObjectSpace.each_object(Module) do |x|
        ns['modules'][x.name] = 1
    end
    Object.private_instance_methods.each do |x|
        ns['functions'][x] = 1
    end
    ns
}.call
EOF

#==============================================================================
# Register Ruby.pm as a valid Inline language
#==============================================================================
sub register {
    return {
            language => 'Ruby',
            aliases => ['rb', 'ruby', 'RUBY'],
            type => 'interpreted',
            suffix => 'rbdat',
           };
}

#==============================================================================
# Validate the Ruby config options
#==============================================================================
sub validate {
    my $o = shift;

    $o->{ILSM} ||= {};
    $o->{ILSM}{FILTERS} ||= [];
    $o->{ILSM}{AUTO_INCLUDE} ||= {};
    $o->{ILSM}{built} ||= 0;
    $o->{ILSM}{loaded} ||= 0;

    $o->{ILSM}{bindto} = [qw(classes modules functions)];
    $o->{ILSM}{ITER} ||= 'iter';

    while (@_) {
	my ($key, $value) = (shift, shift);

	if ($key eq 'REGEX' or $key eq 'REGEXP') {
	    $o->{ILSM}{regexp} = qr/$value/;
	}
	elsif ($key eq 'BIND_TYPE' or $key eq 'BIND_TYPES') {
	    $o->_add_list($o->{ILSM}, 'bindto', $value, []);
	}
	elsif ($key eq 'ITER') {
	    $o->{ILSM}{$key} = $value;
	}
	elsif ($key eq 'FILTERS') {
	    next if $value eq '1' or $value eq '0'; # ignore ENABLE, DISABLE
	    $value = [$value] unless ref($value) eq 'ARRAY';
	    my %filters;
	    for my $val (@$value) {
		if (ref($val) eq 'CODE') {
		    $o->_add_list($o->{ILSM}, $key, $val, []);
	        }
		else {
		    eval { require Inline::Filters };
		    croak "'FILTERS' option requires Inline::Filters to be installed."
		      if $@;
		    %filters = Inline::Filters::get_filters($o->{API}{language})
		      unless keys %filters;
		    if (defined $filters{$val}) {
			my $filter = Inline::Filters->new($val,
							  $filters{$val});
			$o->_add_list($o->{ILSM}, $key, $filter, []);
		    }
		    else {
			croak "Invalid filter $val specified.";
		    }
		}
	    }
	}
	else {
	    croak "$key is not a valid config option for Ruby";
	}
	next;
    }
}

sub _usage_validate {
    return "Invalid value for config option $_[0]";
}

sub _add_list {
    my $o = shift;
    my ($ref, $key, $value, $default) = @_;
    $value = [$value] unless ref $value;
    croak _usage_validate($key) unless ref($value) eq 'ARRAY';
    foreach my $val (@$value) {
	if (defined $val) {
	    push @{$ref->{$key}}, $val;
	}
	else {
	    $ref->{$key} = $default;
	}
    }
}

=begin Removed

sub _add_string {
    my $o = shift;
    my ($ref, $key, $value, $default) = @_;
    $value = [$value] unless ref $value;
    croak _usage_validate($key) unless ref($value) eq 'ARRAY';
    foreach my $val (@$value) {
	if (defined $val) {
	    $ref->{$key} .= " $val";
	}
	else {
	    $ref->{$key} = $default;
	}
    }
}

sub _add_text {
    my $o = shift;
    my ($ref, $key, $value, $default) = @_;
    $value = [$value] unless ref $value;
    croak _usage_validate($key) unless ref($value) eq 'ARRAY';
    for my $val (@$value) {
	if (defined $val) {
	    chomp($val);
	    $ref->{$key} .= $val . "\n";
	}
	else {
	    $ref->{$key} = $default;
	}
    }
}

=end Removed

=cut


#==========================================================================
# Print a short information section if PRINT_INFO is enabled.
#==========================================================================
sub info {
    my $o = shift;
    my $info =  "";

    $o->build unless $o->{ILSM}{built};

    my @functions = @{$o->{ILSM}{namespace}{functions}||[]};
    $info .= "The following Ruby functions have been bound to Perl:\n"
      if @functions;
    for my $function (sort @functions) {
	$info .= "\tdef $function()\n";
    }
    my %classes = %{$o->{ILSM}{namespace}{classes}||{}};
    $info .= "The following Ruby classes have been bound to Perl:\n";
    my $i = ' ' x 4;
    for my $class (sort keys %classes) {
	$info .= "${i}class $class\n";
	$i .= $i;
	for my $method (sort @{$classes{$class}{imethods}}) {
	    next unless $method =~ /^\w+$/;
	    $info .= "${i}def $method(...)\n";
	}
	for my $method (sort @{$classes{$class}{methods}}) {
	    next unless $method =~ /^\w+$/;
	    $info .= "${i}def $class.$method(...)\n";
	}
    }

    return $info;
}

#==========================================================================
# Run the code, study the main namespace, and cache the results.
#==========================================================================
sub build {
    my $o = shift;
    return if $o->{ILSM}{built};

    # Filter the code
    $o->{ILSM}{code} = $o->filter(@{$o->{ILSM}{FILTERS}});

    # Get the namespace before & after evaluating the code:
    my $pre = rb_eval(_GET_NAMESPACE);
    rb_eval($o->{ILSM}{code});
    my $post = rb_eval(_GET_NAMESPACE);

    # Select those things which sprang into existence after running the code:
    my @skip_clas = qw(PerlException PerlProc);
    my @skip_func = qw();
    delete @{ $post->{classes} }{@skip_clas, keys(%{$pre->{classes}})};
    delete @{ $post->{functions} }{@skip_func, keys(%{$pre->{functions}})};
    delete @{ $post->{modules} }{
        keys(%{$pre->{modules}}), keys(%{$post->{classes}})
    };

    # Filter the results according to the {bindto} and {REGEXP} selections:
    for my $type (qw(classes modules functions)) {
	if ($o->{ILSM}{bindto}) {
	    delete $post->{$type}
	      unless grep { $_ eq $type } @{$o->{ILSM}{bindto}};
	}
	if ($o->{ILSM}{regexp}) {
	    for my $k (keys %{$post->{$type}}) {
		delete $post->{$type}{$k} unless $k =~ $o->{ILSM}{regexp};
	    }
	}
    }

    # Get more details about the classes and modules.
    my $c = {};
    if (keys %{$post->{classes} || {}}) {
        my $classes_arg = join ', ',
                          map { '"' . (quotemeta $_) . '"' }
                          keys %{$post->{classes}};
        $c = rb_eval(<<EOF);
Proc.new {
    ns = {}
    classes = [$classes_arg]
    classes.each do |k|
        ns[k] = {}
        begin
            ns[k]['methods'] = eval "#{k}.methods"
            ns[k]['imethods'] = eval "#{k}.instance_methods"
        rescue Exception
            p "Exception: " + \$!
        end
    end
    ns
}.call
EOF
    }

    my $m = {};
    if (%{$post->{modules} || {}}) {
        my $modules_arg = join ', ',
                          map { '"' . (quotemeta $_) . '"' }
                          keys %{$post->{modules}};
        $m = rb_eval(<<EOF);
Proc.new {
    ns = {}
    classes = [$modules_arg]
    classes.each do |k|
        ns[k] = {}
        begin
            ns[k]['methods'] = eval "#{k}.methods"
            ns[k]['imethods'] = eval "#{k}.instance_methods"
        rescue Exception
            p "Exception: " + \$!
        end
    end
    ns
}.call
EOF
    }

    # And the namespace is:
    my %namespace = (
	classes		=> { %$c, %$m },
	functions	=> [keys %{$post->{functions} || {}}],
    );

    if ((! @{$namespace{functions}})
            and (! %{$namespace{classes}}))
    {
        warn "No functions or classes found!";
    }

    # Cache the results
    require Inline::denter;
    my $namespace = Inline::denter->new->indent(
	*namespace => \%namespace,
	*filtered  => $o->{ILSM}{code},
	*itername  => $o->{ILSM}{ITER},
    );

    $o->mkpath("$o->{API}{install_lib}/auto/$o->{API}{modpname}");

    {
        open my $rbdat_fh, '>', $o->{API}{location}
            or croak "Inline::Ruby couldn't write parse information!";
        print {$rbdat_fh} $namespace;
        close($rbdat_fh);
    }

    $o->{ILSM}{namespace} = \%namespace;
    $o->{ILSM}{built}++;
}

sub _slurp
{
    my $filename = shift;

    open my $in, '<', $filename
        or croak "Cannot open '$filename' for slurping - $!";

    local $/;
    my $contents = <$in>;

    close($in);

    return $contents;
}

#==============================================================================
# Load the code, run it, and bind everything to Perl
#==============================================================================
sub load {
    my $o = shift;
    return if $o->{ILSM}{loaded};

    my $rbdat = _slurp($o->{API}{location});

    require Inline::denter;
    my %rbdat = Inline::denter->new->undent($rbdat);
    $o->{ILSM}{namespace} = $rbdat{namespace};
    $o->{ILSM}{code} = $rbdat{filtered};
    $o->{ILSM}{ITER} = $rbdat{itername};
    $o->{ILSM}{loaded}++;

    # Run it
    rb_eval($o->{ILSM}{code});

    # Bind it all
    for my $func (@{ $o->{ILSM}{namespace}{functions} || [] })
    {
        rb_bind_func("$o->{API}{pkg}::$func", $func);
    }
    for my $class (keys %{ $o->{ILSM}{namespace}{classes} || {} })
    {
        rb_bind_class("$o->{API}{pkg}::$class", $class, $o->{ILSM}{ITER},
            %{$o->{ILSM}{namespace}{classes}{$class}});
    }

    # Bind the global function 'iter':
    eval <<END;
sub $o->{API}{pkg}::$o->{ILSM}{ITER} {
    unshift \@_, undef;
    return &Inline::Ruby::rb_iter;
}
END
    croak $@ if $@;
}

#==============================================================================
# Wrap a Ruby function with a Perl sub which calls it.
#==============================================================================
sub rb_bind_func {
    my $perlfunc = shift;	# The fully-qualified Perl sub name to create
    my $function = shift;	# The fully-qualified Ruby sub name to wrap

    my $bind = <<END;
sub $perlfunc {
    unshift \@_, "$function";
    return &Inline::Ruby::rb_call_function;
}
END

    eval $bind;
    croak $@ if $@;
}

#==============================================================================
# Wrap a Ruby class in a Perl package. We wrap every method we know about,
# and we inherit from Inline::Ruby::Object so the Perverse Ruby Programmer
# can still create dynamic methods on-the-fly using its AUTOLOAD.
#==============================================================================

my %bound_pkgs;

sub rb_bind_class {
    my $pkg  	= shift;	# The perl class to use
    my $class	= shift;	# The ruby class to wrap
    my $iter	= shift;	# The name to use for 'iter'
    my %methods = @_;

    $pkg =~ s/\Amain:://;
    if (exists($bound_pkgs{$pkg}))
    {
        return;
    }
    $bound_pkgs{$pkg} = 1;

    my $bind = <<END;
package ${pkg};
\@${pkg}::ISA = qw(Inline::Ruby::Object);
sub new {	# ${class}::new
    splice \@_, 1, 0, "$class";
    return &Inline::Ruby::rb_new_object;
}
END
    $bind .= <<END if $iter;
sub $iter {
    return &Inline::Ruby::rb_iter;
}
END

    my %bound_methods;

    for my $method (@{$methods{methods}}) {
	next unless $method =~ /^\w+$/;
	next if $method eq 'new';	# handled specially
    next if $bound_methods{$method}++;
	$bind .= <<END;
sub $method {	# ${class}::${method}
    splice \@_, 1, 0, "$method";
    return &Inline::Ruby::rb_call_class_method;
}
END
    }
    for my $method (@{$methods{imethods}}) {
	next unless $method =~ /^\w+$/;
    next if $bound_methods{$method}++;
	$bind .= <<END;
sub $method {	# ${class}::${method}
    splice \@_, 1, 0, "$method";
    return &Inline::Ruby::rb_call_instance_method;
}
END
    }

    eval $bind;
    croak $@ if $@;
}

#==============================================================================
# Create a new instance of a Ruby object.
#==============================================================================
sub rb_new_object {
    return &Inline::Ruby::Object::new;
}

#==============================================================================
# We provide Inline::Ruby::Object as a base class for Ruby objects. It
# knows how to create, destroy, and call methods on objects.
#==============================================================================
package Inline::Ruby::Object;

sub new {
    my $pkg = shift;
    splice @_, 1, 0, 'new';
    return bless &Inline::Ruby::rb_call_class_method, ref($pkg) || $pkg;
}

sub AUTOLOAD {
    no strict;
    $AUTOLOAD =~ s|^.*::||;
    splice @_, 1, 0, $AUTOLOAD;
    return &Inline::Ruby::rb_call_instance_method;
}

#==============================================================================
# We provide Inline::Ruby::Exception as a class for Ruby exceptions. Creating
# an instance of it throws a Perl exception. You can call Ruby methods on the
# exception object to get more information about what went wrong.
#
# Don't create your own Inline::Ruby::Exception objects. This is intended to
# be created from XS.
#==============================================================================
package Inline::Ruby::Exception;
use overload '""' => \&to_str;

sub new {
    my ($cls, $obj) = @_;
    die bless $obj, ref($cls) || $cls;
}

sub to_str {
    $_[0]->inspect . "\n";
}

1;
