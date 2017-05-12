package Devel::GDB::Reflect::DelegateProvider::STL;

use warnings;
use strict;

use Devel::GDB::Reflect::MessageMethod qw( anon );

sub new($)
{
	my $class = shift;

	return bless {};
}

sub get_delegates($$$$)
{
	my $self = shift;
	my ($type, $var, $reflector) = @_;

	my @delegates = ();

	if(my $inst = _get_string_delegate($type, $var, $reflector))
	{
		push @delegates, $inst;
	}

	if(my $inst = _get_pair_delegate($type, $var, $reflector))
	{
		push @delegates, $inst;
	}

	if(my $inst = _get_vector_delegate($type, $var, $reflector))
	{
		push @delegates, $inst;
	}

	if(my $inst = _get_tree_delegate($type, $var, $reflector))
	{
		push @delegates, $inst;
	}

	return @delegates;
}

sub _get_string_delegate($$$)
{
	my ($i_type, $i_var, $reflector) = @_;
	my ($basetype, $expr);

	# Dock the priority if this doesn't appear to be a string
	my $priority = ($i_type->{shortname} eq 'string' or $i_type->{shortname} eq 'basic_string') ? 0 : -10;

	# GCC 3.4.4 / GCC 4.1.1
	if( defined( $reflector->get_member($i_type, '_M_dataplus') ) &&
		defined( my $basemember = $reflector->get_member("($i_var)._M_dataplus", '_M_p') ))
	{
		$expr = '"($var)._M_dataplus._M_p"';
		$basetype = $basemember->{type};
	}

	# STLport 5.0.1 with _STLP_DONT_USE_SHORT_STRING_OPTIM
	elsif( defined( $basemember = $reflector->get_member($i_type, '_M_start') ))
	{
		$expr = '"($var)._M_start"';
		$basetype = $basemember->{type};
	}

	# STLport 5.0.1 with _STLP_USE_SHORT_STRING_OPTIM
	elsif( defined( $reflector->get_member($i_type, '_M_buffers') ) &&
		   defined( $reflector->get_member($i_type, '_M_end_of_storage') ) &&
		   defined( $reflector->get_member("($i_var)._M_buffers", '_M_static_buf') ) &&
		   defined( $basemember = $reflector->get_member("($i_var)._M_buffers", '_M_dynamic_buf') ) &&
		   defined( $reflector->get_member("($i_var)._M_end_of_storage", '_M_data') ))
	{
		$expr = '"(($var)._M_buffers._M_static_buf + sizeof(($var)._M_buffers._M_static_buf) == ($var)._M_end_of_storage._M_data) ? (($basetype->{quotename}) ($var)._M_buffers._M_static_buf) : ($var)._M_buffers._M_dynamic_buf"';

		$basetype = $basemember->{type};
	}
	else
	{
		return undef;
	}

	return
	{
		print_open_brace  => "",
		print_close_brace => "",
		print_separator   => "",
		can_iterate => 0,
		priority => $priority,
		factory => sub
		{
			my ($var) = @_;

			# Is this a bug in perl?  If eval($expr) references a variable that
			# hasn't been accessed before in this scope (e.g. $basetype), it's
			# undefined in the scope of the eval().
			my $junk = $basetype;

			my $expr = eval($expr);

			return anon
			{
				print => sub
				{
					my ($callback, $fh) = @_;

					return $callback->($expr, $basetype);
				}
			}
		}
	}
}

sub _get_pair_delegate($$$)
{
	my ($i_type, $i_var, $reflector) = @_;

	unless($i_type->{shortname} eq 'pair')
	{
		return undef;
	}

	unless( defined( $reflector->get_member($i_type, 'first') ) &&
	        defined( $reflector->get_member($i_type, 'second') ))
	{
		return undef;
	}

	return
	{
		can_iterate       => 0,
		priority          => 0,
		print_open_brace  => "",
		print_close_brace => "",
		print_separator   => "=>",
		factory => sub
		{
			my ($var) = @_;

			return anon
			{
				print => sub
				{
					my ($callback, $fh) = @_;

					$callback->("($var).first");
					$callback->("($var).second");
				}
			}
		}
	}
}

sub _get_vector_delegate($$$)
{
	my ($i_type, $i_var, $reflector) = @_;
	my ($basetype, $impl);

	unless($i_type->{shortname} eq 'vector')
	{
		return undef;
	}

	$impl = defined( $reflector->get_member($i_type, '_M_impl') ) ? '._M_impl' : '';

	unless( defined( $reflector->get_member("($i_var)$impl", '_M_start') ) &&
			defined( $reflector->get_member("($i_var)$impl", '_M_finish') ) &&
			defined( $basetype = $reflector->get_type("(*(($i_var)$impl._M_start))") ))
	{
		return undef;
	}

	return
	{
		print_newline => 1,
		priority => 0,
		can_iterate => 1,
		factory => sub
		{
			my ($var) = @_;
			my ($begin_addr, $end_addr, $increment);

			unless( defined( $begin_addr = $reflector->eval("(unsigned long) ($var)$impl._M_start") ) &&
					defined( $end_addr   = $reflector->eval("(unsigned long) ($var)$impl._M_finish") ) &&
					defined( $increment  = $reflector->eval("sizeof(*($var)$impl._M_start)") ))
			{
				die "Internal error";
			}

			my $cur_addr = $begin_addr;
			my $last_newline;

			return anon
			{
				has_next => sub
				{
					return $cur_addr < $end_addr;
				},

				print_next => sub
				{
					my ($callback, $fh) = @_;
					$callback->("*(($basetype->{quotename} *) $cur_addr)", $basetype);
					$cur_addr += $increment;
				},
			}
		}
	}
}

sub _get_tree_delegate($$$)
{
	my ($i_type, $i_var, $reflector) = @_;
	my ($nodetype, $basetype, $begin_expr, $end_expr);

	# Dock the priority if we're not dealing with an STL set or map
	my $priority = ($i_type->{shortname} eq 'set' or $i_type->{shortname} eq 'map') ? 0 : -10;

	# GCC 3.4.4 / GCC 4.1.1
	if( defined( $reflector->eval( "($i_var)._M_t._M_impl._M_header._M_left") ) &&
	    defined( my $nodemember = $reflector->get_member("($i_var)._M_t", "_M_get_node") ))
	{
		$nodetype = $nodemember->{type}->{quotename};
		$begin_expr = '_M_impl._M_header._M_left';
		$end_expr   = '_M_impl._M_header';
	}

	# STLport 5.0.1
	elsif( defined( $reflector->eval( "($i_var)._M_t._M_header._M_data._M_left") ) &&
		   defined( my $treemember = $reflector->get_member($i_type, "_M_t") ))
	{
		# Make a huge leap of faith here and assume that (a) the third template
		# parameter to _M_t is the _Value type; and (b) the correct value for
		# $nodetype is NAMESPACE::_Rb_tree_node<_Value>

		my $value_t = $treemember->{type}->{template}->[2]
			or return undef;

		$treemember->{type}->{fullname} =~ /^((?:[A-Za-z0-9_]+::)*)_Rb_tree\b/
			or return undef;

		my $namespace = $1;

		$nodetype = "'${namespace}_Rb_tree_node< $value_t >' *";

		$begin_expr = '_M_header._M_data._M_left';
		$end_expr   = '_M_header';
	}

	else
	{
		return undef;
	}

	unless( defined( $basetype = $reflector->get_type("(($nodetype *) 0)->_M_value_field") ))
	{
		return undef;
	}

	return
	{
		print_open_brace  => "{",
		print_close_brace => "}",
		print_newline     => 1,
		can_iterate => 1,
		priority => $priority,
		factory => sub
		{
			my ($var) = @_;
			my ($begin_addr, $end_addr);

			unless( defined( $begin_addr = $reflector->eval("(unsigned long) ($var)._M_t.$begin_expr") ) &&
					defined( $end_addr   = $reflector->eval("(unsigned long) &($var)._M_t.$end_expr") ))
			{
				die "Internal error";
			}

			my $cur_addr = $begin_addr;
			my $last_newline;

			return anon
			{
				has_next => sub
				{
					return $cur_addr != $end_addr;
				},

				print_next => sub
				{
					my ($callback, $fh) = @_;

					$callback->("(($nodetype) $cur_addr)->_M_value_field", $basetype);
					$cur_addr = _Rb_tree_increment($reflector, $cur_addr, $nodetype);
				},
			}
		}
	}
}

##
## Advance the iterator as in _Rb_tree_increment()
## (It would be nice to walk the tree recursively instead...)
##

sub _Rb_tree_increment($$$)
{
	my ($reflector, $__x, $nodetype) = @_;

	my $_M_right = $reflector->eval("(unsigned long) (($nodetype) $__x)->_M_right");
	die "Something wrong here!" unless defined($_M_right);

	if($_M_right)
	{
		$__x = $_M_right;
		my $_M_left;
		while($_M_left = $reflector->eval("(unsigned long) (($nodetype) $__x)->_M_left"))
		{
			$__x = $_M_left;
		}

		die "Something wrong here!" unless defined($_M_left);
	}
	else
	{
		my $__y = $reflector->eval("(unsigned long) (($nodetype) $__x)->_M_parent")
			or die "Something wrong here!";

		while($__x == $reflector->eval("(unsigned long) (($nodetype) $__y)->_M_right"))
		{
			$__x = $__y;
			$__y = $reflector->eval("(unsigned long) (($nodetype) $__y)->_M_parent")
				or die "Something wrong here!";
		}

		$_M_right = $reflector->eval("(unsigned long) (($nodetype) $__x)->_M_right");
		die "Something wrong here" unless defined($_M_right);

		if($_M_right != $__y)
		{
			$__x = $__y;
		}
	}

	return $__x;
}

1;
