package File::Collector ;
$File::Collector::VERSION = '0.038';
use strict; use warnings;

use Carp;
use File::Spec;
use File::Basename;
use Role::Tiny::With;

# public methods

sub AUTOLOAD {
  our $AUTOLOAD;
  my $s = shift;
  $AUTOLOAD  =~ /.*::(next_|isa_|get_)*(\w+)_files*$/ or
    croak "No such method: $AUTOLOAD";

  if (!$s->{_files}{"$2_files"}) { $s->_scroak("No such file category exists: '$2' at "); }
  else { return $s->{_files}{"$2_files"} if !$1; }

  if ($1 eq 'next_') {
    return $s->{_files}{"$2_files"}->next;
  }

  if ($1 eq 'isa_') {
    return $s->{_files}{"$2_files"}->_isa($s->selected);
  }

  # must be a "get" method
  my $cat   = $2;
  my $class = $s->{_processor_map}{$cat};
  my $obj   = $class->new($s->{_files}{all},
            \($s->{selected}),
            $s->{_files}{"${cat}_files"}{_files});
  return $obj;
}

sub new {
  my $class = shift;

  # process args
  my ($user_opts, $classes, @resources) = _get_args(@_);

  # get options hash
  my $default_opts = { recurse => 1 };
  my %opts = (%$default_opts, %$user_opts);

  # construct object
  my $s = bless {
    _files          => { all => {} },
    _common_dir     => '',
    selected        => '',
    _options        => \%opts,
    _classes        => $classes,
    all             => undef,
  }, $class;

  # eval class code
  foreach my $class ( @$classes ) {
    eval "require $class";
    die "Could not load class: $class, $@" if $@;
  }

  # a bit of trickery to make Processor class code consistent with base class
  $s->{all} = $s->{_files}{all};

  # add rersources and process files
  $s->add_resources(@resources);

  return $s;
}

sub add_resources {
  my ($s, @resources) = @_;

  # collect the files
  foreach my $resource (@resources) {
    $s->_exists($resource);
    $s->_add_file($resource)          if -f $resource;
    $s->_get_file_manifest($resource) if -d $resource;
  }

  $s->_generate_short_names;                    # calculate the short names
  $s->_init_all_processors;
  foreach my $file (@{$s->{_files}{new}}) {
    $s->{selected} = $file;
    $s->_classify_all;
  }
  $s->_run_all;
  undef $s->{selected};
  undef $s->{_files}{new};                 # clear the new_file array
}

sub get_count {
  my $s = shift;
  return (scalar keys %{$s->{_files}{all}})
}

sub get_files {
  my $s = shift;

  my @files = sort keys %{$s->{_files}{all}};
  return @files;
}

sub get_file {
  my ($s, $file) = @_;
  $s->_scroak('No file argument passed to method. Aborting.') if !$file;

  return $s->{_files}{all}{$file};
}

sub list_files_long {
  my $s = shift;

  my @files = $s->get_files;
  print $_ . "\n" for @files;
}

sub list_files {
  my $s = shift;

  my @files = map { $s->{_files}{all}{$_}{short_path} } sort keys %{$s->{_files}{all}};
  print "\nFiles found in '".$s->{_common_dir}."':\n\n";
  print $_ . "\n" for @files;
}

sub DESTROY {
}

# private methods meant for used by subclasses

sub _classify {
  my ($s, @classes) = @_;
  foreach my $type (@classes) {
    my $t = $type . '_files';
    my $file = $s->selected;

    # die if bad args given
    die ("No $type argument sent to _classify method. Aborting.") if !$type;
    die ("No processor called $type exists. Aborting.") if !$s->{_files}{$t};

    $s->{_files}{$t}->_add_file($file, $s->{_files}{all}{$file});
  }
}

sub _add_obj {
  my ($s, $type, $obj) = @_;
  $s->_scroak("Missing args to 'add_obj' method. Aborting.") if (!$obj);

  $s->{_files}{all}{$s->selected}{"${type}_obj"} = $obj;
}

# Methods for iterators

sub get_obj_prop {
  my ($s, $obj, $prop) = @_;

  if (!$prop) {
    $s->_scroak ("Missing arguments to get_obj_prop method");
  }

  my $file         = ref ($s->selected) eq 'HASH'
                     ? $s->selected->{full_path}
                     : $s->selected;
  my $attr         = "_$prop";
  my $o            = $obj . '_obj';
  my $object       = $s->{all}{$file}{$o};
  if (! exists $object->{$attr} ) {
    $s->_scroak ("Non-existent $obj object attribute requested: '_$prop'");
  }
  my $value = $object->{$attr};
  if (ref $value eq 'ARRAY') {
    return @$value;
  } else {
    return $value;
  }
}

sub get_obj {
  my ($s, $obj) = @_;

  if (!$obj) {
    _scroak ("Missing arguments to get_obj method");
  }

  my $file = ref ($s->selected) eq 'HASH'
             ? $s->selected->{full_path}
             : $s->selected;
  my $o    = $obj . '_obj';

  return $s->{all}{$file}{$o};
}

sub set_obj_prop {
  my ($s, $obj, $prop, $val)  = @_;

  if (!$val) {
    $s->_scroak ("Missing arguments to set_obj_prop method");
  }

  my $file = $s->selected;

  my $o      = $obj . '_obj';
  my $object = $s->{all}{$file}{$o};
  my $attr   = "_$prop";
  if (! exists $object->{$attr} ) {
    $s->_scroak ("Non-existent $obj object attribute requested: '$prop'");
  }

  $object->{$attr} = $val;
}

sub get_filename {
  my $s = shift;
  my $file = $s->selected;

  return $s->{all}{$file}{filename};
}

sub obj_meth {
  # Keep these args shifted individually
  my $s    = shift;
  my $obj  = shift;
  my $meth = shift;
  my $file = ref ($s->selected) eq 'HASH'
             ? $s->selected->{full_path}
             : $s->selected;

  if (!$meth) {
    $s->_scroak ("Missing arguments to obj_meth method");
  }

  my $o            = $obj . '_obj';
  $obj             = $s->{all}{$file}{$o};

  if (! $obj->can($meth)) {
    _scroak ("Non-existent method on $obj object: '$meth'");
  }
  return $obj->$meth($s->_short_name, @_);
}

sub selected {
  my $s = shift;
  $s->{selected};
}

sub has_obj {
  my ($s, $type) = @_;

  if (!$type) {
    $s->_scroak ("Missing argument to has method");
  }

  my $to   = "${type}_obj";
  my $file = ref ($s->selected) eq 'HASH'
             ? $s->selected->{full_path}
             : $s->selected;
  return defined $s->{all}{$file}{$to};
}

sub attr_defined {
  my $s = shift;
  my $obj = shift;
  my $attr = shift;

  if (ref $s->selected eq 'HASH') {
    return exists $s->selected->{"${obj}_obj"}->{"_${attr}"};
  } else {
    return exists $s->{_files}{all}{$s->selected}{"${obj}_obj"}->{"_${attr}"};
  }
}

sub print_short_name {
  my $s = shift;

  $s->_scroak ("The 'print_short_name' method does not accept methods") if @_;
  print $s->_short_name . "\n";
}

# private helper methods

sub _short_name {
  my $s    = shift;
  my $file = ref ($s->selected) eq 'HASH'
             ? $s->selected->{full_path}
             : $s->selected;
  $s->{all}{$file}{short_path};
}

sub _exists {
  my $s = shift;
  $s->_scroak("'$_[0]' does not exist, aborting call from: ") if ! -e $_[0];
}

sub _scroak {
  my $s = shift;
  my $msg = shift;
  croak($msg . ' ' . (fileparse((caller(1))[1]))[0] . ', line ' . (caller(1))[2] . "\n");
}

sub _get_file_manifest {
  my ($s, $dir) = @_;

  opendir (my $dh, $dir) or die "Can't opendir $dir: $!";
  my @dirs_and_files = grep { /^[^\.]/ } readdir($dh);

  my @files = grep { -f File::Spec->catfile($dir, $_) } @dirs_and_files;
  $s->_add_file( File::Spec->catfile($dir, $_)) for @files;

  my @dirs  = grep { -d File::Spec->catdir( $dir, $_ ) } @dirs_and_files if $s->{_options}{recurse};
  foreach my $tdir (@dirs) {
    opendir (my $tdh, File::Spec->catdir($dir, $tdir)) || die "Can't opendir $tdir: $!";
    $s->_get_file_manifest(File::Spec->catdir( $dir, $tdir ));
  }
}

sub _run_all {
  my $s = shift;
  my $classes = $s->{_classes};
  foreach my $c ( @$classes ) {
    my $role = Role::Tiny->apply_roles_to_object ($s, $c);
    $role->_run_processes if $role->can('_run_processes');;
  }
}

sub _generate_short_names {
  my $s = shift;

  my @files                         = $s->get_files;
  my $file                          = pop @files;
  my @letters                       = split //, $file;
  my ($new_string, $longest_string) = '';
  foreach my $cfile (@files) {
    my @cletters = split //, $cfile;
    my $lc       = 0;

    foreach my $cletter (@cletters) {
      if (defined $letters[$lc] && $cletters[$lc] eq $letters[$lc]) {
        $new_string   .= $cletters[$lc++];
        next;
      }
      $longest_string = $new_string;
      @letters        = split //, $new_string;
      $new_string     = '';
      last;
    }
  }

  $s->{_common_dir} = $longest_string || (fileparse($file))[1];

  if (@files) {
    foreach my $file ( @files, $file ) {
      my $tfile = $file;
      $tfile =~ s/\Q$longest_string\E//;
      $s->{_files}{all}{$file}{short_path} = $tfile;
    }
  } else {
    $s->{_files}{all}{$file}{short_path} = $file;
  }
}

sub _add_file {
  my ($s, $file) = @_;

  $file                                 = File::Spec->rel2abs( $file );
  $s->{_files}{all}{$file}{full_path}   = $file;
  my $filename                          = (fileparse($file))[0];
  $s->{_files}{all}{$file}{filename}    = $filename;

  push @{$s->{_files}{new}}, $file if !$s->{_files}{$file};
}

sub _init_all_processors {
  my $s = shift;

  foreach my $c ( @{ $s->{_classes} } ) {
    my @processors = $c->_init_processors if $c->can('_init_processors');
    my $it_class = $c . '::Processor';
    foreach my $it ( @processors ) {
      next if ($s->{_files}{"${it}_files"});    # don't overwrite existing processor
      $s->{_processor_map}{$it} = $it_class;
      $s->{_files}{"${it}_files"} = $it_class->new($s->{_files}{all}, \($s->{selected}));
    }
  }
}

sub _classify_all {
  my $s = shift;
  foreach my $c ( @{ $s->{_classes} } ) {
    my $role = Role::Tiny->apply_roles_to_object ($s, $c);
    $role->_classify_file() if $role->can('_classify_file');
  }
}

sub _get_args {
  my $user_opts = {};
  my @resources;
  my $classes;
  foreach my $arg (@_) {
    if (!ref $arg) {
      push @resources, $arg;
    } elsif (ref($arg) eq 'HASH') {
      die ('Only one option hash allowed in constructor. Aborting.') if %$user_opts;
      $user_opts = $arg;
    } elsif (ref($arg) eq 'ARRAY') {
      die ('Only one class array allowed in constructor. Aborting.') if $classes;
      $classes = $arg;
    } else {
      die ('Unrecognized argument type passed to constructor');
    }
  }
  die('No list of resources passed to constructor. Aborting.') if ! @resources;
  #die('No Collector class array passed to constructor. Aborting.') if !$classes;

  return ($user_opts, $classes, @resources);
}

1; # Magic true value
# ABSTRACT: Base class for custom File::Collector classes for classifying files and calling File::Collector::Processor methods for processing files

__END__

=pod

=head1 NAME

File::Collector - Base class for custom File::Collector classes for classifying files and calling File::Collector::Processor methods for processing files

=head1 VERSION

version 0.038

=head1 OVERVIEW

C<File::Collector> and its companion module L<File::Collector::Processor> are
base classes designed to make it easier to create custom modules for classifying
and processing a collection of files as well as generating and processing data
related to files in the collection.

For example, let's say you need to import raw files from one directory into some
kind of repository. Let's say that files in the directory need to be filtered
and the content of the files needs to be parsed, validated, rendered and/or
changed before getting imported. Complicating things further, let's say that the
name and location of the file in the target repository is dependent upon the
content of the files in some way and that you also have to check to make sure
the file hasn't already been imported into the repository.

This kind of task can be acomplished with a series of one-off scripts that
process and import your files in stages. Each script produces output suitable
for the next one. But running separate scripts for each processing stage can
be slow, tedious, error-prone and a headache to maintain and organize.

The C<File::Collector> and L<File::Collector::Processor> base modules make it
trivial to chain file processing modules into one logical package to make
complicated file processing more robust, testable, and simpler to code.

=head1 SYNOPSIS

There are three steps to using C<File::Collector>. First, create at least one
C<Collector> class for classifying and filtering files. Next, create a
C<Processor> class your C<Collector> class will use to process the classified
files. Finally, write a script to construct a new C<File::Collector> object to
collect and process your files.

B<Step 1: Create the C<Collector> classes>

  package File::Collector::YourCollector;
  use strict; use warnings;

  # You Collector must use Role::Tiny or you will get an error
  use Role::Tiny

  # Here we add in the package containing the processing methods associated
  # with the Collector (see below).
  use File::Collector::YourCollector::Processor;

  # Objects can store information about the files in the collection which
  # can be accessed by other Collector and Processor classes.
  use SomeObject;

  # Add categories for file collections with the _init_processors method. These
  # categories are used as labels for Processor objects which contain
  # information about the files and can run methods on them. In the example
  # below, we add two file collection categories, "good" and "bad."
  sub _init_processors {
    return qw ( good bad );
  }

  # Next we add a _classify_file method that is called once for each file added
  # to our Collector object. The primary job of this method is to add files and
  # any associated objects to a Processor for further processing.
  sub _classify_file {
    my $s = shift;

    # First, we create an object and associate it with our file using the
    # _add_obj method. There is no requirement that you create objects but they
    # will make data about your file easily available to other classes.
    # Offloading as much logic as possible to objects will keep classes simple.

    # Note how we pass the name of the current file being processed to the
    # object by using the "selected" method which intelligently generates the
    # full path to the file currently being processed by _classify_file. Also
    # note that we don't have to bother passing the name of the file to _add_obj
    # method since this method can figure out which file is being processed by
    # calling the "selected" method as well.
    my $data = SomeObject->new( $s->selected );
    $s->_add_obj('data', $data);

    # Now that we know something about our file, we can classify the files
    # according to any criteria of our choosing.
    # to a processor category
    if ( $data->{has_good_property} ) {
      $s->_classify('good');
    } else {
      $s->_classify('bad');
    }
  }

  # Finally, the _run_processes method contains method calls to your
  # Processor methods.
  sub _run_processes {
    my $s = shift;

    # Below are the methods we can run on the files in our collection. The
    # "good_files" method returns the collection of files classified as "good"
    # and the "do" method is a method that automatically iterates over the
    # files. The "modify" method is one of the methods in our Processor class
    # (see below).
    $s->good_files->do->modify;

    # Run methods on files classified as "bad"
    $s->bad_files->do->fix;
    $s->bad_files->do->modify;

    # You can call methods found in any of the earlier Processor classes in your
    # file processing chain.
    $s->good_files->do->import;
    $s->bad_files->do->import;
  }

B<Step 2: Create your C<Processor> classes.>

  # The Processor class must have the same package name as the Collector class
  # but with "::Processor" tacked on to the end.
  package File::Collector::YourCollector::Processor;

  # This line is required to get access to the methods from the base class.
  use parent 'File::Collector::Processor';

  # This custom method is run once for each file in a collection when we use
  # the "do" method.
  sub modify {
    my $s = shift;

    # Skip the file if it has already been processed.
    next if ($s->attr_defined ( 'data', 'processed' ));

    # Properties of objects added by Collector classes can be easily accessed.
    my @values = $s->get_obj_prop ( 'data', 'header_values' );

    # You can call methods found inside objects, too. Here we run the
    # add_header() method on the data object and pass on values to it.
    $s->obj_meth ( 'data', 'add_header', \@values );
  }

  # We can add as many additional custom methods as we need.
  sub fix {
    ...
  }

B<Step 3: Construct the Collector>

Once your classes have been created, you can run all of your collectors and
processors simply by constructing a C<Collector> object.

The constructor takes three types of arguments: a list of the files and/or
directories you want to collect; an array of the names of the C<Collector>
classes you wish to use in the order you wish to employ them; and finally, an
option hash, which is optional.

   my $collector = File::Collector::YourClassifier->new(
     # The first arguments are a list of resources to be added
     'my/dir', 'a_file.txt',

     # The next argument is an array of Collector class names listed in the same
     # order you want them to run
     [ 'File::Collector::First', 'File::Collector::YourCollector'],

     # Finally, an optional hash argument for options can be supplied
     { recurse => 0 });

   # The C<$collector> object has some useful methods:
   $collector->get_count;  # returns the total number of files in the collection

   # Convenience methods with a little under-the-hood magic make it painless to
   # iterate over files and run methods on them.
   while ($collector->next_good_file) {
     $collector->print_short_name;
   }

   # Iterators can be easily created from C<Processor> objects:
   my $iterator = $s->get_good_files;
   while ( $iterator->next ) {
     # run C<Processor> methods and do other stuff to "good" files
     $iterator->modify_file;
   }

=head1 DESCRIPTION

=head2 Collector Methods

The methods can be run on C<Collector> objects after they've been constructed.

=head3 new( $dir, $file, ..., [ @custom_collector_classes ], \%opts )

=head3 new( $dir, $file, ..., [ @custom_collector_classes ] )

=head3 new( $dir, $file, ..., )

  my $collector = File::Collector->new( 'my/directory',
                                        [ 'Custom::Classifier' ]
				        { recurse => 0 } );

Creates a C<Collector> object that collects files from the directories and files
in the argument list. Once collected, the files are processed by the
C<@custom_collector_classes> in the order supplied by the array argument. Each
of your C<Collector> classes must C<use Role::Tiny> or you will receive an
error.

An option hash can be supplied to turn directory recursion off by setting
C<recurse> to false.

C<new> returns an object which contains all the files, their processing classes,
and any data you have associated with the files. This object has serveral
methods that can be used to inspect the object.

=head3 add_resources( $dir, $file, ... )

  $collector->add_resources( 'myfile1.txt', '/my/home/dir/files/', ... );

Adds additional file resources to an existing collection and processes them.
This method accepts no option hash and the same one supplied to the new
constructor is used.

=head3 get_count()

  $collector->get_count;

Returns the total number of files in the collection.

=head3 get_files()

  my @all_files = $collector->get_files;

Returns a list of the full path of each file in the collection.

=head3 get_file( $file_path )

  my $file = $collector->get_file( '/full/path/to/file.txt' );

Returns a reference of the data and objects associated with a file.

=head3 list_files_long()

Prints the full path names of each file in the collection, sorted
alphabetically, to STDOUT.

=head3 list_files()

Same as C<list_files_long> but prints the files' paths relative to the top level
directory shared by all the files in the collections.

=head3 next_FILE_CATEGORY_file()

  while ($collector->next_good_file) {
    my $file = $collector->selected;
    ...
  }

Retrieves the first file from the the collection of files indicated by
C<FILE_CATEGORY>. Each subsequent C<next> call iterates over the list of files. Returns
a boolean false when the file is exhausted. Provides an easy way to iterate
over files and perform operations on them.

C<FILE_CATEGORY> must be a valid processor name as supplied by one of the
C<_init_processors> method.

=head3 FILE_CATEGORY_files()

  my $processor = $collector->good_files;

Returns the C<File::Processor> object for the category indicated by C<FILE_CATEGROY>.

=head3 get_FILE_CATEGORY_files()

Similar to C<FILE_CATEGORY_files()> except a shallow clone of the C<File::Processor> object is returned. Useful if you require separate iterators for files in the same category.

C<FILE_CATEGORY> must be a valid processor name as supplied by one of the
C<_init_processors> method.

=head3 isa_FILE_CATEGORY_file()

Returns a boolean value reflecting whether the file being iterated over belongs
to a category.

=head2 Private Methods

The following private methods are used in a child classes of C<File::Collector> you provide. See the L<SYNOPSIS> for examples of these methods in use.

=head3 _init_processors()

  sub _init_processors {
    return qw ( 'category_1', 'category_2' );
  }

Creates new file categories. Internally, this method adds a new Processor
object to the C<Collector> for each category added so that C<Processor> methods
from custom C<Processor> classes can be run on individual categories of files.

=head3 _classify_file()

  sub _classify_file {
    my $s = shift;

    # File classifying and analysis logic goes here
  }

Use this method to classify files and to associate objects with your files
using the methods provided by the C<Collector> class. This method is run once
for each file in the collection.

=head3 _run_processes()

  sub _run_processes {
    my $s = shift;

    # Processor method calls go here
  }

In this method, you should place various calls to C<Processor> methods.

=head3 _classify( $category_name )

This method is typically called from within the C<_classify_file> method. It
adds the file currently getting pocessed to a collection of C<$category_name>
files contained within a C<Processor> object which, in turn, belongs to the
C<Collector> object.  The C<$category_name> must match one of the processor
names provided by the C<_init_processor> methods.

=head3 _add_obj( $object_name, $object )

Like the C<_classify> method, this method is typically called from within the
C<_classify_file> method. It associates the object specified by C<$object> to an
arbitrary name, specified by C<$object_name>, with the file currently getting
processed.

=head2 Iteration Methods

These methods can be used while iterating over a collection of files. See the L<SYNOPSIS> for some examples of these methods in use.

=head3 get_obj_prop( $obj_name, $property_name )

Returns the contents of an object's property.

=head3 get_obj( $obj_name )

Returns an object associated with a file.

=head3 set_obj_prop( $obj_name, $property_name, $value )

Sets an object's property.

=head3 obj_meth( $obj_name, $method_name, $method_args );

Runs the C<$method_name> method on the object specified in C<$obj_name>.
Arguments are passed via C<$method_args>.

=head3 get_filename()

Retrieves the name of file being processed without the path.

=head3 selected()

Returns the full path and file name of the file being processed.

=head3 has_obj( $obj_name );

Returns a boolean value reflecting the existence of the obj in C<$obj_name>.

=head3 attr_defined( $obj_name, $attr_name )

Returns a boolean value reflecting if the atrribute specified by C<$attr_name> is defined in the C<$obj_name> object.

=head3 print_short_name()

Returns a shortened path, relative to all the files in the entire collection,
and the file name of the file being processed or in an iterator.

=head1 REQUIRES

=over 4

=item * L<Carp|Carp>

=item * L<File::Basename|File::Basename>

=item * L<File::Spec|File::Spec>

=item * L<Role::Tiny::With|Role::Tiny::With>

=item * L<strict|strict>

=item * L<warnings|warnings>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc File::Collector

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/File-Collector>

=back

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/sdondley/File-Collector>

  git clone git://github.com/sdondley/File-Collector.git

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/sdondley/File-Collector/issues>.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 SEE ALSO

L<File::Collector::Processor>

=head1 AUTHOR

Steve Dondley <s@dondley.com>

=head1 Special Thanks

Thanks to all the generous monks at the L<PerlMonks|https://PerlMonks.org>
community for patiently answering my (sometimes asinine) questions. A very
special mention goes to L<jcb|https://www.perlmonks.org/?node_id=1149436> whose
advice was invaluable to improving the quality of this module. Another shout out
to L<Hippo|https://www.perlmonks.org/?node=hippo> for the suggesting
L<Role::Tiny> to help make the module more flexible.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Steve Dondley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
