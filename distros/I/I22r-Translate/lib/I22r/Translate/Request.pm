package I22r::Translate::Request;
use Moose;
use Carp;

our $VERSION = '0.96';

has _config => ( is => 'rw', isa => 'HashRef', 
		 default => sub { {} } );
has results => ( is => 'rw', isa => 'HashRef', default => sub { {} } );
has src => ( is => 'ro', isa => 'Str', required => 1 );
has dest => ( is => 'ro', isa => 'Str', required => 1 );
has text => ( is => 'rw', isa => 'HashRef', required => 1 );
has start => ( is => 'ro', isa => 'Int', default => sub { time } );
has logger => ( is => 'rw' );

# TODO: return_type validation: simple, object, hash
has return_type => ( is => 'ro', isa => 'Str', default => 'simple' );

# TODO: backend validation: 
has backend => ( is => 'rw', default => undef );

our %filters_loaded = ();

sub BUILDARGS {
    my ($class, %opts) = @_;
    my $config = { };
    foreach my $key (keys %opts) {
	if ($key eq 'src' || $key eq 'dest' || $key eq 'text') {
	    $config->{$key} = $opts{$key};
	} else {
	    $config->{_config}{$key} = $opts{$key};
	}
    }
    return $config;
}

sub BUILD {
    my $self = shift;
    $self->{otext} = { %{$self->text} };
}

sub config {
    my ($self, $key) = @_;
    my $r = $self->_config->{$key};
    return $r if defined $r;

    if ($self->backend) {
	$r = $self->_config->{ $self->backend . '::' . $key };
	return $r if defined $r;
	$r = $self->backend->config($key);
	return $r if defined $r;
    }

    return $I22r::Translate::config{$key};
}

sub translations_complete {
    my $self = shift;
    foreach my $id (keys %{$self->text}) {
	if (!defined $self->results->{$id}) {
	    return 0;
	}
    }
    return 1;
}

sub otext {
    my $self = shift;
    return $self->{otext};
}

# return results in accordance with the desired  return_type
sub return_results {
    my $self = shift;
    my $return_type = $self->config('return_type') // 'simple';

    if ($return_type eq 'object') {
	return %{ $self->results };
    }
    if ($return_type eq 'hash') {
	return map { 
	    $_ => $self->results->{$_}->to_hash 
	} keys %{$self->results};
    }
    if ($return_type eq 'simple' || 1) {
	return map {
	    $_ => $self->results->{$_}->text
	} keys %{$self->results};
    }
}

##########################################################
#
# Filter methods
#
##########################################################

sub get_filters {
    my $self = shift;
    my $f1 = $I22r::Translate::config{filter} // [];
    my $f2 = ($self->backend && $self->backend->config('filter')) // [];
    my $f3 = $self->_config->{'filter'} // [];
    return [ map { to_filter($_) } @$f1, @$f2, @$f3 ];
}

sub to_filter {
    my $filter = shift;
    my @args = ();
    if ('ARRAY' eq ref $filter) {
	($filter, @args) = @$filter;
    }
    if (ref $filter) {
	return $filter;
    }
    if ($filter !~ /::/) {
	$filter = "I22r::Translate::Filter::" . $filter;
    }

    my $f = eval "use $filter; $filter->new( \@args )";
    if ($@) {
	# what should we do when filter fails to load? croak or just carp?
	carp "error loading filter $filter: $@\n";
    }
    return $f;

    # TODO - assert  $filter  fulfills the  I22r::Translate::Filter  role
}

sub apply_filters {
    my $self = shift;
    $self->{otext} = { %{$self->text} };

    # apply filters to  $self->text  for any input
    # that doesn't have a result (in  $self->results )
    my @filter_targets = grep {
	!defined $self->results->{$_}
    } keys %{$self->text};

    if (@filter_targets == 0) {
	$self->{filter_targets} = [];
	$self->{filters} = [];
	return;
    }
    $self->{filter_targets} = \@filter_targets;
    $self->{filters} = $self->get_filters;

    foreach my $filter ( @{$self->{filters}} ) {
	I22r::Translate->log(
	    $self->{logger}, " applying filter: ",
	    ref($filter) ? ref($filter) : "$filter" );
	foreach my $id (@filter_targets) {
	    $filter->apply( $self, $id );
	}
    }
}

sub unapply_filters {
    my $self = shift;
    my @targets = @{$self->{filter_targets}};
    foreach my $filter ( reverse @{ $self->{filters} } ) {
	I22r::Translate->log(
	    $self->{logger}, " removing filter: ",
	    ref($filter) ? ref($filter) : "$filter");
	foreach my $id (@targets) {
	    $filter->unapply( $self, $id );
	}
    }
    foreach my $id (@targets) {
	$self->text->{$id} = $self->{otext}{$id};
	if (defined($self->results->{$id})) {
	    $self->results->{$id}{otext} =  $self->text->{$id};
	}
    }
    delete $self->{filter_targets};
    delete $self->{filters};
}

##########################################################
#
# time out methods
#
##########################################################

sub timed_out {
    my $self = shift;
    my $elapsed = time - $self->start;
    if ($self->_config->{timeout} && $elapsed >= $self->_config->{timeout}) {
	I22r::Translate->log($self->{logger}, 
			     "request timed out after ${elapsed}s");
	return 1;
    }

    if ($I22r::Translate::config{timeout} &&
	$elapsed >= $I22r::Translate::config{timeout}) {
	I22r::Translate->log($self->{logger}, 
			     "request timed out after ${elapsed}s");
	return 1;
    }

    if ($self->backend && $self->backend->config('timeout')) {
	if ($self->{backend_start}) {
	    $elapsed = time - $self->{backend_start};
	}
	if ($elapsed >= $self->backend->config('timeout')) {
	    I22r::Translate->log($self->{logger}, 
			     "request timed out after ${elapsed}s");
	    return 1;
	}
    }
    return;
}

##########################################################
#
# Callback functions
#
##########################################################

sub get_callbacks {
    my $self = shift;
    my @callbacks = ($self->_config->{callback},
		     $self->backend 
		     && $self->backend->config("callback"),
		     $I22r::Translate::config{callback});
    return grep defined, @callbacks;
}

sub invoke_callbacks {
    my ($self, @ids) = @_;
    $DB::single = 1;
    return if !@ids;
    my @callbacks = $self->get_callbacks;
    return if ! @callbacks;
    I22r::Translate->log( $self->{logger},
			  "invoking callbacks on inputs ",
			  "@ids" );
    foreach my $id (@ids) {
	foreach my $callback (@callbacks) {
	    $callback->( $self, $self->results->{$id} );
	}
    }
}

##########################################################

__PACKAGE__->meta->make_immutable;
1;

__END__

TODO:

    src_enc, dest_enc

    return_type  validation

    backend  validation, must be undef or fulfill I22r::Translate::Backend role

    new_result($id, $translated_text) method so the backends don't need to
        call the I22r::Translate::Result constructor ??

#'

=head1 NAME

I22r::Translate::Request - translation request object

=head1 DESCRIPTION

Internal translation request object for the L<I22r::Translation>
distribution. If you're not developing a backend or a filter for
this distribution, you can stop reading now.

Otherwise, you'll just need to know that a new C<I22r::Translate::Request>
object is created when you call one of the
 L<I22r::Translate::translate_xxx|I22r::Translate/"translate_string">
methods. 

=head1 METHODS

=head2 src

=head2 dest

The source and target languages for the translation request.

=head2 text

A hash reference whose values are the source strings to be
translated. If the request was created from a C<translate_string>
or C<translate_list> call, the inputs are still put into a hash
reference.

=head2 _config

All other inputs to C<I22r::Translate::translate_xxx> are put
into a configuration hash for the request, accessible through
the C<_config> method.

=head2 config

A special method that examines the current request's configuration,
configuration for the current backend (see L<"backend">), and the
global configuration from L<I22r::Translate>. 

=head2 backend

Get or set the name of the active backend. The C<I22r::Translate>
translation process will iterate through available, qualified
backends until all of the inputs have been translated.

=head2 results

A hashref for translation results. Each key should be the same as
a key in L<< $request->text|"text" >>, and the value is an
L<I22r::Translate::Result> object.

=head1 MORE DEVELOPER NOTES

If you are writing a new L<filter|I22r::Translate::Filter>,
you will want your C<apply> method to operate on an element
of C<< $request->text >> (say, C<< $request->text->{$key} >>,
 and your C<unapply> method to operate on the corresponding
C<< $request->results->{$key}->text >>.

In a backend, you'll want to pass the values in
C<< $request->text >> the translation engine, and populate
C<< $request->results >> with the results of the translation.

=head1 SEE ALSO

L<I22r::Translate>

=cut
