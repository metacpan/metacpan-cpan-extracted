# This software is copyright (c) 2004 Alex Robinson.
# It is free software and can be used under the same terms as perl,
# i.e. either the GNU Public Licence or the Artistic License.

package MasonX::Interp::ExtendedCompRoot;

use strict;

our $VERSION = '0.04';

use warnings;

use base qw(HTML::Mason::Interp);



use HTML::Mason::Exceptions( abbr => [qw(param_error system_error wrong_compiler_error compilation_error error)] );

sub new
	{
	my $class = shift;
	my %args = @_;
	
	# add dynamic comp root unless it already exists
	$args{dynamic_comp_root} = 1;
	if (!$args{request_class} or $args{request_class} =~ m/^HTML::Mason::Request/)
		{
		$args{request_class} = 'MasonX::Request::ExtendedCompRoot';
		}
	#@_ = %args;
	my $self = $class->SUPER::new(%args);
	return $self;
	}

# cut and pasted from HTML::Mason::Interp to make two tiny changes
sub load {
    #my ($self, $path) = @_;
    my ($self, $path, $super) = @_; #ECR
    my ($maxfilemod, $objfile, $objfilemod);
    my $code_cache = $self->{code_cache};
    my $resolver = $self->{resolver};

    #
    # Path must be absolute.
    #
    unless (substr($path, 0, 1) eq '/') {
        error "Component path given to Interp->load must be absolute (was given $path)";
    }

    #
    # Get source info from resolver.
    #
    #my $source = $self->resolve_comp_path_to_source($path);
    my $source = $self->resolve_comp_path_to_source($path, $super); #ECR

    # No component matches this path.
    return unless defined $source;

    # comp_id is the unique name for the component, used for cache key
    # and object file name.
    my $comp_id = $source->comp_id;

    #
    # Get last modified time of source.
    #
    my $srcmod = $source->last_modified;

    #
    # If code cache contains an up to date entry for this path, use
    # the cached comp.  Always use the cached comp in static_source
    # mode.
    #
    if ( exists $code_cache->{$comp_id} &&
         ( $self->static_source || $code_cache->{$comp_id}->{lastmod} >= $srcmod )
       ) {
        return $code_cache->{$comp_id}->{comp};
    }

    if ($self->{use_object_files}) {
        $objfile = $self->comp_id_to_objfile($comp_id);

        my @stat = stat $objfile;
        if ( @stat && ! -f _ ) {
            error "The object file '$objfile' exists but it is not a file!";
        }

        if ($self->static_source) {
            # No entry in the code cache so if the object file exists,
            # we will use it, otherwise we must create it.  These
            # values make that happen.
            $objfilemod = @stat ? $srcmod : 0;
        } else {
            # If the object file exists, get its modification time.
            # Otherwise (it doesn't exist or it is a directory) we
            # must create it.
            $objfilemod = @stat ? $stat[9] : 0;
        }
    }

    my $comp;
    if ($objfile) {
        #
        # We are using object files.  Update object file if necessary
        # and load component from there.
        #
        # If loading the object file generates an error, or results in
        # a non-component object, try regenerating the object file
        # once before giving up and reporting an error. This can be
        # handy in the rare case of an empty or corrupted object file.
        #
        if ($objfilemod < $srcmod) {
            $self->compiler->compile_to_file( file => $objfile, source => $source);
        }
        $comp = eval { $self->eval_object_code( object_file => $objfile ) };

        if (!UNIVERSAL::isa($comp, 'HTML::Mason::Component')) {
            $self->compiler->compile_to_file( file => $objfile, source => $source);
            $comp = eval { $self->eval_object_code( object_file => $objfile ) };

            if (!UNIVERSAL::isa($comp, 'HTML::Mason::Component')) {
                my $error = $@ ? $@ : "Could not get HTML::Mason::Component object from object file '$objfile'";
                $self->_compilation_error( $source->friendly_name, $error );
            }
        }
    } else {
        #
        # Not using object files. Load component directly into memory.
        #
        my $object_code = $source->object_code( compiler => $self->compiler );
        $comp = eval { $self->eval_object_code( object_code => $object_code ) };
        $self->_compilation_error( $source->friendly_name, $@ ) if $@;
    }
    $comp->assign_runtime_properties($self, $source);

    #
    # Delete any stale cached version of this component, then
    # cache it.
    #
    $self->delete_from_code_cache($comp_id);
    $code_cache->{$comp_id} = { lastmod => $srcmod, comp => $comp };

    return $comp;
}

# again cut and pasted from HTML::Mason::Interp
# this time slightly more fiddling is required
sub resolve_comp_path_to_source
{
    #my ($self, $path) = @_;
    my ($self, $path, $super) = @_; #ECR
    my $actual_path = $path; #ECR
    my $explicit_key; #ECR
    $actual_path =~ s|.*?=>||; #ECR
    if ($actual_path ne $path) #ECR
        	{ #ECR
        	$explicit_key = $path; #ECR
        	$explicit_key =~ s|(([^=]+)=>)*.*$|$2|; #ECR
        	$explicit_key =~ s|.*/||; #ECR
        	$path = $actual_path; #ECR
        	} #ECR
    my $source;
    if ($self->{static_source}) {
        # Maintain a separate source_cache for each component root,
        # because the set of active component roots can change
        # from request to request.
        #
        
        my $source_cache = $self->{source_cache};
        my @comp_root = @{$self->{comp_root}}; #ECR
        @comp_root = reverse @comp_root if ($super); #ECR
        foreach my $pair (@comp_root) {
        #foreach my $pair (@{$self->{comp_root}}) {
        	next if ($explicit_key and ($pair->[0] ne $explicit_key)); #ECR
            my $source_cache_for_root = $source_cache->{$pair->[0]} ||= {};
            unless (exists($source_cache_for_root->{$path})) {
                $source_cache_for_root->{$path}
                  = $self->{resolver}->get_info($path, @$pair);
            }
            last if $source = $source_cache_for_root->{$path};
        }
    } else {
        my $resolver = $self->{resolver};
        my @comp_root = $self->comp_root_array; #ECR
        @comp_root = reverse @comp_root if ($super); #ECR
        foreach my $pair (@comp_root) {
        #foreach my $pair ($self->comp_root_array) {
            next if ($explicit_key and ($pair->[0] ne $explicit_key)); #ECR
            last if $source = $resolver->get_info($path, @$pair);
        }
    }
    return $source;
}

1;