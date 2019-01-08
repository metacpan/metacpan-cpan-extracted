package KubeBuilder::Path;
  use Moose;
  has object => (is => 'ro', required => 1);
  has schema => (is => 'ro', required => 1, isa => 'KubeBuilder');
  has path   => (is => 'ro', required => 1);

package KubeBuilder::Logger;
  use Moose;
  use v5.10;
  has log_level => (is => 'ro', default => 5);
  sub debug { if (shift->log_level > 4) { say '[DEBUG] ', $_ for @_ } }
  sub info  { if (shift->log_level > 3) { say '[INFO ] ', $_ for @_ } }
  sub warn  { if (shift->log_level > 2) { say '[WARN ] ', $_ for @_ } }
  sub error { if (shift->log_level > 0) { say '[ERROR] ', $_ for @_ } }

package KubeBuilder::Error;
  use Moose;
  extends 'Throwable::Error';

package KubeBuilder;
  use Moose;
  use Swagger::Schema::Kubernetes;
  our $VERSION = '0.02';
  #ABSTRACT: Module to help build the Perl Kubernetes client

  use KubeBuilder::Object;
  use KubeBuilder::Method;
  use KubeBuilder::Group;

  has schema_file => (
    is => 'ro',
    isa => 'Str',
    required => 1,
  );

  has schema => (
    is => 'ro', 
    isa => 'Swagger::Schema::Kubernetes',
    lazy => 1,
    default => sub {
      my $self = shift;
      my $data = file($self->schema_file)->slurp;
      KubeBuilder::Error->throw("Couldn't read file " . $self->schema_file) if (not defined $data);
      $data =~ s/^\xEF\xBB\xBF//;
      return Swagger::Schema::Kubernetes->MooseX::DataModel::new_from_json($data);
    }
  );

  has log => (
    is => 'ro',
    default => sub {
      KubeBuilder::Logger->new;
    }
  );

  has objects => (
    is => 'ro',
    isa => 'HashRef[KubeBuilder::Object]',
    lazy => 1,
    traits => [ 'Hash' ],
    handles => {
      object_list => 'values',
    },
    default => sub {
      my $self = shift;
      my %objects => ();

      # Get objects from the definitions (almost everything refs out to defintions/NameOfObject
      my $definitions = (defined $self->schema->definitions) ? $self->schema->definitions : {};

      foreach my $def_name (sort keys %$definitions) {
        my $object = $self->schema->definitions->{ $def_name };

        next if (not exists $object->{ properties });

        $objects{ $def_name } = 
          KubeBuilder::Object->new(
            original_schema => $object,
            root_schema => $self,
            name => $def_name,
          );

        #$self->_get_subobjects_in(\%objects, $def_name, $objects{ $ob_name });
      }

      return \%objects;
    }
  );

  has method_groups => (is => 'ro', isa => 'HashRef[KubeBuilder::Group]', lazy => 1, default => sub {
    my $self = shift;
    my %groups = ();
    foreach my $m (@{ $self->method_list }) {
      my $group_name = $m->group;
      $groups{ $group_name } = KubeBuilder::Group->new(methods => [], name => $group_name) if (not defined $groups{ $group_name });
      push @{ $groups{ $group_name }->methods }, $m;
    }
    return \%groups;
  });

  has method_groups_list => (is => 'ro', isa => 'ArrayRef[KubeBuilder::Group]', lazy => 1, default => sub {
    my $self = shift;
    [ map { $self->method_groups->{ $_ } } sort keys %{ $self->method_groups } ];
  });

  has method_list => (is => 'ro', isa => 'ArrayRef[KubeBuilder::Method]', lazy => 1, default => sub {
    my $self = shift;
    [ map { $self->methods->{ $_ } } sort keys %{ $self->methods } ];
  });

  has methods => (
    is => 'ro',
    isa => 'HashRef[KubeBuilder::Method]',
    lazy => 1,
    default => sub {
      my $self = shift;
      my %methods => ();


      foreach my $path (sort keys %{ $self->schema->paths }) {
        my $common_parameters = $self->schema->paths->{ $path }->parameters;

        foreach my $method (qw/get post put delete options head patch/) {
          my $operation = $self->schema->paths->{ $path }->$method;
          next if (not defined $operation);

          my $method_name = $operation->operationId;
          $methods{ $method_name } = 
            KubeBuilder::Method->new(
              operation => $operation,
              root_schema => $self,
              name => $method_name,
              url => $path,
              method => uc($method),
              (defined $common_parameters) ? (common_parameters => $common_parameters) : (),
            );
        }
      }

      return \%methods;
    }
  );


  sub build {
    my $self = shift;

    $self->process_template(
      'main_module',
      { builder => $self },
    );

    $self->process_template(
      'result2object',
      { builder => $self },
    );

    foreach my $m_name (sort keys %{ $self->methods }){
      my $method = $self->methods->{ $m_name };
      $self->log->info("Generating method for definition $m_name");
      $self->process_template(
        'method',
        { method => $method },
      );
    }
  }


  #
  # Template processing methods
  #

  use Template;
  use Path::Class;

  has _tt => (is => 'ro', isa => 'Template', default => sub {
    Template->new(
      INCLUDE_PATH => "$FindBin::Bin/../templates",
      INTERPOLATE => 0,
    );
  });

  has output_dir => (
    is => 'ro',
    isa => 'Str',
    default => 'auto-lib/'
  );

  sub process_template {
    my ($self, $template_file, $vars) = @_;

    $self->log->debug('Processing template \'' . $template_file . '\'');

    $vars = {} if (not defined $vars);
    my $output = '';
    $self->_tt->process(
      $template_file,
      { c => $self, %$vars },
      \$output
    ) or die "Error processing template " . $self->_tt->error;

    $self->log->debug("Output from template:\n" . $output);

    #TODO: detect the class name from output, and save to it
    my ($outfile) = ($output =~ m/package (\S+)(?:\s*;|\s*\{)/);

    die "Didn't find package name" if (not defined $outfile or $outfile eq '');

    $self->log->info("Detected package $outfile in output");

    $outfile =~ s/\:\:/\//g;
    $outfile .= '.pm';

    $self->log->info("Naming it $outfile");
    my $f = file($self->output_dir, $outfile);

    $f->parent->mkpath;

    $f->spew($output);
  }

  sub path_parts {
    my ($self, $path) = @_;
    my @parts = split /\//, $path;
    KubeBuilder::Error->throw("Cannot resolve a path doesn't start with #: $path") if ($parts[0] ne '#');
    return ($parts[1], $parts[2]);
  }

  sub object_for_ref {
    my ($self, $ref) = @_;

    $self->log->debug("Object for ref: $ref " . $ref->ref);
    my $path = $self->resolve_path($ref->ref);
    my $objects = $self->objects;
    my $final_path = $path->path;

    my ($first, $second) = $self->path_parts($path->path);
    KubeBuilder::Error->throw("Can't process $final_path in objects because path is not a definitions path") if ($first ne 'definitions');

    my $object = $path->schema->objects->{ $second };
    KubeBuilder::Error->throw("Can't find $final_path in objects") if (not defined $object);
    return $object;
  }

  sub resolve_path {
    my ($self, $path) = @_;

    $self->log->debug("Resolving $path");

    my $final_path = $path;
    my $final_schema = $self;

    my ($first, $second) = $self->path_parts($final_path);
    my $object = $final_schema->schema->$first->{ $second };

    KubeBuilder::Error->throw("Cannot resolve path $path in " . $final_schema->schema_file) if (not defined $object);

    return KubeBuilder::Path->new(
      object => $object,
      schema => $final_schema,
      path => $final_path,
    );
  }

1;
