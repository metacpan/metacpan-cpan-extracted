#line 1
package SQL::Translator;

# ----------------------------------------------------------------------
# Copyright (C) 2002-2009 The SQLFairy Authors
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; version 2.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
# 02111-1307  USA
# -------------------------------------------------------------------

use strict;
use vars qw( $VERSION $DEFAULT_SUB $DEBUG $ERROR );
use base 'Class::Base';

require 5.005;

$VERSION  = '0.11002';
$DEBUG    = 0 unless defined $DEBUG;
$ERROR    = "";

use Carp qw(carp);

use Data::Dumper;
use File::Find;
use File::Spec::Functions qw(catfile);
use File::Basename qw(dirname);
use IO::Dir;
use SQL::Translator::Producer;
use SQL::Translator::Schema;

# ----------------------------------------------------------------------
# The default behavior is to "pass through" values (note that the
# SQL::Translator instance is the first value ($_[0]), and the stuff
# to be parsed is the second value ($_[1])
# ----------------------------------------------------------------------
$DEFAULT_SUB = sub { $_[0]->schema } unless defined $DEFAULT_SUB;

# ----------------------------------------------------------------------
# init([ARGS])
#   The constructor.
#
#   new takes an optional hash of arguments.  These arguments may
#   include a parser, specified with the keys "parser" or "from",
#   and a producer, specified with the keys "producer" or "to".
#
#   The values that can be passed as the parser or producer are
#   given directly to the parser or producer methods, respectively.
#   See the appropriate method description below for details about
#   what each expects/accepts.
# ----------------------------------------------------------------------
sub init {
    my ( $self, $config ) = @_;
    #
    # Set the parser and producer.
    #
    # If a 'parser' or 'from' parameter is passed in, use that as the
    # parser; if a 'producer' or 'to' parameter is passed in, use that
    # as the producer; both default to $DEFAULT_SUB.
    #
    $self->parser  ($config->{'parser'}   || $config->{'from'} || $DEFAULT_SUB);
    $self->producer($config->{'producer'} || $config->{'to'}   || $DEFAULT_SUB);

    #
    # Set up callbacks for formatting of pk,fk,table,package names in producer
    # MOVED TO PRODUCER ARGS
    #
    #$self->format_table_name($config->{'format_table_name'});
    #$self->format_package_name($config->{'format_package_name'});
    #$self->format_fk_name($config->{'format_fk_name'});
    #$self->format_pk_name($config->{'format_pk_name'});

    #
    # Set the parser_args and producer_args
    #
    for my $pargs ( qw[ parser_args producer_args ] ) {
        $self->$pargs( $config->{$pargs} ) if defined $config->{ $pargs };
    }

    #
    # Initialize the filters.
    #
    if ( $config->{filters} && ref $config->{filters} eq "ARRAY" ) {
        $self->filters( @{$config->{filters}} )
        || return $self->error('Error inititializing filters: '.$self->error);
    }

    #
    # Set the data source, if 'filename' or 'file' is provided.
    #
    $config->{'filename'} ||= $config->{'file'} || "";
    $self->filename( $config->{'filename'} ) if $config->{'filename'};

    #
    # Finally, if there is a 'data' parameter, use that in
    # preference to filename and file
    #
    if ( my $data = $config->{'data'} ) {
        $self->data( $data );
    }

    #
    # Set various other options.
    #
    $self->{'debug'} = defined $config->{'debug'} ? $config->{'debug'} : $DEBUG;

    $self->add_drop_table( $config->{'add_drop_table'} );

    $self->no_comments( $config->{'no_comments'} );

    $self->show_warnings( $config->{'show_warnings'} );

    $self->trace( $config->{'trace'} );

    $self->validate( $config->{'validate'} );
    
    $self->quote_table_names( (defined $config->{'quote_table_names'} 
        ? $config->{'quote_table_names'} : 1) );
    $self->quote_field_names( (defined $config->{'quote_field_names'} 
        ? $config->{'quote_field_names'} : 1) );

    return $self;
}

# ----------------------------------------------------------------------
# add_drop_table([$bool])
# ----------------------------------------------------------------------
sub add_drop_table {
    my $self = shift;
    if ( defined (my $arg = shift) ) {
        $self->{'add_drop_table'} = $arg ? 1 : 0;
    }
    return $self->{'add_drop_table'} || 0;
}

# ----------------------------------------------------------------------
# no_comments([$bool])
# ----------------------------------------------------------------------
sub no_comments {
    my $self = shift;
    my $arg  = shift;
    if ( defined $arg ) {
        $self->{'no_comments'} = $arg ? 1 : 0;
    }
    return $self->{'no_comments'} || 0;
}


# ----------------------------------------------------------------------
# quote_table_names([$bool])
# ----------------------------------------------------------------------
sub quote_table_names {
    my $self = shift;
    if ( defined (my $arg = shift) ) {
        $self->{'quote_table_names'} = $arg ? 1 : 0;
    }
    return $self->{'quote_table_names'} || 0;
}

# ----------------------------------------------------------------------
# quote_field_names([$bool])
# ----------------------------------------------------------------------
sub quote_field_names {
    my $self = shift;
    if ( defined (my $arg = shift) ) {
        $self->{'quote_field_names'} = $arg ? 1 : 0;
    }
    return $self->{'quote_field_names'} || 0;
}

# ----------------------------------------------------------------------
# producer([$producer_spec])
#
# Get or set the producer for the current translator.
# ----------------------------------------------------------------------
sub producer {
    shift->_tool({
            name => 'producer',
            path => "SQL::Translator::Producer",
            default_sub => "produce",
    }, @_);
}

# ----------------------------------------------------------------------
# producer_type()
#
# producer_type is an accessor that allows producer subs to get
# information about their origin.  This is poptentially important;
# since all producer subs are called as subroutine references, there is
# no way for a producer to find out which package the sub lives in
# originally, for example.
# ----------------------------------------------------------------------
sub producer_type { $_[0]->{'producer_type'} }

# ----------------------------------------------------------------------
# producer_args([\%args])
#
# Arbitrary name => value pairs of paramters can be passed to a
# producer using this method.
#
# If the first argument passed in is undef, then the hash of arguments
# is cleared; all subsequent elements are added to the hash of name,
# value pairs stored as producer_args.
# ----------------------------------------------------------------------
sub producer_args { shift->_args("producer", @_); }

# ----------------------------------------------------------------------
# parser([$parser_spec])
# ----------------------------------------------------------------------
sub parser {
    shift->_tool({
        name => 'parser',
        path => "SQL::Translator::Parser",
        default_sub => "parse",
    }, @_);
}

sub parser_type { $_[0]->{'parser_type'}; }

sub parser_args { shift->_args("parser", @_); }

# ----------------------------------------------------------------------
# e.g.
#   $sqlt->filters => [
#       sub { },
#       [ "NormalizeNames", field => "lc", tabel => "ucfirst" ],
#       [
#           "DataTypeMap",
#           "TEXT" => "BIGTEXT",
#       ],
#   ],
# ----------------------------------------------------------------------
sub filters {
    my $self = shift;
    my $filters = $self->{filters} ||= [];
    return @$filters unless @_;

    # Set. Convert args to list of [\&code,@args]
    foreach (@_) {
        my ($filt,@args) = ref($_) eq "ARRAY" ? @$_ : $_;
        if ( isa($filt,"CODE") ) {
            push @$filters, [$filt,@args];
            next;
        }
        else {
            $self->debug("Adding $filt filter. Args:".Dumper(\@args)."\n");
            $filt = _load_sub("$filt\::filter", "SQL::Translator::Filter")
            || return $self->error(__PACKAGE__->error);
            push @$filters, [$filt,@args];
        }
    }
    return @$filters;
}

# ----------------------------------------------------------------------
sub show_warnings {
    my $self = shift;
    my $arg  = shift;
    if ( defined $arg ) {
        $self->{'show_warnings'} = $arg ? 1 : 0;
    }
    return $self->{'show_warnings'} || 0;
}


# filename - get or set the filename
sub filename {
    my $self = shift;
    if (@_) {
        my $filename = shift;
        if (-d $filename) {
            my $msg = "Cannot use directory '$filename' as input source";
            return $self->error($msg);
        } elsif (ref($filename) eq 'ARRAY') {
            $self->{'filename'} = $filename;
            $self->debug("Got array of files: ".join(', ',@$filename)."\n");
        } elsif (-f _ && -r _) {
            $self->{'filename'} = $filename;
            $self->debug("Got filename: '$self->{'filename'}'\n");
        } else {
            my $msg = "Cannot use '$filename' as input source: ".
                      "file does not exist or is not readable.";
            return $self->error($msg);
        }
    }

    $self->{'filename'};
}

# ----------------------------------------------------------------------
# data([$data])
#
# if $self->{'data'} is not set, but $self->{'filename'} is, then
# $self->{'filename'} is opened and read, with the results put into
# $self->{'data'}.
# ----------------------------------------------------------------------
sub data {
    my $self = shift;

    # Set $self->{'data'} based on what was passed in.  We will
    # accept a number of things; do our best to get it right.
    if (@_) {
        my $data = shift;
        if (isa($data, "SCALAR")) {
            $self->{'data'} =  $data;
        }
        else {
            if (isa($data, 'ARRAY')) {
                $data = join '', @$data;
            }
            elsif (isa($data, 'GLOB')) {
                seek ($data, 0, 0) if eof ($data);
                local $/;
                $data = <$data>;
            }
            elsif (! ref $data && @_) {
                $data = join '', $data, @_;
            }
            $self->{'data'} = \$data;
        }
    }

    # If we have a filename but no data yet, populate.
    if (not $self->{'data'} and my $filename = $self->filename) {
        $self->debug("Opening '$filename' to get contents.\n");
        local *FH;
        local $/;
        my $data;

        my @files = ref($filename) eq 'ARRAY' ? @$filename : ($filename);

        foreach my $file (@files) {
            unless (open FH, $file) {
                return $self->error("Can't read file '$file': $!");
            }

            $data .= <FH>;

            unless (close FH) {
                return $self->error("Can't close file '$file': $!");
            }
        }

        $self->{'data'} = \$data;
    }

    return $self->{'data'};
}

# ----------------------------------------------------------------------
sub reset {
#
# Deletes the existing Schema object so that future calls to translate
# don't append to the existing.
#
    my $self = shift;
    $self->{'schema'} = undef;
    return 1;
}

# ----------------------------------------------------------------------
sub schema {
#
# Returns the SQL::Translator::Schema object
#
    my $self = shift;

    unless ( defined $self->{'schema'} ) {
        $self->{'schema'} = SQL::Translator::Schema->new(
            translator      => $self,
        );
    }

    return $self->{'schema'};
}

# ----------------------------------------------------------------------
sub trace {
    my $self = shift;
    my $arg  = shift;
    if ( defined $arg ) {
        $self->{'trace'} = $arg ? 1 : 0;
    }
    return $self->{'trace'} || 0;
}

# ----------------------------------------------------------------------
# translate([source], [\%args])
#
# translate does the actual translation.  The main argument is the
# source of the data to be translated, which can be a filename, scalar
# reference, or glob reference.
#
# Alternatively, translate takes optional arguements, which are passed
# to the appropriate places.  Most notable of these arguments are
# parser and producer, which can be used to set the parser and
# producer, respectively.  This is the applications last chance to set
# these.
#
# translate returns a string.
# ----------------------------------------------------------------------
sub translate {
    my $self = shift;
    my ($args, $parser, $parser_type, $producer, $producer_type);
    my ($parser_output, $producer_output, @producer_output);

    # Parse arguments
    if (@_ == 1) {
        # Passed a reference to a hash?
        if (isa($_[0], 'HASH')) {
            # yep, a hashref
            $self->debug("translate: Got a hashref\n");
            $args = $_[0];
        }

        # Passed a GLOB reference, i.e., filehandle
        elsif (isa($_[0], 'GLOB')) {
            $self->debug("translate: Got a GLOB reference\n");
            $self->data($_[0]);
        }

        # Passed a reference to a string containing the data
        elsif (isa($_[0], 'SCALAR')) {
            # passed a ref to a string
            $self->debug("translate: Got a SCALAR reference (string)\n");
            $self->data($_[0]);
        }

        # Not a reference; treat it as a filename
        elsif (! ref $_[0]) {
            # Not a ref, it's a filename
            $self->debug("translate: Got a filename\n");
            $self->filename($_[0]);
        }

        # Passed something else entirely.
        else {
            # We're not impressed.  Take your empty string and leave.
            # return "";

            # Actually, if data, parser, and producer are set, then we
            # can continue.  Too bad, because I like my comment
            # (above)...
            return "" unless ($self->data     &&
                              $self->producer &&
                              $self->parser);
        }
    }
    else {
        # You must pass in a hash, or you get nothing.
        return "" if @_ % 2;
        $args = { @_ };
    }

    # ----------------------------------------------------------------------
    # Can specify the data to be transformed using "filename", "file",
    # "data", or "datasource".
    # ----------------------------------------------------------------------
    if (my $filename = ($args->{'filename'} || $args->{'file'})) {
        $self->filename($filename);
    }

    if (my $data = ($args->{'data'} || $args->{'datasource'})) {
        $self->data($data);
    }

    # ----------------------------------------------------------------
    # Get the data.
    # ----------------------------------------------------------------
    my $data = $self->data;

    # ----------------------------------------------------------------
    # Local reference to the parser subroutine
    # ----------------------------------------------------------------
    if ($parser = ($args->{'parser'} || $args->{'from'})) {
        $self->parser($parser);
    }
    $parser      = $self->parser;
    $parser_type = $self->parser_type;

    # ----------------------------------------------------------------
    # Local reference to the producer subroutine
    # ----------------------------------------------------------------
    if ($producer = ($args->{'producer'} || $args->{'to'})) {
        $self->producer($producer);
    }
    $producer      = $self->producer;
    $producer_type = $self->producer_type;

    # ----------------------------------------------------------------
    # Execute the parser, the filters and then execute the producer.
    # Allowances are made for each piece to die, or fail to compile,
    # since the referenced subroutines could be almost anything.  In
    # the future, each of these might happen in a Safe environment,
    # depending on how paranoid we want to be.
    # ----------------------------------------------------------------

    # Run parser
    unless ( defined $self->{'schema'} ) {
        eval { $parser_output = $parser->($self, $$data) };
        if ($@ || ! $parser_output) {
            my $msg = sprintf "translate: Error with parser '%s': %s",
                $parser_type, ($@) ? $@ : " no results";
            return $self->error($msg);
        }
    }
    $self->debug("Schema =\n", Dumper($self->schema), "\n");

    # Validate the schema if asked to.
    if ($self->validate) {
        my $schema = $self->schema;
        return $self->error('Invalid schema') unless $schema->is_valid;
    }

    # Run filters
    my $filt_num = 0;
    foreach ($self->filters) {
        $filt_num++;
        my ($code,@args) = @$_;
        eval { $code->($self->schema, @args) };
        my $err = $@ || $self->error || 0;
        return $self->error("Error with filter $filt_num : $err") if $err;
    }

    # Run producer
    # Calling wantarray in the eval no work, wrong scope.
    my $wantarray = wantarray ? 1 : 0;
    eval {
        if ($wantarray) {
            @producer_output = $producer->($self);
        } else {
            $producer_output = $producer->($self);
        }
    };
    if ($@ || !( $producer_output || @producer_output)) {
        my $err = $@ || $self->error || "no results";
        my $msg = "translate: Error with producer '$producer_type': $err";
        return $self->error($msg);
    }

    return wantarray ? @producer_output : $producer_output;
}

# ----------------------------------------------------------------------
# list_parsers()
#
# Hacky sort of method to list all available parsers.  This has
# several problems:
#
#   - Only finds things in the SQL::Translator::Parser namespace
#
#   - Only finds things that are located in the same directory
#     as SQL::Translator::Parser.  Yeck.
#
# This method will fail in several very likely cases:
#
#   - Parser modules in different namespaces
#
#   - Parser modules in the SQL::Translator::Parser namespace that
#     have any XS componenets will be installed in
#     arch_lib/SQL/Translator.
#
# ----------------------------------------------------------------------
sub list_parsers {
    return shift->_list("parser");
}

# ----------------------------------------------------------------------
# list_producers()
#
# See notes for list_parsers(), above; all the problems apply to
# list_producers as well.
# ----------------------------------------------------------------------
sub list_producers {
    return shift->_list("producer");
}


# ======================================================================
# Private Methods
# ======================================================================

# ----------------------------------------------------------------------
# _args($type, \%args);
#
# Gets or sets ${type}_args.  Called by parser_args and producer_args.
# ----------------------------------------------------------------------
sub _args {
    my $self = shift;
    my $type = shift;
    $type = "${type}_args" unless $type =~ /_args$/;

    unless (defined $self->{$type} && isa($self->{$type}, 'HASH')) {
        $self->{$type} = { };
    }

    if (@_) {
        # If the first argument is an explicit undef (remember, we
        # don't get here unless there is stuff in @_), then we clear
        # out the producer_args hash.
        if (! defined $_[0]) {
            shift @_;
            %{$self->{$type}} = ();
        }

        my $args = isa($_[0], 'HASH') ? shift : { @_ };
        %{$self->{$type}} = (%{$self->{$type}}, %$args);
    }

    $self->{$type};
}

# ----------------------------------------------------------------------
# Does the get/set work for parser and producer. e.g.
# return $self->_tool({ 
#   name => 'producer', 
#   path => "SQL::Translator::Producer",
#   default_sub => "produce",
# }, @_);
# ----------------------------------------------------------------------
sub _tool {
    my ($self,$args) = (shift, shift);
    my $name = $args->{name};
    return $self->{$name} unless @_; # get accessor

    my $path = $args->{path};
    my $default_sub = $args->{default_sub};
    my $tool = shift;
   
    # passed an anonymous subroutine reference
    if (isa($tool, 'CODE')) {
        $self->{$name} = $tool;
        $self->{"$name\_type"} = "CODE";
        $self->debug("Got $name: code ref\n");
    }

    # Module name was passed directly
    # We try to load the name; if it doesn't load, there's a
    # possibility that it has a function name attached to it,
    # so we give it a go.
    else {
        $tool =~ s/-/::/g if $tool !~ /::/;
        my ($code,$sub);
        ($code,$sub) = _load_sub("$tool\::$default_sub", $path);
        unless ($code) {
            if ( __PACKAGE__->error =~ m/Can't find module/ ) {
                # Mod not found so try sub
                ($code,$sub) = _load_sub("$tool", $path) unless $code;
                die "Can't load $name subroutine '$tool' : ".__PACKAGE__->error
                unless $code;
            }
            else {
                die "Can't load $name '$tool' : ".__PACKAGE__->error;
            }
        }

        # get code reference and assign
        my (undef,$module,undef) = $sub =~ m/((.*)::)?(\w+)$/;
        $self->{$name} = $code;
        $self->{"$name\_type"} = $sub eq "CODE" ? "CODE" : $module;
        $self->debug("Got $name: $sub\n");
    }

    # At this point, $self->{$name} contains a subroutine
    # reference that is ready to run

    # Anything left?  If so, it's args
    my $meth = "$name\_args";
    $self->$meth(@_) if (@_);

    return $self->{$name};
}

# ----------------------------------------------------------------------
# _list($type)
# ----------------------------------------------------------------------
sub _list {
    my $self   = shift;
    my $type   = shift || return ();
    my $uctype = ucfirst lc $type;

    #
    # First find all the directories where SQL::Translator 
    # parsers or producers (the "type") appear to live.
    #
    load("SQL::Translator::$uctype") or return ();
    my $path = catfile "SQL", "Translator", $uctype;
    my @dirs;
    for (@INC) {
        my $dir = catfile $_, $path;
        $self->debug("_list_${type}s searching $dir\n");
        next unless -d $dir;
        push @dirs, $dir;
    }

    #
    # Now use File::File::find to look recursively in those 
    # directories for all the *.pm files, then present them
    # with the slashes turned into dashes.
    #
    my %found;
    find( 
        sub { 
            if ( -f && m/\.pm$/ ) {
                my $mod      =  $_;
                   $mod      =~ s/\.pm$//;
                my $cur_dir  = $File::Find::dir;
                my $base_dir = quotemeta catfile 'SQL', 'Translator', $uctype;

                #
                # See if the current directory is below the base directory.
                #
                if ( $cur_dir =~ m/$base_dir(.*)/ ) {
                    $cur_dir = $1;
                    $cur_dir =~ s!^/!!;  # kill leading slash
                    $cur_dir =~ s!/!-!g; # turn other slashes into dashes
                }
                else {
                    $cur_dir = '';
                }

                $found{ join '-', map { $_ || () } $cur_dir, $mod } = 1;
            }
        },
        @dirs
    );

    return sort { lc $a cmp lc $b } keys %found;
}

# ----------------------------------------------------------------------
# load(MODULE [,PATH[,PATH]...])
#
# Loads a Perl module.  Short circuits if a module is already loaded.
#
# MODULE - is the name of the module to load.
#
# PATH - optional list of 'package paths' to look for the module in. e.g
# If you called load('Super::Foo' => 'My', 'Other') it will
# try to load the mod Super::Foo then My::Super::Foo then Other::Super::Foo.
#
# Returns package name of the module actually loaded or false and sets error.
#
# Note, you can't load a name from the root namespace (ie one without '::' in
# it), therefore a single word name without a path fails.
# ----------------------------------------------------------------------
sub load {
    my $name = shift;
    my @path;
    push @path, "" if $name =~ /::/; # Empty path to check name on its own first
    push @path, @_ if @_;

    foreach (@path) {
        my $module = $_ ? "$_\::$name" : $name;
        my $file = $module; $file =~ s[::][/]g; $file .= ".pm";
        __PACKAGE__->debug("Loading $name as $file\n");
        return $module if $INC{$file}; # Already loaded

        eval { require $file };
        next if $@ =~ /Can't locate $file in \@INC/; 
        eval { $module->import() } unless $@;
        return __PACKAGE__->error("Error loading $name as $module : $@")
        if $@ && $@ !~ /"SQL::Translator::Producer" is not exported/;

        return $module; # Module loaded ok
    }

    return __PACKAGE__->error("Can't find module $name. Path:".join(",",@path));
}

# ----------------------------------------------------------------------
# Load the sub name given (including package), optionally using a base package
# path. Returns code ref and name of sub loaded, including its package.
# (\&code, $sub) = load_sub( 'MySQL::produce', "SQL::Translator::Producer" );
# (\&code, $sub) = load_sub( 'MySQL::produce', @path );
# ----------------------------------------------------------------------
sub _load_sub {
    my ($tool, @path) = @_;

    my (undef,$module,$func_name) = $tool =~ m/((.*)::)?(\w+)$/;
    if ( my $module = load($module => @path) ) {
        my $sub = "$module\::$func_name";
        return wantarray ? ( \&{ $sub }, $sub ) : \&$sub;
    }
    return undef;
}

# ----------------------------------------------------------------------
sub format_table_name {
    return shift->_format_name('_format_table_name', @_);
}

# ----------------------------------------------------------------------
sub format_package_name {
    return shift->_format_name('_format_package_name', @_);
}

# ----------------------------------------------------------------------
sub format_fk_name {
    return shift->_format_name('_format_fk_name', @_);
}

# ----------------------------------------------------------------------
sub format_pk_name {
    return shift->_format_name('_format_pk_name', @_);
}

# ----------------------------------------------------------------------
# The other format_*_name methods rely on this one.  It optionally
# accepts a subroutine ref as the first argument (or uses an identity
# sub if one isn't provided or it doesn't already exist), and applies
# it to the rest of the arguments (if any).
# ----------------------------------------------------------------------
sub _format_name {
    my $self = shift;
    my $field = shift;
    my @args = @_;

    if (ref($args[0]) eq 'CODE') {
        $self->{$field} = shift @args;
    }
    elsif (! exists $self->{$field}) {
        $self->{$field} = sub { return shift };
    }

    return @args ? $self->{$field}->(@args) : $self->{$field};
}

# ----------------------------------------------------------------------
# isa($ref, $type)
#
# Calls UNIVERSAL::isa($ref, $type).  I think UNIVERSAL::isa is ugly,
# but I like function overhead.
# ----------------------------------------------------------------------
sub isa($$) {
    my ($ref, $type) = @_;
    return UNIVERSAL::isa($ref, $type);
}

# ----------------------------------------------------------------------
# version
#
# Returns the $VERSION of the main SQL::Translator package.
# ----------------------------------------------------------------------
sub version {
    my $self = shift;
    return $VERSION;
}

# ----------------------------------------------------------------------
sub validate {
    my ( $self, $arg ) = @_;
    if ( defined $arg ) {
        $self->{'validate'} = $arg ? 1 : 0;
    }
    return $self->{'validate'} || 0;
}

1;

# ----------------------------------------------------------------------
# Who killed the pork chops?
# What price bananas?
# Are you my Angel?
# Allen Ginsberg
# ----------------------------------------------------------------------

