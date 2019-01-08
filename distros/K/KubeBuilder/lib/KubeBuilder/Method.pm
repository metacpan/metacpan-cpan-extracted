package KubeBuilder::Method;
  use Moose;
  use KubeBuilder::Property;

  has operation => (is => 'ro', required => 1, isa => 'Swagger::Schema::Operation');

  has name => (is => 'ro', isa => 'Str', required => 1);

  has root_schema => (
    is => 'ro',
    isa => 'KubeBuilder',
    weak_ref => 1,
    required => 1,
  );

  has return_object_ref => (is => 'ro', isa => 'Swagger::Schema::RefParameter|Undef', lazy => 1, default => sub {
    my $self = shift;
    my $responses = $self->operation->responses;
    my @ok_responses = grep { $_ =~ m/^2/ } keys %$responses;
    my @ok_refs = map { $_->schema }
                  grep { $_->schema->isa('Swagger::Schema::RefParameter') } 
                  map { $responses->{ $_ } }
                  grep { $_ =~ m/^2/ }
                  keys %$responses;
    return undef if (not @ok_refs);
    my $first = $ok_refs[0]->ref;
    my $all_equal = (scalar(@ok_refs) == grep { $_->ref eq $first } @ok_refs);
    die "Not all responses are equal for " . $self->name if (not $all_equal);
    return $ok_refs[0];
  });

  has return_object => (is => 'ro', lazy => 1, default => sub {
    my $self = shift;
    my $obj = $self->root_schema->object_for_ref($self->return_object_ref);
    return $obj;
  });

  has url => (is => 'ro', isa => 'Str', required => 1);
  has method => (is => 'ro', isa => 'Str', required => 1);

  # Some methods are not versioned with v1, v1alpha1, etc
  has is_versionedcall => (is => 'ro', isa => 'Bool', lazy => 1, default => sub {
    my $self = shift;
    my $operation_tag = $self->operation->tags->[0];
    die "No tag for " . $self->name if (not defined $operation_tag);
    my ($group, $version_namespace) = split /_/, $operation_tag, 2;

    return 0 if (not defined $version_namespace);
    return 1;
  });

  has call_classname => (is => 'ro', isa => 'Str', lazy => 1, default => sub {
    my $self = shift;
    my $mname = $self->operation->operationId;
    substr($mname, 0, 1) = uc(substr($mname, 0, 1));

    if ($self->is_versionedcall) {
      # strip off the API version and the API group from the name of the method
      my $version = $self->version_namespace;
      $mname =~ s/$version//i;
      my $group = $self->group;
      $mname =~ s/$group//i;
    }

    return $mname;
  });

  has call_namespace => (is => 'ro', isa => 'Str', default => 'Kubernetes::REST::Call');

  has group => (is => 'ro', isa => 'Str|Undef', lazy => 1, default => sub {
    my $self = shift;
    my $operation_tag = $self->operation->tags->[0];
    die "No tag for " . $self->name if (not defined $operation_tag);
    my ($group, $version_namespace) = split /_/, $operation_tag, 2;
    
    substr($group, 0, 1) = uc(substr($group, 0, 1));
    return $group;
  });

  has version_namespace => (is => 'ro', isa => 'Str|Undef', lazy => 1, default => sub {
    my $self = shift;
    my $operation_tag = $self->operation->tags->[0];
    die "No tag for " . $self->name if (not defined $operation_tag);
    my ($group, $version_namespace) = split /_/, $operation_tag, 2;

    return undef if (not defined $version_namespace);

    #substr($version_namespace, 0, 1) = uc(substr($version_namespace, 0, 1));
    return $version_namespace;
  });

  has fullyqualified_methodname => (is => 'ro', isa => 'Str', lazy => 1, default => sub {
    my $self = shift;

    if (not $self->is_versionedcall) {
      return join '::', $self->call_namespace, $self->call_classname;
    } else {
      return join '::', $self->call_namespace, $self->version_namespace, $self->group, $self->call_classname;
    }
  });

  sub swagger_to_perltype {
    my ($self, $param) = @_;

    return 'Defined' if ($param->{ schema });

    my $type = $param->{ type };
    if      ($type eq 'string') {
      return 'Str';
    } elsif ($type eq 'integer') {
      return 'Int';
    } elsif ($type eq 'boolean') {
      return 'Bool';
    } elsif ($type eq 'number') {
      return 'Num';
    } else {
      die "Unknown type $type";
    }
  }

  has common_parameters => (is => 'ro', isa => 'ArrayRef', default => sub { [] });

  has parameters => (is => 'ro', isa => 'ArrayRef[HashRef]', lazy => 1, default => sub {
    my $self = shift;
    my @params;

    my @parameters = (defined $self->operation->parameters) ? @{ $self->operation->parameters } : ();
    my @common_parameters = (defined $self->common_parameters) ? @{ $self->common_parameters } : ();

    foreach my $param (@parameters, @common_parameters) {
      push @params, {
        name => $param->{ name },
        required => $param->{ required },
        perl_type => $self->swagger_to_perltype($param),
        in => $param->{ in },
      };
    }

    return \@params;
  });

  has type_list => (is => 'ro', isa => 'ArrayRef[Str]', lazy => 1, default => sub {
    my $self = shift;
    my %types = ( map { ($_->{ perl_type } => 1) } @{ $self->parameters } );
    return [ sort keys %types ];
  });

  sub filter_parameters {
    my $type = shift;
    return sub {
      my $self = shift;
      return [
        grep { $_->{ in } eq $type } @{ $self->parameters }
      ];
    }
  }

  has query_params => (is => 'ro', isa => 'ArrayRef[HashRef]', lazy => 1, default => filter_parameters('query'));
  has url_params => (is => 'ro', isa => 'ArrayRef[HashRef]', lazy => 1, default => filter_parameters('path'));
  has body_params => (is => 'ro', isa => 'ArrayRef[HashRef]', lazy => 1, default => filter_parameters('body'));


1;
