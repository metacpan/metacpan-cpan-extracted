package ExtUtils::XSBuilder::ParseSource;

use strict;
use vars qw{$VERSION $verbose} ;

use Config ();
use Data::Dumper ;
use Carp;
use Parse::RecDescent;
use File::Path qw(mkpath);

use ExtUtils::XSBuilder::C::grammar  ;

$VERSION = '0.03';

$verbose = 1 ;


=pod

=head1 NAME

ExtUtils::XSBuilder::ParseSource - parse C source files

=head2 DESCRIPTION

For more information, see L<ExtUtils::XSBuilder>

=cut

# ============================================================================

sub new {
    my $class = shift;

    my $self = bless {
        @_,
    }, $class;


    $self;
}

# ============================================================================

=pod

=head2 extent_parser (o)

Allows the user to call the Extent or Replace method of the parser to add 
new syntax rules. This is mainly useful to include expansions for 
preprocessor macros.

=cut

sub extent_parser {
}

# ============================================================================
=pod

=head2 preprocess (o)

Allows the user to preprocess the source before it is given to the parser.
You may modify the source, which is given as first argument in place.

=cut

sub preprocess {
}


# ============================================================================

sub parse {
    my $self = shift;

    $self -> find_includes ;
    my $c = $self -> {c} = {} ;
    
    print "Initialize parser\n" if ($verbose) ;
    my $grammar = ExtUtils::XSBuilder::C::grammar::grammar() or croak "Can't find C grammar\n";
    
    $::RD_HINT++;
    
    my $parser = $self -> {parser} = Parse::RecDescent->new($grammar);

    $parser -> {data} = $c ;
    $parser -> {srcobj} = $self ;

    $self -> extent_parser ($parser) ;

    foreach my $inc (@{$self->{includes}})
        {
        print "scan $inc ...\n" if ($verbose) ;
        $self->scan ($inc) ;
        }

}


# ============================================================================

sub scan {

    my ($self, $filename) = @_ ;

    my $txt ;
        {
        local $/ = undef ;
        open FH, $filename or die "Cannot open $filename ($!)" ;
        $txt = <FH> ;
        close FH ;
        }
    local $SIG{__DIE__} = \&Carp::confess;

    $self -> {parser} -> {srcfilename} = $filename ;

    $self -> preprocess ($txt) ;

    return $self -> {parser}->code($txt) or die "Cannot parse $filename" ;

}


# ============================================================================

sub DESTROY {
    my $self = shift;
    unlink $self->{scan_filename}
}


# ============================================================================
=pod

=head2 include_dirs (o)

Returns a reference to the list of directories that should be searched for
include files which contain the functions, structures, etc. to be extracted. 

Default: C<'.'>

=cut

sub include_dirs {
    my $self = shift;
    ['.'],
}


# ============================================================================
=pod

=head2 include_paths (o)

Returns a reference to a list of directories that are given as include
directories to the C compiler. This is mainly used to strip these directories
from filenames to convert absolute paths to relative paths.

Default: empty list (C<[]>)

=cut

sub include_paths {
    my $self = shift;
    [],
}


# ============================================================================
=pod

=head2 unwanted_includes (o)

Returns a reference to a list of include files that should not be processed.

Default: empty list (C<[]>)

=cut

sub unwanted_includes { [] }



# ============================================================================
=pod

=head2 sort_includes (o, include_list)

Passed an array ref of include files, it allows the user to define the sort
order, so includes are processed correctly.

Default: return the passed array reference.

=cut

sub sort_includes {
    
    return $_[1] ;
}



# ============================================================================
=pod

=head2 find_includes (o)

Returns a list of include files to be processed. 

Default: search directories given by C<include_dirs> for all files and build a
list of include files. All files starting with a word matched by 
C<unwanted_includes> are not included in the list.

=cut

sub find_includes {
    my $self = shift;

    return $self->{includes} if $self->{includes};

    require File::Find;

    my(@dirs) = $self->include_dirs;

    unless (-d $dirs[0]) {
        die "could not find include directory";
    }

    print "Will search @dirs for include files...\n" if ($verbose) ;

    my @includes;
    my $unwanted = join '|', @{$self -> unwanted_includes} ;

    for my $dir (@dirs) {
        File::Find::finddepth({
                               wanted => sub {
                                   return unless /\.h$/;
                                   return if ($unwanted && (/^($unwanted)/o));
                                   my $dir = $File::Find::dir;
                                   push @includes, "$dir/$_";
                               },
                               follow => $^O ne 'MSWin32',
                              }, $dir);
    }

    return $self->{includes} = $self -> sort_includes (\@includes) ;
}



# ============================================================================
=pod

=head2 handle_define (o)

Passed a hash ref with the definition of a define, may modify it.
Return false to discard it, return true to keep it.

Default: C<1>

=cut

sub handle_define { 1 } ;


# ============================================================================
=pod

=head2 handle_enum (o)

Passed a hash ref with the definition of a enum value, may modify it.
Return false to discard it, return true to keep it.

Default: C<1>

=cut

sub handle_enum { 1 } ;


# ============================================================================
=pod

=head2 handle_struct (o)

Passed a hash ref with the definition of a struct, may modify it.
Return false to discard it, return true to keep it.

Default: C<1>

=cut

sub handle_struct { 1 } ;



# ============================================================================
=pod

=head2 handle_function (o)

Passed a hash ref with the definition of a function, may modify it.
Return false to discard it, return true to keep it.

Default: C<1>

=cut

sub handle_function { 1 } ;



# ============================================================================
=pod

=head2 handle_callback (o)

Passed a hash ref with the definition of a callback, may modify it.
Return false to discard it, return true to keep it.

Default: C<1>

=cut

sub handle_callback { 1 } ;







# ============================================================================


sub get_constants {
    my($self) = @_;

    my $includes = $self->find_includes;
    my(%constants, %seen);
    my $defines_wanted_re   = $self -> defines_wanted_re ;
    my $defines_wanted      = $self -> defines_wanted ;
    my $defines_unwanted    = $self -> defines_unwanted ;
    my $enums_wanted        = $self -> enums_wanted ;
    my $enums_unwanted      = $self -> enums_unwanted ;

    for my $file (@$includes) {
        open my $fh, $file or die "open $file: $!";
        while (<$fh>) {
            if (s/^\#define\s+(\w+)\s+.*/$1/) {
                chomp;
                next if /_H$/;
                next if $seen{$_}++;
                $self->handle_constant(\%constants, $defines_wanted_re, $defines_wanted, $defines_unwanted);
            }
            elsif (m/enum[^\{]+\{/) {
                $self->handle_enum($fh, \%constants, $enums_wanted, $enums_unwanted);
            }
        }
        close $fh;
    }

    return \%constants;
}

# ============================================================================

sub get_constants {
    my $self = shift;

    my $key = 'parsed_constants';
    return $self->{$key} if $self->{$key};

    my $c = $self->{$key} = $self->{c}{constants}  ||= [] ;


    # sort the constants by the 'name' attribute to ensure a
    # consistent output on different systems.
    $self->{$key} = [sort { $a->{name} cmp $b->{name} } @{$self->{$key}}];
}



# ============================================================================

sub get_functions {
    my $self = shift;

    my $key = 'parsed_fdecls';
    return $self->{$key} if $self->{$key};

    my $c = $self->{c}{functions}  ||= [] ;


    # sort the functions by the 'name' attribute to ensure a
    # consistent output on different systems.
    $self->{$key} = [sort { $a->{name} cmp $b->{name} } @$c];
}

# ============================================================================

sub get_structs {
    my $self = shift;

    my $key = 'typedef_structs';
    return $self->{$key} if $self->{$key};

    my $c = $self->{c}{structures}  ||= [] ;

    # sort the structs by the 'type' attribute to ensure a consistent
    # output on different systems.
    
    $self->{$key} = [sort { $a->{type} cmp $b->{type} } @$c];
}

# ============================================================================

sub get_callbacks {
    my $self = shift;

    my $key = 'typedef_callbacks';
    return $self->{$key} if $self->{$key};

    my $c = $self->{c}{callbacks} ||= [] ;

    # sort the callbacks by the 'type' attribute to ensure a consistent
    # output on different systems.
    $self->{$key} = [sort { $a->{type} cmp $b->{type} } @$c];
}

# ============================================================================
=pod

=head2 package (o)

Return package name for tables

Default: C<'MY'>

=cut

sub package { 'MY' }

# ============================================================================
=pod

=head2 targetdir (o)

Return name of target directory where to write tables

Default: C<'./xsbuilder/tables'>

=cut

sub targetdir { './xsbuilder/tables' }



# ============================================================================

sub write_functions_pm {
    my $self = shift;
    my $file = shift || 'FunctionTable.pm';
    my $name = shift || $self -> package . '::FunctionTable';

    $self->write_pm($file, $name, $self->get_functions);
}

# ============================================================================

sub write_structs_pm {
    my $self = shift;
    my $file = shift || 'StructureTable.pm';
    my $name = shift || $self -> package . '::StructureTable';

    $self->write_pm($file, $name, $self->get_structs);
}

# ============================================================================

sub write_constants_pm {
    my $self = shift;
    my $file = shift || 'ConstantsTable.pm';
    my $name = shift || $self -> package . '::ConstantsTable';

    $self->write_pm($file, $name, $self->get_constants);
}

# ============================================================================

sub write_callbacks_pm {
    my $self = shift;
    my $file = shift || 'CallbackTable.pm';
    my $name = shift || $self -> package . '::CallbackTable';

    $self->write_pm($file, $name, $self->get_callbacks);
}

# ============================================================================

sub pm_path {
    my($self, $file, $name, $create) = @_;

    my @parts = split '::', ($name || $self -> package . '::X') ;
    my($subdir) = join ('/', @parts[0..$#parts-1]) ;

    my $tdir = $self -> targetdir ;
    if (!-d "$tdir/$subdir") {
        if ($create) {
            mkpath ("$tdir/$subdir", 0, 0755) or die "Cannot create directory $tdir/$subdir ($!)" ;
        }
        else {
            die "Missing directory $tdir/$subdir" ;
            }
    }

    return "$tdir/$subdir/$file";
}

# ============================================================================

sub write_pm {
    my($self, $file, $name, $data) = @_;

    require Data::Dumper;
    local $Data::Dumper::Indent = 1;

    $data ||= [] ;

    $file = $self -> pm_path ($file, $name, 1) ;

    # sort the hashes (including nested ones) for a consistent dump
    canonsort(\$data);

    my $dump = Data::Dumper->new([$data],
                                 [$name])->Dump;

    my $package = ref($self) || $self;
    my $version = $self->VERSION;
    my $date = scalar localtime;

    my $new_content = << "EOF";
package $name;

# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# ! WARNING: generated by $package/$version
# !          $date
# !          do NOT edit, any changes will be lost !
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

$dump

1;
EOF

    my $old_content = '';
    if (-e $file) {
        open PM, "<$file" or die "open $file: $!";
        local $/ = undef; # slurp the file
        $old_content = <PM>;
        close PM;
    }

    my $overwrite = 1;
    if ($old_content) {
        # strip the date line, which will never be the same before
        # comparing
        my $table_header = qr{^\#\s!.*};
        (my $old = $old_content) =~ s/$table_header//mg;
        (my $new = $new_content) =~ s/$table_header//mg;
        $overwrite = 0 if $old eq $new;
    }

    if ($overwrite) {
        open PM, ">$file" or die "open $file: $!";
        print PM $new_content;
        close PM;
    }

}

# ============================================================================
#
# canonsort(\$data);
# sort nested hashes in the data structure.
# the data structure itself gets modified
#

sub canonsort {
    my $ref = shift;
    my $type = ref $$ref;

    return unless $type;

    require Tie::IxHash;

    my $data = $$ref;

    if ($type eq 'ARRAY') {
        for my $d (@$data) {
            canonsort(\$d);
        }
    }
    elsif ($type eq 'HASH') {
        for my $d (keys %$data) {
            canonsort(\$data->{$d});
        }

        tie my %ixhash, 'Tie::IxHash';

        # reverse sort so we get the order of:
        # return_type, name, args { type, name } for functions
        # type, elts { type, name } for structures

        for (sort { $b cmp $a } keys %$data) {
            $ixhash{$_} = $data->{$_};
        }

        $$ref = \%ixhash;
    }
}


# ============================================================================
=pod

=head2 run

Call this class method to parse your source. Before you can do so you must
provide a class that overrides the defaults in
L<ExtUtils::XSBuilder::ParseSource>. After that you scan the source files with

    MyClass -> run ;

=cut

sub run

    {
    my ($class) = @_ ;

    my $p = $class -> new() ;

    $p -> parse ; 

    $p -> write_constants_pm ;

    $p -> write_functions_pm ;

    $p -> write_structs_pm ;

    $p -> write_callbacks_pm ;
    }




1;
__END__
