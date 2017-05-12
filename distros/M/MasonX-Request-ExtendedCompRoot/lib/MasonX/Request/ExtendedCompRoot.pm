# This software is copyright (c) 2004 Alex Robinson.
# It is free software and can be used under the same terms as perl,
# i.e. either the GNU Public Licence or the Artistic License.

package MasonX::Request::ExtendedCompRoot;

use strict;

our $VERSION = '0.04';

use Carp;
use Data::Dumper;

use base qw(HTML::Mason::Request);

# Need this because we've copied comp to _comp
use constant STACK_BUFFER       => 2;

# fetch_comp needs this
use HTML::Mason::Tools qw(absolute_comp_path);
use HTML::Mason::Exceptions( abbr => [qw(param_error error)] ); 
use Params::Validate qw(:all);
Params::Validate::validation_options( on_fail => sub { param_error( join '', @_ ) } );
use File::Spec;# qw(canonpath file_name_is_absolute);

my %params =
	(
	pseudodhandler_exclude_paths =>
		{
		type => ARRAYREF,
		optional => 1,
		default => [],
		descr => 'list of regular expressions to match paths for pseudo-dhandlering to ignore'
		},
	pseudodhandler_exclude_comp_roots =>
		{
		type => ARRAYREF,
		optional => 1,
		default => [],
		descr => 'list of regular expressions to match comp roots for pseudo-dhandlering to ignore'
		},
	pseudodhandler_name =>
		{
		type => SCALAR,
		optional => 1,
		default => 'pseudodhandler',
		descr => "The filename to use for ExtendedCompRoot's 'pseudodhandler' capability - an empty string suppresses its use"
		}
	);

__PACKAGE__->valid_params(%params);

#
# Standard request subclass alter_superclass dance
#
sub new
	{
	my $class = shift;
	$class->alter_superclass(
		$HTML::Mason::ApacheHandler::VERSION ?
		'HTML::Mason::Request::ApacheHandler' :
		$HTML::Mason::CGIHandler::VERSION ?
		'HTML::Mason::Request::CGI' :
		'HTML::Mason::Request' );
	my $self = $class->SUPER::new(@_);

	return $self->_init_extended(@_);
	}

sub _init_extended
	{
	my $self = shift;
	my %params = @_;
	
	my $store_root = $self->comp_root;
	$self->_base_comp_root($store_root);
	$self->_pseudodhandler_exclude_paths($params{pseudodhandler_exclude_paths});
	$self->_pseudodhandler_exclude_comp_roots($params{pseudodhandler_exclude_comp_roots});
	$self->pseudodhandler_name($params{pseudodhandler_name});

	return $self;

	}

sub _base_comp_root
	{
	my $self = shift;
	my $value = shift;
	$self->{base_comp_root} = $value if (defined($value));
	return $self->{base_comp_root};
	}
sub pseudodhandler_name
	{
	my $self = shift;
	my $value = shift;
	$self->{pseudodhandler_name} = $value if (defined($value));
	return $self->{pseudodhandler_name};
	}

sub pseudodhandler_arg
	{
	my $self = shift;
	my $value = shift;
	$self->{pseudodhandler_arg} = $value if (defined($value));
	return $self->{pseudodhandler_arg};
	}

sub adjusted_args
	{
	my $self = shift;
	my $key = shift;
	my $value = shift;
	unless ($self->{adjusted_args_initialised})
		{
		$self->{adjusted_args} = $self->{request_args};
		$self->{adjusted_args_initialised} = 1;
		}
	
	unless ($key)
		{
		if (wantarray)
			{
			return @{$self->{adjusted_args}};
			}
		else
			{
			return { @{$self->{adjusted_args}} };
			}
		}
	# surely I can do better than this?
	my %adjusted_args = @{$self->{adjusted_args}};
	
	return $adjusted_args{$key} unless (defined($value));
	
	$adjusted_args{$key} = $value;
	my @store_adjusted = %adjusted_args;
	$self->{adjusted_args} = \@store_adjusted;
	return $self->adjusted_args($key);
	}

sub _pseudodhandler_exclude_paths
	{
	my ($self, $exclude_paths) = @_;
	if (defined($exclude_paths))
		{ 
		$self->{pseudodhandler_exclude_paths} = $exclude_paths;
		}
	$exclude_paths = $self->{pseudodhandler_exclude_paths};
	return $exclude_paths ? @{$exclude_paths} : ();
	}
sub _pseudodhandler_exclude_comp_roots
	{
	my ($self, $exclude_roots) = @_;
	if (defined($exclude_roots))
		{
		$self->{pseudodhandler_exclude_comp_roots} = $exclude_roots;
		}
	$exclude_roots = $self->{pseudodhandler_exclude_comp_roots};
	return $exclude_roots ? @{$exclude_roots} : ();
	}


# to enable the passing of INHERIT and SUPER and also allow pseudo-dhandlering
# copied and pasted from HTML::Mason::Request 1.30 - checked against 1.37
sub _fetch_comp
{
    my ($self, $path, $current_comp, $error) = @_;

    #
    # Handle paths SELF, PARENT, and REQUEST
    #
    if ($path eq 'SELF') {
        return $self->base_comp;
    }
    if ($path eq 'PARENT') {
        my $c = $current_comp->parent;
        $$error = "PARENT designator used from component with no parent" if !$c && defined($error);
        return $c;
    }
    if ($path eq 'REQUEST') {
        return $self->request_comp;
    }

    #
    # Handle paths of the form comp_path:method_name
    #
    if (index($path,':') != -1) {
        my $method_comp;
        my ($owner_path,$method_name) = split(':',$path,2);
        if (my $owner_comp = $self->fetch_comp($owner_path, $current_comp, $error)) {
            if ($owner_comp->_locate_inherited('methods',$method_name,\$method_comp)) {
                return $method_comp;
            } else {
            	if ($owner_path =~ m/^(INHERIT|SUPER)/) #ECR
            		{ #ECR
            		$owner_path = $current_comp->path; #ECR
            		my @comp_root = $self->comp_root; #ECR
            		@comp_root = reverse(@comp_root) if ($owner_path eq 'SUPER'); #ECR
            		foreach my $root (@comp_root) #ECR
            			{ #ECR
						if (my $owner_comp = $self->fetch_comp($root->[0].'=>'.$owner_path, $current_comp, $error)) #ECR
							{ #ECR
							if ($owner_comp->_locate_inherited('methods',$method_name,\$method_comp)) #ECR
								{ #ECR
								return $method_comp; #ECR
								} #ECR
							} #ECR
            			} #ECR
            		$$error = "no such method '$method_name' exists in any comp root for component " . $owner_comp->title . " <- topmost root" if defined($error); #ECR
            		return; #ECR
            		} #ECR
                $$error = "no such method '$method_name' for component " . $owner_comp->title if defined($error);
            }
        } else {
            $$error ||= "could not find component for path '$owner_path'\n" if defined($error);
        }

        return $method_comp;
    }

	my $super; #ECR
	if ($path =~ m/(SUPER|INHERIT)$/) #ECR
    	{
    	$super = 1 if ($path =~ m/SUPER$/); #ECR
    	$path = $current_comp->path; #ECR
    	#die "YADDER SUPER - ". $path; #ECR
    	} #ECR
    if ($path =~ m/^_/) #ECR
    	{ #ECR
    	$path =~ s/^_//; #ECR
	# unfortunately, Mason::Request has a local select #ECR
		if ($path =~ m/::SELECTED/) #ECR
			{ #ECR
			$path = 'select'; #ECR
			} #ECR
		my $tags_path = $self->notes->{_OUTPUT}->{tag_type} || 'xhtml1-strict'; #ECR
		$path = "/tags/$tags_path/$path"; #ECR
    	} #ECR

    #
    # If path does not contain a slash, check for a subcomponent in the
    # current component first.
    #
    if ($path !~ /\//) {
        # Check my subcomponents.
        if (my $subcomp = $current_comp->subcomps($path)) {
            return $subcomp;
        }
        # If I am a subcomponent, also check my owner's subcomponents.
        # This won't work when we go to multiply embedded subcomponents...
        if ($current_comp->is_subcomp and my $subcomp = $current_comp->owner->subcomps($path)) {
            return $subcomp;
        }
    }

    #
    # Otherwise pass the canonicalized absolute path to interp->load.
    #
    $path = absolute_comp_path($path, $current_comp->dir_path);
    #my $comp = $self->interp->load($path);
    my $comp = $self->interp->load($path, $super); #ECR

	# ECR addition
	# If no comp exists and pseudodhandlering is on
	#
	if (!$comp and $self->pseudodhandler_name)
		{
		my $pseudodhandler_arg;
		# make any necessary adjustments to the comp_root
		# grab the comp root and stash it
		my @comp_root = $self->comp_root;
		my @store_comp_root = @comp_root;
		# check the list of excluded comp_roots
		my @exclude_roots = $self->_pseudodhandler_exclude_comp_roots;
		foreach my $exclude (@exclude_roots)
			{
			@comp_root = grep { $_->[0] !~ m/$exclude/ } @comp_root;
			}
		# check the list of excluded comp root paths 
		my @exclude_paths = $self->_pseudodhandler_exclude_paths;
		foreach my $exclude (@exclude_paths)
			{
			@comp_root = grep { $_->[1] !~ m/$exclude/ } @comp_root;
			}
		# set the adjusted comp_root
		$self->comp_root(\@comp_root);
		while (($path) and (!$comp))
			{
			my $pseudoprefix = $path;
			my $pseudodelimit = '-';
			$pseudoprefix =~ s|/|$pseudodelimit|g;
			$pseudoprefix =~ s|^$pseudodelimit(.*)|$1$pseudodelimit|;
			my $check_path = $path.'/'.$pseudoprefix.$self->pseudodhandler_name;
			$comp = $self->interp->load($check_path, $super);
			unless ($comp)
				{
				$check_path = $path.'/'.$self->pseudodhandler_name;
				$comp = $self->interp->load($check_path, $super);
				}
			if ($comp)
				{
				$pseudodhandler_arg =~ s|^/||;
				$self->pseudodhandler_arg($pseudodhandler_arg);
				last;
				}
			$path =~ s|(/[^/]+$)||;
			$pseudodhandler_arg = $1.$pseudodhandler_arg;
			last if ($path =~ m|=>$|);
			}
		# reset the adjusted comp_root
		$self->comp_root(\@store_comp_root);
		}
	## ECR addition ends

    return $comp;
}

sub comp
	{
	my $self = shift;
	my $original_pseudodhandler_arg = $self->pseudodhandler_arg;
	$self->pseudodhandler_arg('');
	my ($result, @results);
	if (wantarray)
		{
		@results = $self->_comp(@_);
		}
	else
		{
		$result = $self->_comp(@_);
		}
	$self->pseudodhandler_arg($original_pseudodhandler_arg);
	return wantarray ? @results : $result;
	}

#
# _comp copied from 1.37 for adjustment
#
sub _comp {
    my $self = shift;

    # Get modifiers: optional hash reference passed in as first argument.
    # Merge multiple hash references to simplify user and internal usage.
    #
    my %mods;
    %mods = (%{shift()}, %mods) while ref($_[0]) eq 'HASH';

    # Get component path or object. If a path, load into object.
    #
    my $path;
    my $comp = shift;
    if (!ref($comp)) {
        die "comp called without component - must pass a path or component object"
            unless defined($comp);
        $path = $comp;
        my $error;
        $comp = $self->fetch_comp($path, undef, \$error)
            or error($error || "could not find component for path '$path'\n");
    }

    # Increment depth and check for maximum recursion. Depth starts at 1.
    #
    my $depth = $self->depth;
    error "$depth levels deep in component stack (infinite recursive call?)\n"
        if $depth >= $self->{max_recurse};

    # Keep the same output buffer unless store modifier was passed. If we have
    # a filter, put the filter buffer on the stack instead of the regular buffer.
    #
    my $filter_buffer = '';
    my $top_buffer = defined($mods{store}) ? $mods{store} : $self->{top_stack}->[STACK_BUFFER];
    my $stack_buffer = $comp->{has_filter} ? \$filter_buffer : $top_buffer;
    $stack_buffer = \$filter_buffer; #ECR
    my $flushable = exists $mods{flushable} ? $mods{flushable} : 1;

    # Add new stack frame and point dynamically scoped $self->{top_stack} at it.
    push @{ $self->{stack} },
        [ $comp,           # STACK_COMP
          \@_,             # STACK_ARGS
          $stack_buffer,   # STACK_BUFFER
          \%mods,          # STACK_MODS
          $path,           # STACK_PATH
          undef,           # STACK_BASE_COMP
          undef,           # STACK_IN_CALL_SELF
          $flushable,      # STACK_BUFFER_IS_FLUSHABLE
        ];
    local $self->{top_stack} = $self->{stack}->[-1];

    # Run start_component hooks for each plugin.
    #
    if ($self->{has_plugins}) {
        my $context = bless
            [$self, $comp, \@_],
            'HTML::Mason::Plugin::Context::StartComponent';

        foreach my $plugin_instance (@{$self->{plugin_instances}}) {
            $plugin_instance->start_component_hook( $context );
        }
    }

    # Finally, call the component.
    #
    my $wantarray = wantarray;
    my @result;
    
    eval {
        # By putting an empty block here, we protect against stack
        # corruption when a component calls next or last outside of a
        # loop. See 05-request.t #28 for a test.
        {
            if ($wantarray) {
                @result = $comp->run(@_);
            } elsif (defined $wantarray) {
                $result[0] = $comp->run(@_);
            } else {
                $comp->run(@_);
            }
        }
    };
    my $error = $@;

    # Run component's filter if there is one, and restore true top buffer
    # (e.g. in case a plugin prints something).
    #
    if ($comp->{has_filter}) {
        # We have to check $comp->filter because abort or error may
        # occur before filter gets defined in component. In such cases
        # there should be no output, but should look into this more.
        #
        if (defined($comp->filter)) {
            $$top_buffer .= $comp->filter->($filter_buffer);
        }
        #$self->{top_stack}->[STACK_BUFFER] = $top_buffer; # -ECR
    } else { #ECR
        my $filter_newlines = $comp->{flags}->{filter_newlines} || 
        $self->{interp}->{filter_newlines} || 'all'; #ECR
        if ($filter_newlines and $filter_newlines ne 'none') { #ECR
            my $lines_to_filter = $filter_newlines eq 'all' ? '' : '1'; #ECR
            $filter_buffer =~ s/^\n{1,$lines_to_filter}//; #ECR
            $filter_buffer =~ s/\n{1,$lines_to_filter}$//; #ECR
        } #ECR
        $$top_buffer .= $filter_buffer; #ECR
    }
    $self->{top_stack}->[STACK_BUFFER] = $top_buffer; #ECR

    # Run end_component hooks for each plugin, in reverse order.
    #
    if ($self->{has_plugins}) {
        my $context = bless
            [$self, $comp, \@_, $wantarray, \@result, \$error],
            'HTML::Mason::Plugin::Context::EndComponent';
        
        foreach my $plugin_instance (@{$self->{plugin_instances_reverse}}) {
            $plugin_instance->end_component_hook( $context );
        }
    }

    # This is very important in order to avoid memory leaks, since we
    # stick the arguments on the stack. If we don't pop the stack,
    # they don't get cleaned up until the component exits.
    pop @{ $self->{stack} };

    # Repropagate error if one occurred, otherwise return result.
    rethrow_exception $error if $error;
    return $wantarray ? @result : $result[0];
}

sub content
	{
	my $self = shift;
	my $buffer = $self->SUPER::content;
	$buffer =~ s/^\n+/\n/;
	$buffer =~ s/\n+$/\n/;
	return $buffer;
	}

#
# Call Request.pm's exec, then put comp_root back 
# to what it was when the current request or subrequest was made
#
sub exec
	{
	my $self = shift;
	$self->comp_root(@{$self->_base_comp_root});
	#$self->_store_comp_root;
	my $return_exec = $self->SUPER::exec(@_);
	$self->comp_root(@{$self->_base_comp_root});
	return $return_exec;
	}

#
# make alias to $interp->comp_root
#
sub comp_root
	{
	my $self = shift;

	unless (@_)
		{
		my $return_root = $self->interp->comp_root;
		return (wantarray) ? @{$return_root} : $return_root;
		}

	my @root = $self->_munge_root(@_);
	my $return_root = $self->interp->comp_root(\@root);
	return (wantarray) ? @{$return_root} : $return_root;
	}

sub _munge_root
	{
	my $self = shift;
	
	my @roots = @_;

	foreach my $root (@roots)
		{
		if (ref($root) eq 'ARRAY')
			{
			my @inner_root = @{$root};
			if (scalar(@inner_root) == 2)
				{
				unless (ref($inner_root[0]) eq 'ARRAY')
					{
					next if (index($inner_root[0], '=>') == -1);
					}
				}
			@roots = $self->_munge_root(@inner_root);
			}
		elsif (ref($root) eq 'HASH')
			{
			my @hasharray = map { $_, $root->{$_} } keys %{$root};
			$root = \@hasharray;
			}
		else
			{
			my @strings = split('=>', $root);
			$root = \@strings if (@strings);
			}
		}
	return @roots;
	}

#
# add further comp_roots to the beginning of the comp_root array
#
sub prefix_comp_root
	{
	my $self = shift;
	my @prefix = $self->_munge_root(@_);
	my $foo = $self->comp_root;
	if (ref($foo) ne 'ARRAY')
		{
		$foo = [['MAIN', $foo]];
		}
	unshift(@{$foo}, @prefix);
	$self->comp_root($foo);
	return;
	}


#
# reverse the comp root - what it says on the can
#
sub _reverse_comp_root
	{
	my $self = shift;
	my @comp_root_array = $self->comp_root();
	@comp_root_array = reverse @comp_root_array;
	$self->comp_root(\@comp_root_array);
	return;
	}


#
# Register - for when notes is not sufficent
#
sub register
	{
	my $self = shift;
	my %params = @_;
	return unless ($params{namespace} or $params{name});
	my $namespace = $params{namespace} || 'default';
	my $name = $params{name} || 'default';
	my $content = $params{content};
	my $contents = $params{contents};
	my $marker = $params{marker};
	my $marker_key = $params{marker_key};
	my $priority = $params{priority};
	my $remove = $params{remove};
	my $clear = $params{clear};
	my $clear_priority = $params{clear_priority};
	my $unlock = $params{unlock};
	my $lock = $params{lock};
	my $allow_duplicates = $params{allow_duplicates};
	my $overwrite = $params{overwrite};

	# unlock if required, spanner out if locked, lock if required
	# NB. you can unlock, set the register and lock all in one
	if ($unlock)
		{
		delete $self->{_REGISTER}{$namespace}{$name}{locked};
		}
	return if ($self->{_REGISTER}{$namespace}{$name}{locked});
	if ($lock)
		{
		$self->{_REGISTER}{$namespace}{$name}{locked} = 1;
		}

	if ($remove)
		{
		if ($self->{_REGISTER}{$namespace}{$name}{priority})
			{
			foreach my $key (sort keys %{$self->{_REGISTER}{$namespace}{$name}{priority}})
				{
				next if (defined($priority) and $priority != $key);
				my @temp;
				foreach my $bundle (@{$self->{_REGISTER}{$namespace}{$name}{priority}{$key}})
					{
					if ($bundle->{marker} =~ m|^$remove$|)
						{
						delete $self->{_REGISTER}{$namespace}{$name}{scoreboard}{$key}{$bundle->{marker}};
						}
					else
						{
						push(@temp, $bundle);
						}
					}
				$self->{_REGISTER}{$namespace}{$name}{priority}{$key} = \@temp;
				}
			}
		}

	# Here comes the get
	unless (defined $content or $contents)
		{
		my @registered;
		if ($self->{_REGISTER}{$namespace}{$name}{priority})
			{
			foreach my $key (sort keys %{$self->{_REGISTER}{$namespace}{$name}{priority}})
				{
				next if (defined($priority) and $priority != $key);
				foreach my $bundle (@{$self->{_REGISTER}{$namespace}{$name}{priority}{$key}})
					{
					push(@registered, $bundle->{content});
					}
				}
			}
		if ($clear)
			{
			$self->{_REGISTER}{$namespace}{$name} = undef;
			}
		if (!wantarray) { return pop(@registered); }
		return @registered;
		}

	if ($clear)
		{
		$self->{_REGISTER}{$namespace}{$name} = undef;
		}


	# sanity check the priority level
	$priority = 0.5 unless defined $priority;
	$priority += 0;
	# maybe this is unfairly restrictive, but it's good to have boundaries
	$priority = 0 if ($priority < 0);
	$priority = 1 if ($priority > 1);
	# $marker prevents duplicate entries per priority level
	# NB. if you want to add the same entry to different priorities, that's your bag
	unless ($marker)
		{
		if ($marker_key)
			{
			$marker = $content->{$marker_key};
			}
		else
			{
			$marker = ref $content ? ($content->{marker} || $content->{content}) : $content;
			}
		}
	
	if ($clear_priority)
		{
		$self->{_REGISTER}{$namespace}{$name}{priority}{$priority} = [];
		delete $self->{_REGISTER}{$namespace}{$name}{scoreboard}{$priority}{$marker};
		}
	
	if ($contents)
		{
		my %new_params = %params;
		delete $new_params{content};
		delete $new_params{contents};
		delete $new_params{clear};
		delete $new_params{clear_priority};
		foreach my $new_content (@{$contents})
			{
			$new_params{content} = $new_content;
			&register(%new_params);
			}
		return;
		}

	unless ($allow_duplicates and not $overwrite)
		{
		if ($self->{_REGISTER}{$namespace}{$name}{scoreboard}{$priority}{$marker})
			{
			return 'already registered' unless ($overwrite);
			my @temp = grep { $_->{marker} ne $marker } @{$self->{_REGISTER}{$namespace}{$name}{priority}{$priority}};
			$self->{_REGISTER}{$namespace}{$name}{priority}{$priority} = \@temp;
			}
		}
	
	# ensure a priority slot exists
	$self->{_REGISTER}{$namespace}{$name}{priority}{$priority} ||= [];
	# and make a note that this has been done
	$self->{_REGISTER}{$namespace}{$name}{scoreboard}{$priority}{$marker} = 1;
	# pump the parameters into the slot
	push (@{$self->{_REGISTER}{$namespace}{$name}{priority}{$priority}}, {content=>$content, marker=>$marker});
	return;
	};

#
# Register errors
#
sub register_error
	{
	my $self = shift;
	return $self->_register_namespace('error', @_);
	}
#
# Register warnings
#
sub register_warning
	{
	my $self = shift;
	return $self->_register_namespace('warning', @_);
	}
#
# Register info
#
sub register_info
	{
	my $self = shift;
	return $self->_register_namespace('info', @_);
	}
sub _register_namespace
	{
	my $self = shift;
	my $namespace = shift;
	my %params;
	my $name;
	my $content;

	if (scalar(@_)%2)
		{
		$name = shift;
		}
	%params = @_;
	$params{name} = $name if defined($name);
	
	unless ($params{name})
		{
		$name = shift;
		return unless ($name);
		if (scalar(@_)%2)
			{
			$content = shift;
			}
		%params = @_;
		$params{content} = $content if defined($content);
		$params{name} = $name if defined($name);
		}

	$params{namespace} = $namespace;
	return $self->register(%params);
	}


sub share_var
	{
	my $self = shift;
	my $var_name = shift;
	my $var_value = shift;
	my $comp_path = $self->current_comp->path;
	$comp_path =~ s/:.*//;
	$self->notes->{_SHARED}->{$comp_path}->{$var_name} = $var_value if (defined($var_value));
	return $self->notes->{_SHARED}->{$comp_path}->{$var_name};
	}

1;


__END__

=head1 NAME

MasonX::Request::ExtendedCompRoot - Extend functionality of Mason's component root

=head1 SYNOPSIS

In your F<httpd.conf> file:

  PerlSetVar  MasonRequestClass   MasonX::Request::ExtendedCompRoot
  PerlSetVar  MasonResolverClass  MasonX::Resolver::ExtendedCompRoot

Or when creating an ApacheHandler object:

  my $ah =
      HTML::Mason::ApacheHandler->new
          ( request_class  => 'MasonX::Request::ExtendedCompRoot',
            resolver_class => 'MasonX::Resolver::ExtendedCompRoot'
            ...
          );

Once Mason is up and running, ExtendedCompRoot allows you to:

  # completely override the component root
  $m->comp_root({key1=>'/path/to/root1'}, {key2=>'/path/to/root2'});
  
  # add another root to the component root
  $m->prefix_comp_root('key=>/path/to/root');
  
  # call a component in a specific component root
  <& key=>/path/to/comp &>

C<MasonX::Request::ExtendedCompRoot> can also be used as the request class when running Mason in standalone mode.

=head1 DESCRIPTION

=head2 DYNAMIC COMPONENT ROOT

C<MasonX::Request::ExtendedCompRoot> lets you alter Mason's component root during the lifetime of any given request or subrequest.

This behaviour is useful if you want to override certain components, but cannot determine that at the moment you create your handler (when you could in theory create an interp object with a different component root) or because you configure Mason in an F<httpd.conf>.

For example:

  # outputs component in /path/to/root1
  <& /path/to/comp &>
  
  % $m->prefix_comp_root('another_key=>/path/to/root2');
  
  # now outputs component in /path/to/root2 if it exists
  # if it doesn't, the output remains the component in /path/to/root1
  <& /path/to/comp &>

At the end of each request or subrequest, the component root is reset to its initial state.

=head2 ADDITIONAL COMPONENT CALL SYNTAX

C<MasonX::Request::ExtendedCompRoot> also provides syntactical glue to enable calling a component in a specific component root that would otherwise be inaccessible via the usual search path.

  <& key=>/path/to/comp &>

ie. A given component path matches the first file found in an ordered search through the roots, but if preceded with the named key of a component root, matches the file found in that root.

This leaves the rules for calling methods that deal with component paths (C<$m->comp>, C<$m->comp_exists>, C<$m->fetch_comp>) as follows:

=over 4

=item * If the path is absolute (starting with a '/'), then the component is found relative to the component root.

=item * If the path contains the component root delimiter ('=>'), then the component is found in the specified component root.

=item * If the path is relative (no leading '/'), then the component is found relative to the current component directory.

=item * If the path matches both a subcomponent and file-based component, the subcomponent takes precedence.

=head2 QUASI-INHERITANCE FOR MASON METHODS

Calls to component methods work slightly differently to standard Mason behaviour.

The standard behaviour is:

  a) search component root for component
  b) if a component is found, look up method in that component
  c) stop regardless of whether a method exists there or not

This makes perfect sense since a given component path can only ever match the first file found in an ordered search through the roots. However, that doesn't hold true for C<MasonX::Request::ExtendedCompRoot>.

The ExtendedCompRoot way is:

  a) search component root for component
  b) if a component is found, look up method in that component
  c) if no method is found in that component, continue searching the component root

This has the effect of allowing methods to percolate up through the component root as if they were "inherited".

For example, given a component root [key1=>'path/to/root1', key2=>'/path/to/root2'], if '/path/to/comp' exists in both roots, but only the component in key2 has a method called 'method_name':

  # outputs component in key1
  <& /path/to/comp &> 

  # outputs method in key2
  <& /path/to/comp:method_name &>

NB. in the above example, only the method is accessed - the components in key1 and key2 are separate and variables are not shared between them. If you wanted such behaviour, you would either need to make any such variables global or else use $m->notes or even create get and set methods to pass the variables back and forth.

=head1 USAGE

=head2 SET UP

To use this module you need to tell Mason to use this class for requests and C<MasonX::Resolver::ExtendedCompRoot> for its resolver.  This can be done in two ways.  If you are configuring Mason via your F<httpd.conf> file, simply add this:

  PerlSetVar  MasonRequestClass    MasonX::Request::ExtendedCompRoot
  PerlSetVar  MasonResolverClass   MasonX::Resolver::ExtendedCompRoot

If you are using a F<handler.pl> file, simply add this parameter to
the parameters given to the ApacheHandler constructor:

  request_class  => 'MasonX::Request::ExtendedCompRoot'
  resolver_class => 'MasonX::Resolver::ExtendedCompRoot'

=head2 METHODS

=over 4

=item * comp_root

Returns an array of component roots if no arguments are passed.

  my @comp_root = $m->comp_root;     # just returns the comp_root

If any arguments are passed, the existing component root is replaced with those values.

Any argument passed must have a name and a path. The name must be unique and the path absolute and actually exist.

Arguments can be passed as an argument list of scalars, hashes or arrays (or a combination of any of those) or as an array ref to such a list - the following examples are all equivalent:
  
  # as scalar - must take form NAME=>PATH
  $m->comp_root('key1=>/path/to/root1', 'key2=>/path/to/root2');

  $m->comp_root({key1=>'/path/to/root1'}, {key2=>'/path/to/root2'});

  $m->comp_root(['key1','/path/to/root1'], ['key2','/path/to/root2']);

  $m->comp_root('key1=>/path/to/root1', {key2=>'/path/to/root2'}, ['key3','/path/to/root3']);

  my @new_comp_root = ('key1=>/path/to/root1', 'key2=>/path/to/root2');
  $m->comp_root(\@new_comp_root);

=item * prefix_comp_root

Adds passed arguments to the beginning of the current component root array.

  $m->prefix_comp_root('key=>/path/to/root');

Arguments for C<prefix_comp_root> are treated in exactly the same way as those for C<comp_root>.

=back

=head1 PREREQUISITES

HTML::Mason

=head1 BUGS

No known bugs. Unless the inability to insert non-existent or non-absolute paths into the component root is considered a bug.

=head1 VERSION

0.04

=head1 SEE ALSO

L<HTML::Mason>, L<MasonX::Resolver::ExtendedCompRoot>, L<MasonX::Request::WithApacheSession>

=head1 AUTHOR

Alex Robinson, <cpan[@]alex.cloudband.com>

=head1 LICENSE

MasonX::Request::ExtendedCompRoot is free software and can be used under the same terms as Perl, i.e. either the GNU Public Licence or the Artistic License.

=cut