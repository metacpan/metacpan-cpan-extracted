package FabForce::DBDesigner4::DBIC;

use warnings;
use strict;
use Carp;
use File::Spec;
use FabForce::DBDesigner4;

# ABSTRACT: create DBIC scheme for DBDesigner4 xml file

our $VERSION = '0.15';

=head1 SYNOPSIS

    use FabForce::DBDesigner4::DBIC;

    my $foo = FabForce::DBDesigner4::DBIC->new();
    $foo->output_path( $some_path );
    $foo->namespace( 'MyApp::DB' );
    $foo->version_add( 0.01 );
    $foo->create_schema( $xml_document );

=head1 METHODS

=head2 new

creates a new object of FabForce::DBDesigner4::DBIC. You can pass some parameters
to new (all parameters are optional)

  my $foo = FabForce::DBDesigner4::DBIC->new(
    output_path => '/path/to/dir',
    input_file  => '/path/to/dbdesigner.file',
    namespace   => 'MyApp::Database',
    version_add => 0.001,
    schema_name => 'MySchema',
    column_details => 1,
    use_fake_dbic  => 1, # default 0.
  );

C<use_fake_dbic> is helpful when C<DBIx::Class> is not installed on the
machine where you use this module.
  
=cut

sub new {
    my ($class,%args) = @_;
    
    my $self = {};
    bless $self, $class;
    
    $self->output_path( $args{output_path} );
    $self->input_file( $args{input_file} );
    $self->namespace( $args{namespace} );
    $self->schema_name( $args{schema_name} );
    $self->version_add( $args{version_add} );
    $self->column_details( $args{column_details} );

    if ( $args{use_fake_dbic} || !eval{ require DBIx::Class } ) {
        require FabForce::DBDesigner4::DBIC::FakeDBIC;
    }
    
    $self->prefix( 
        'belongs_to'   => '',
        'has_many'     => '',
        'has_one'      => '',
        'many_to_many' => '',
    );
    
    
    return $self;
}

=head2 output_path

sets / gets the output path for the scheme

  $foo->output_path( '/any/directory' );
  print $foo->output_path;

=cut

sub output_path {
    my ($self,$path) = @_;
    
    $self->{output_path} = $path if defined $path;
    return $self->{output_path};
}

=head2 input_file

sets / gets the name of the DBDesigner file (XML format)

  $foo->input_file( 'dbdesigner.xml' );
  print $foo->input_file;

=cut

sub input_file{
    my ($self,$file) = @_;
    
    $self->{_input_file} = $file if defined $file;
    return $self->{_input_file};
}

=head2 column_details

If enabled, the column definitions are more detailed. Default: disabled.

  $foo->column_details( 1 );

Standard (excerpt from Result classes):

  __PACKAGE__->add_columns( qw/
    cert_id
    register_nr
    state
  );

With enabled column details:

  __PACKAGE__->add_columns(
    cert_id => {
      data_type         => 'integer',
      is_nullable       => 0,
      is_auto_increment => 1,
    },
    register_nr => {
      data_type   => 'integer',
      is_nullable => 0,
    },
    state => {
      data_type     => 'varchar',
      size          => 1,
      is_nullable   => 0,
      default_value => 'done',
    },
  );

This is useful when you use L<DBIx::Class::DeploymentHandler> to deploy the columns
correctly.

=cut

sub column_details {
    my ($self,$bool) = @_;
    
    $self->{_column_details} = $bool if defined $bool;
    return $self->{_column_details};
}

=head2 version_add

The files should be versioned (e.g. to deploy the DB via C<DBIx::Class::DeploymentHandler>). On the first run 
the version is set to "0.01". When the schema file already exists, the version is increased by the value
of C<version_add> (default: 0.01)

  $foo->version_add( 0.001 );

=cut

sub version_add{
    my ($self,$inc) = @_;
    
    $self->{_version_add} = $inc if defined $inc;
    return $self->{_version_add};
}

=head2 create_schema

creates all the files that are needed to work with DBIx::Class schema:

The main module that loads all classes and one class per table. If you haven't
specified an input file, the module will croak.

You can specify the input file either with input_file or as an parameter for
create_schema

  $foo->input_file( 'dbdesigner.xml' );
  $foo->create_schema;
  
  # or
  
  $foo->create_schema( 'dbdesigner.xml' );

=cut

sub create_schema{
    my ($self, $inputfile) = @_;
    
    $inputfile ||= $self->input_file;
    
    croak "no input file defined" unless defined $inputfile;
    
    my $output_path = $self->output_path || '.';
    my $namespace   = $self->namespace;
    
    my $fabforce    = $self->dbdesigner;
       $fabforce->parsefile( xml => $inputfile );
    my @tables      = $fabforce->getTables;
    
    
    my @files;
    my %relations;
    
    for my $table ( @tables ){
        my $name = $table->name;
        $self->_add_class( $name );
        my $rels = $table->get_foreign_keys;
        for my $to_table ( keys %$rels ){
            $relations{$to_table}->{to}->{$name}   = $rels->{$to_table};
            $relations{$name}->{from}->{$to_table} = $rels->{$to_table};
        }
    }
    
    my @scheme = $self->_main_template;
    
    for my $table ( @tables ){
        push @files, $self->_class_template( $table, $relations{$table->name} );
    }
    
    push @files, @scheme;
    
    $self->_write_files( @files );
}

=head2 create_scheme

C<create_scheme> is an alias for C<create_schema> for compatibility reasons

=cut

sub create_scheme {
    &create_schema;
}

=head2 schema_name 

sets a new name for the schema. By default on of these names is used:

  DBIC_Scheme Database DBIC MyScheme MyDatabase DBIxClass_Scheme

  $dbic->schema_name( 'MyNewSchema' );

=cut

sub schema_name {
    my ($self,$name) = @_;
    
    if( @_ == 2 ){
        $name =~ s![^A-Za-z0-9_]!!g if defined $name;
        $self->_schema( $name );
    }
}

=head2 namespace

sets / gets the name of the namespace. If you set the namespace to 'Test' and you
have a table named 'MyTable', the main module is named 'Test::DBIC_Scheme' and
the class for 'MyTable' is named 'Test::DBIC_Scheme::MyTable'

  $foo->namespace( 'MyApp::DB' );

=cut

sub namespace{
    my ($self,$namespace) = @_;
    
    $self->{namespace} = '' unless defined $self->{namespace};
    
    #print "yes: $namespace\n" if defined $namespace and $namespace =~ /^[A-Z]\w*(::\w+)*$/;
    
    if( defined $namespace and $namespace !~ /^[A-Z]\w*(::\w+)*$/  ){
        croak "no valid namespace given";
    }
    elsif( defined $namespace ){
        $self->{namespace} = $namespace;
    }

    return $self->{namespace};
}

=head2 prefix

In relationships the accessor for the objects of the "other" table shouldn't have the name of the column. 
Otherwise it is very clumsy to get the orginial value of this table.

  $foo->prefix( 'belongs_to' => 'fk_' );
  $foo->prefix( 'has_many' => 'has_' );

creates (col1 is the column name of the foreign key)

  __PACKAGE__->belongs_to( 'fk_col1' => 'OtherTable', {'foreign.col1' => 'self.col1' } );

=cut

sub prefix{
    if( @_ == 2 ){
        my ($self,$key) = @_;
        return $self->{prefixes}->{$key};
    }

    if( @_ > 1 and @_ % 2 != 0 ){
        my ($self,%prefixes) = @_;
        while( my ($key,$val) = each %prefixes ){
            $self->{prefixes}->{$key} = $val;
        }
    }
}

=head2 dbdesigner

returns the C<FabForce::DBDesigner4> object.

=cut

sub dbdesigner {
    my ($self) = @_;
    
    unless( $self->{_dbdesigner} ){
        $self->{_dbdesigner} = FabForce::DBDesigner4->new;
    }
    
    $self->{_dbdesigner};
}

sub _write_files{
    my ($self, %files) = @_;
    
    for my $package ( keys %files ){
        my @path;
        push @path, $self->output_path if $self->output_path;
        push @path, split /::/, $package;
        my $file = pop @path;
        my $dir  = File::Spec->catdir( @path );
        
        $dir = $self->_untaint_path( $dir );
        
        unless( -e $dir ){
            $self->_mkpath( $dir );
        }

        if( open my $fh, '>', $dir . '/' . $file . '.pm' ){
            print $fh $files{$package};
            close $fh;
        }
        else{
            croak "Couldn't create $file.pm";
        }
    }
}

sub _untaint_path{
    my ($self,$path) = @_;
    ($path) = ( $path =~ /(.*)/ );
    # win32 uses ';' for a path separator, assume others use ':'
    my $sep = ($^O =~ /win32/i) ? ';' : ':';
    # -T disallows relative directories in the PATH
    $path = join $sep, grep !/^\./, split /$sep/, $path;
    return $path;
}

sub _mkpath{
    my ($self, $path) = @_;
    
    my @parts = split /[\\\/]/, $path;
    
    for my $i ( 0..$#parts ){
        my $dir = File::Spec->catdir( @parts[ 0..$i ] );
        $dir = $self->_untaint_path( $dir );
        mkdir $dir unless -e $dir;
    }
}

sub _add_class{
    my ($self,$class) = @_;
    
    push @{ $self->{_classes} }, $class if defined $class;
}

sub _get_classes{
    my ($self) = @_;
    
    return @{ $self->{_classes} };
}

sub _version{
    my ($self,$version) = @_;
    
    $self->{_version} = $version if defined $version;
    return $self->{_version};
}

sub _schema{
    my ($self,$name) = @_;
    
    $self->{_scheme} = $name if defined $name;
    return $self->{_scheme};
}

sub _has_many_template{
    my ($self, $to, $arrayref) = @_;
    
    my $package = $self->namespace . '::' . $self->_schema . '::Result::' . $to;
       $package =~ s/^:://;
    my $name    = (split /::/, $package)[-1];
    
    my $string = '';
    for my $arref ( @$arrayref ){
        my ($foreign_field,$field) = @$arref;
        my $temp = $self->prefix( 'has_many' ) . $name;
    
        $string .= qq~
__PACKAGE__->has_many( $temp => '$package',
             { 'foreign.$foreign_field' => 'self.$field' });
~;
    }

    return $string;
}

sub _belongs_to_template{
    my ($self, $from, $arrayref) = @_;
    
    my $package = $self->namespace . '::' . $self->_schema . '::Result::' . $from;
       $package =~ s/^:://;
    my $name    = (split /::/, $package)[-1];
    
    my $string = '';
    for my $arref ( @$arrayref ){
        my ($field,$foreign_field) = @$arref;
        my $temp_field = $self->prefix( 'belongs_to' ) . $name;
    
        $string .= qq~
__PACKAGE__->belongs_to($temp_field => '$package',
             { 'foreign.$foreign_field' => 'self.$field' });
~;
    }

    return $string;
}

sub _class_template{
    my ($self,$table,$relations) = @_;
    
    my $name    = $table->name;
    my $package = $self->namespace . '::' . $self->_schema . '::Result::' . $name;
       $package =~ s/^:://;
    
    my ($has_many, $belongs_to) = ('','');
    
    for my $to_table ( keys %{ $relations->{to} } ){
        $has_many .= $self->_has_many_template( $to_table, $relations->{to}->{$to_table} );
    }

    for my $from_table ( keys %{ $relations->{from} } ){
        $belongs_to .= $self->_belongs_to_template( $from_table, $relations->{from}->{$from_table} );
    }
    
    my @columns = $table->column_names;
    my $column_string = '';

    if ( !$self->column_details ) {
        $column_string = "qw/\n" . join "\n", map{ "    " . $_ }@columns, "    /";
    }
    else {
        my @columns = @{ $table->column_details || [] };

        for my $column ( @columns ) {
            $column->{DefaultValue} =~ s/'/\\'/g;

            if ( $column->{DataType} =~ /char/i && $column->{Width} <= 0 ) {
                $column->{Width} = 255;
            }

            my @options;

            my $name          = $column->{ColName};

            push @options, "data_type => '" . $column->{DataType} . "',";
            push @options, "is_auto_increment => 1,"                             if $column->{AutoInc};
            push @options, "is_nullable => 1,"                                   if !$column->{NotNull};
            push @options, "size => " . $column->{Width} . ","                   if $column->{Width} > 0; 
            push @options, "default_value => '" . $column->{DefaultValue} . "'," if $column->{DefaultValue};

            my $option_string = join "\n        ", @options;

            $column_string .= <<"            COLUMN";
    $name => {
        $option_string
    },
            COLUMN
        }
    }

    my $primary_key   = join " ", $table->key;
    my $version       = $self->_version;
    
    my $template = qq~package $package;
    
use strict;
use warnings;
use base qw(DBIx::Class);

our \$VERSION = $version;

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( '$name' );
__PACKAGE__->add_columns(
$column_string
);
__PACKAGE__->set_primary_key( qw/ $primary_key / );

$has_many
$belongs_to

1;~;

    return $package, $template;
}

sub _main_template{
    my ($self) = @_;
    
    my @class_names  = $self->_get_classes;
    my $classes      = join "\n", map{ "    " . $_ }@class_names;
    
    my $schema_name  = $self->_schema;
    my @schema_names = qw(DBIC_Schema Database DBIC MySchema MyDatabase DBIxClass_Schema);
    
    for my $schema ( @schema_names ){
        last if $schema_name;
        unless( grep{ $_ eq $schema }@class_names ){
            $schema_name = $schema;
            last;
        }
    }

    croak "couldn't determine a package name for the schema" unless $schema_name;
    
    $self->_schema( $schema_name );
    
    my $namespace  = $self->namespace . '::' . $schema_name;
       $namespace  =~ s/^:://;

    my $version;
    eval {
        eval "require $namespace";
        $version = $namespace->VERSION()
    };

    if ( $version ) {
        $version += ( $self->version_add || 0.01 );
    }

    $version ||= '0.01';

    $self->_version( $version );
       
    my $template = qq~package $namespace;

use base qw/DBIx::Class::Schema/;

our \$VERSION = $version;

__PACKAGE__->load_namespaces;

1;~;

    return $namespace, $template;
}

=head1 BUGS

Please report any bugs or feature requests to
C<bug-fabforce-dbdesigner4-dbic at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FabForce::DBDesigner4::DBIC>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FabForce::DBDesigner4::DBIC

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/FabForce::DBDesigner4::DBIC>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/FabForce::DBDesigner4::DBIC>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=FabForce::DBDesigner4::DBIC>

=item * Search CPAN

L<http://search.cpan.org/dist/FabForce::DBDesigner4::DBIC>

=back

=head1 ACKNOWLEDGEMENTS

=cut

1; # End of FabForce::DBDesigner4::DBIC
