package Language::LispPerl::Evaler;
$Language::LispPerl::Evaler::VERSION = '0.007';
use Moose;

use File::ShareDir;
use File::Spec;
use File::Basename;

use Language::LispPerl::Reader;
use Language::LispPerl::Var;
use Language::LispPerl::Printer;
use Language::LispPerl::BuiltIns;

use Log::Any qw/$log/;

BEGIN{
  # The test compatible File::Share
  eval{ require File::Share; File::Share->import('dist_dir'); };
  if( $@ ){
    # The production only File::ShareDir
    require File::ShareDir;
    File::ShareDir->import('dist_dir');
  }
};


our $namespace_key = "0namespace0";

has 'scopes' => ( is => 'ro', default => sub{
                      return [ { $namespace_key => [] } ]
                  });
has 'loaded_files' => ( is => 'ro', default => sub{ {}; } );

has 'file_stack' => ( is => 'ro',  default => sub{ []; } );
has 'caller' => ( is => 'ro' , default => sub{ []; } );

has 'quotation_scope' => ( is => 'ro', default => 0 );
has 'syntaxquotation_scope' => ( is => 'ro', default => 0 );

has 'exception' => ( is => 'rw' );

# The container for the builtin functions.
has 'builtins' => ( is => 'ro', lazy_build => 1 );

sub _build_builtins{
    my ($self) = @_;
    return Language::LispPerl::BuiltIns->new({ evaler => $self });
}

sub to_hash{
    my ($self) = @_;
    return {
        'scopes' => Language::LispPerl::Printer::to_perl( $self->scopes() ),
        'loaded_files' => Language::LispPerl::Printer::to_perl( $self->loaded_files() ),
        'file_stack' => Language::LispPerl::Printer::to_perl( $self->file_stack() ),
        'caller' => Language::LispPerl::Printer::to_perl( $self->caller() ),
        'quotation_scope' => Language::LispPerl::Printer::to_perl( $self->quotation_scope() ),
        'syntaxquotation_scope' => Language::LispPerl::Printer::to_perl( $self->syntaxquotation_scope() ),
        'exception' => Language::LispPerl::Printer::to_perl( $self->exception() ),
        __class => $self->blessed(),
    };
}

sub from_hash{
    my ($class, $hash) = @_;
    return $class->new({
        map { $_ => Language::LispPerl::Reader::from_perl( $hash->{$_} ) } keys %$hash
    });
}

=head2 new_instance

Returns a new instance of this with the same builtins and everything else reset.

Usage:

 my $other_evaler = $this->new_instance();

=cut

sub new_instance{
    my ($self) = @_;
    return ref($self)->new( { builtins => $self->builtins() } );
}

sub clear_exception{
    my ($self) = @_;
    $self->{exception} = undef;
}

sub push_scope {
    my $self    = shift;
    my $context = shift() || confess("Cannot push untrue context");
    my %c       = %{$context};
    my @ns      = @{ $c{$namespace_key} };
    $c{$namespace_key} = \@ns;
    unshift @{ $self->scopes() }, \%c;
}

sub pop_scope {
    my $self = shift;
    shift @{ $self->scopes() };
}

sub current_scope {
    my $self  = shift;
    my $scope = @{ $self->scopes() }[0];
    return $scope;
}

sub push_caller {
    my $self = shift;
    my $ast  = shift;
    unshift @{ $self->caller() }, $ast;
}

sub pop_caller {
    my $self = shift;
    shift @{ $self->caller() };
}

sub caller_size {
    my $self = shift;
    scalar @{ $self->caller() };
}

=head2 copy_caller

Returns a shallow copy of this caller's stack.

Usage:

 my $caller_stack = $this->copy_caller();

=cut

sub copy_caller{
    my ($self) = @_;
    return [ @{ $self->caller() } ];
}

=head2 copy_current_scope

Take a shallow copy of the current scope that
is adequate for function and macro contexts

=cut

sub copy_current_scope{
    my ($self) = @_;
    # Take a shallow copy of the current_scope
    my %c    = %{ $self->current_scope() };

    # Take a shallow copy of the namespace (keyed by namespace_key)
    my @ns   = @{ $c{$namespace_key} };
    $c{$namespace_key} = \@ns;

    return \%c;
}

sub push_namespace {
    my $self      = shift;
    my $namespace = shift;
    my $scope     = $self->current_scope();
    unshift @{ $scope->{$namespace_key} }, $namespace;
}

sub pop_namespace {
    my $self  = shift;
    my $scope = $self->current_scope();
    shift @{ $scope->{$namespace_key} };
}

sub current_namespace {
    my $self      = shift;
    my $scope     = $self->current_scope();
    my $namespace = @{ $scope->{$namespace_key} }[0];
    return "" if ( !defined $namespace );
    return $namespace;
}

=head2 new_var

From a name and a value, creates a new L<Language::LispPerl::Var> under the
key 'name' in $this->current_scope();

Usage:

 $this->new_var( 'bla' , 1 );

=cut

sub new_var {
    my $self  = shift;
    my $name  = shift;
    my $value = shift;
    my $scope = $self->current_scope();
    $name = $self->current_namespace() . "#" . $name;
    $scope->{$name} = Language::LispPerl::Var->new({ name =>  $name, value => $value });
}

=head2 var

Lookup the L<Language::LispPerl::Var> by name in the current scope or in the current namespace.
Returns undef if no such variable is found.

Usage:

 if( my $var = $this->var( 'blabla' ) ){
   ...
 }

=cut

sub var {
    my $self  = shift;
    my $name  = shift;
    my $scope = $self->current_scope();
    if ( exists $scope->{$name} ) {
        return $scope->{$name};
    }
    elsif ( exists $scope->{ $self->current_namespace() . "#" . $name } ) {
        return $scope->{ $self->current_namespace() . "#" . $name };
    }
    elsif ( exists $scope->{ "#" . $name } ) {
        return $scope->{ "#" . $name };
    }
    return undef;
}

=head2 current_file

Returns the current file on the file_stack or '.' if no such thing
exists.

=cut

sub current_file {
    my $self = shift;
    my $sd   = scalar @{ $self->{file_stack} };
    if ( $sd == 0 ) {
        return ".";
    }
    else {
        return ${ $self->{file_stack} }[ $sd - 1 ];
    }
}

=head2 search_file

Looks up the given file name (fully qualified, with clp extension or not)
in this package's share directory or in @INC.

dies with an error if no file can be found.

Usage:

  $this->search_file('core');

=cut

sub search_file {
    my $self = shift;
    my $file = shift;

    my $dist_dir = dist_dir( 'Language-LispPerl' );
    $log->debug("Using dist dir = $dist_dir");

    foreach my $ext ( '', '.clp' ) {
        if ( -f "$file$ext" ) {
            return "$file$ext";
        }
        elsif ( -f $dist_dir. "/lisp/$file$ext" ) {
          return $dist_dir . "/lisp/$file$ext";
        }
        foreach my $p (@INC) {
          if ( -f "$p/$file$ext" ) {
            return "$p/$file$ext";
          }
        }
    }
    Language::LispPerl::Logger::error( "cannot find " . $file );
}

=head2 load

Reads a file once if it hasn't been read before, for loading
libraries in the global scope.

Usage:

 $this->load(/path/to/file.clp');

=cut

sub load {
    my $self = shift;
    my $file = shift;

    Language::LispPerl::Logger::error(
        "cannot require file " . $file . " in non-global scope" )
      if scalar @{ $self->scopes() } > 1;

    $file = File::Spec->rel2abs( $self->search_file($file) );

    return 1 if exists $self->{loaded_files}->{$file};
    $self->{loaded_files}->{$file} = 1;
    push @{ $self->{file_stack} }, $file;
    my $res = $self->read($file);
    pop @{ $self->{file_stack} };
    return $res;
}

=head2 read

Reads and evaluates in this evaler
all the expressions in the given filename
and returns the last evaluation result.

Usage:

 $this->read('/path/to/file.clp');

=cut

sub read {
    my $self   = shift;
    my $file   = shift;
    my $reader = Language::LispPerl::Reader->new();
    $reader->read_file($file);
    my $res = undef;
    $reader->ast()->each( sub { $res = $self->_eval( $_[0] ) } );
    return $res;
}

our $empty_list = Language::LispPerl::Seq->new({ type => "list" });
our $true       = Language::LispPerl::Atom->new({type =>  "bool", value => "true" });
our $false      = Language::LispPerl::Atom->new({type =>  "bool", value => "false"});
our $nil        = Language::LispPerl::Atom->new({type =>  "nil",  value => "nil"});

sub true{ return $true; }
sub false{ return $false; }
sub nil{ return $nil; }
sub empty_list{ return $empty_list; }

=head2 eval

Evaluates a string and returns the result of the latest expression (or dies
with an error).

Return the nil/nil atom when the given string is empty.

Usage:

 my $res = $this->eval(q|( - 1 1 ) ( + 1 2 )|);
 # $res->value() is 3

=cut

sub eval {
    my ($self, $str) = @_;
    unless( length( defined( $str ) ? $str : '' ) ){
        return $nil;
    }

    my $reader = Language::LispPerl::Reader->new();
    $reader->read_string($str);
    my $res = undef;
    $reader->ast()->each( sub { $res = $self->_eval( $_[0] ) } );
    return $res;
}


=head2 bind

Associate the current L<Language::LispPerl::Atom> or L<Language::LispPerl::Seq>
with the correct Perl/Lisp space values.

=cut

sub bind {
    my $self  = shift;
    my $ast   = shift;
    my $class = $ast->class();
    my $type  = $ast->type();
    my $value = $ast->value();
    if ( $type eq "symbol" and $value eq "true" ) {
        return $true;
    }
    elsif ( $type eq "symbol" and $value eq "false" ) {
        return $false;
    }
    elsif ( $type eq "symbol" and $value eq "nil" ) {
        return $nil;
    }
    elsif ( $type eq "accessor" ) {
        return Language::LispPerl::Atom->new({ type => "accessor", value => $self->bind($value) } );
    }
    elsif ( $type eq "sender" ) {
        return Language::LispPerl::Atom->new({ type => "sender", value => $self->bind($value) });
    }
    elsif ( $type eq "syntaxquotation" or $type eq "quotation" ) {
        $self->{syntaxquotation_scope} += 1 if $type eq "syntaxquotation";
        $self->{quotation_scope}       += 1 if $type eq "quotation";
        my $r = $self->bind($value);
        $self->{syntaxquotation_scope} -= 1 if $type eq "syntaxquotation";
        $self->{quotation_scope}       -= 1 if $type eq "quotation";
        return $r;
    }
    elsif (
        (
                $type eq "symbol" and $self->{syntaxquotation_scope} == 0
            and $self->{quotation_scope} == 0
        )
        or ( $type eq "dequotation" and $self->{syntaxquotation_scope} > 0 )
      )
    {
        $ast->error("dequotation should be in syntax quotation scope")
          if ( $type eq "dequotation" and $self->{syntaxquotation_scope} == 0 );
        my $name = $value;
        if ( $type eq "dequotation" and $value =~ /^@(\S+)$/ ) {
            $name = $1;
        }
        return $ast
          if $self->word_is_reserved( $name );
        my $var = $self->var($name);
        $ast->error("unbound symbol '$name'") if !defined $var;
        return $var->value();
    }
    elsif ( $type eq "symbol"
        and $self->{quotation_scope} > 0 )
    {
        my $q = Language::LispPerl::Atom->new({ type => "quotation", value => $value });
        return $q;
    }
    elsif ( $class eq "Seq" ) {
        return $empty_list if $type eq "list" and $ast->size() == 0;
        my $list = Language::LispPerl::Seq->new({ type => "list" });
        $list->type($type);
        foreach my $i ( @{$value} ) {
            if ( $i->type() eq "dequotation" and $i->value() =~ /^@/ ) {
                my $dl = $self->bind($i);
                $i->error( "~@ should be given a list but got " . $dl->type() )
                  if $dl->type() ne "list";
                foreach my $di ( @{ $dl->value() } ) {
                    $list->append($di);
                }
            }
            else {
                $list->append( $self->bind($i) );
            }
        }
        return $list;
    }
    return $ast;
}

sub _eval {
    my $self  = shift;
    my $ast   = shift;
    my $class = $ast->class();
    my $type  = $ast->type();
    my $value = $ast->value();
    if ( $type eq "list" ) {
        my $size = $ast->size();
        if ( $size == 0 ) {
            return $empty_list;
        }
        my $f      = $self->_eval( $ast->first() );
        my $ftype  = $f->type();
        my $fvalue = $f->value();
        if ( $ftype eq "symbol" ) {
            return $self->builtin( $f, $ast );
        }
        elsif ( $ftype eq "key accessor" ) {
            $ast->error("key accessor expects >= 1 arguments") if $size == 1;
            my $m      = $self->_eval( $ast->second() );
            my $mtype  = $m->type();
            my $mvalue = $m->value();
            $ast->error(
"key accessor expects a map or meta as the first arguments but got "
                  . $mtype )
              if $mtype ne "map" and $mtype ne "meta";
            if ( $size == 2 ) {

                #$ast->error("key " . $fvalue . " does not exist")
                return $nil if !exists $mvalue->{$fvalue};
                return $mvalue->{$fvalue};
            }
            elsif ( $size == 3 ) {
                my $v = $self->_eval( $ast->third() );
                if ( $v->type() eq "nil" ) {
                    delete $mvalue->{$fvalue};
                    return $nil;
                }
                else {
                    $mvalue->{$fvalue} = $v;
                    return $mvalue->{$fvalue};
                }
            }
            else {
                $ast->error("key accessor expects <= 2 arguments");
            }
        }
        elsif ( $ftype eq "index accessor" ) {
            $ast->error("index accessor expects >= 1 arguments") if $size == 1;
            my $v      = $self->_eval( $ast->second() );
            my $vtype  = $v->type();
            my $vvalue = $v->value();
            $ast->error(
"index accessor expects a vector or list or xml as the first arguments but got "
                  . $vtype )
              if $vtype ne "vector"
              and $vtype ne "list"
              and $vtype ne "xml";
            $ast->error("index is bigger than size")
              if $fvalue >= scalar @{$vvalue};
            if ( $size == 2 ) {
                return $vvalue->[$fvalue];
            }
            elsif ( $size == 3 ) {
                $vvalue->[$fvalue] = $self->_eval( $ast->third() );
                return $vvalue->[$fvalue];
            }
            else {
                $ast->error("index accessor expects <= 2 arguments");
            }
        }
        elsif ( $ftype eq "function" ) {
            # Fallback to current scope if the function
            # definition didnt shallow copy its current scope at the time of definition.
            # This is the case when the evaler is persisted and then defrosted.
            my $scope  = defined( $f->context() ) ? $f->context() : $self->copy_current_scope();

            my $fn     = $fvalue;
            my $fargs  = $fn->second();
            my @rargs  = $ast->slice( 1 .. $size - 1 );
            my @rrargs = ();
            foreach my $arg (@rargs) {
                push @rrargs, $self->_eval($arg);
            }
            $self->push_scope($scope);
            $self->push_caller($fn);
            my $rest_args  = undef;
            my $i          = 0;
            my $fargsvalue = $fargs->value();
            my $fargsn     = scalar @{$fargsvalue};
            my $rrargsn    = scalar @rrargs;

            for ( $i = 0 ; $i < $fargsn ; $i++ ) {
                my $name = $fargsvalue->[$i]->value();
                if ( $name eq "&" ) {
                    $i++;
                    $name      = $fargsvalue->[$i]->value();
                    $rest_args = Language::LispPerl::Seq->new({ type => "list" });
                    $self->new_var( $name, $rest_args );
                }
                else {
                    $ast->error("real arguments < formal arguments")
                      if $i >= $rrargsn;
                    $self->new_var( $name, $rrargs[$i] );
                }
            }
            if ( defined $rest_args ) {
                $i -= 2;
                for ( ; $i < $rrargsn ; $i++ ) {
                    $rest_args->append( $rrargs[$i] );
                }
            }
            else {
                $ast->error("real arguments > formal arguments")
                  if $i < $rrargsn;
            }
            my @body = $fn->slice( 2 .. $fn->size() - 1 );
            my $res;
            foreach my $b (@body) {
                $res = $self->_eval($b);
            }
            $self->pop_scope();
            $self->pop_caller();
            return $res;
        }
        elsif ( $ftype eq "perlfunction" ) {
            my $meta = undef;
            $meta = $self->_eval( $ast->second() )
              if defined $ast->second()
              and $ast->second()->type() eq "meta";
            my $perl_func = \&{ $f->value() };
            my @args = $ast->slice( ( defined $meta ? 2 : 1 ) .. $size - 1 );
            return $self->perlfunc_call( $perl_func, $meta, \@args, $ast );
        }
        elsif ( $ftype eq "macro" ) {
            my $scope  = defined( $f->context() ) ? $f->context() : $self->copy_current_scope();
            my $fn    = $fvalue;
            my $fargs = $fn->third();
            my @rargs = $ast->slice( 1 .. $ast->size() - 1 );
            $self->push_scope($scope);
            $self->push_caller($fn);
            my $rest_args  = undef;
            my $i          = 0;
            my $fargsvalue = $fargs->value();
            my $fargsn     = scalar @{$fargsvalue};
            my $rargsn     = scalar @rargs;

            for ( $i = 0 ; $i < $fargsn ; $i++ ) {
                my $name = $fargsvalue->[$i]->value();
                if ( $name eq "&" ) {
                    $i++;
                    $name      = $fargsvalue->[$i]->value();
                    $rest_args = Language::LispPerl::Seq->new({ type => "list" });
                    $self->new_var( $name, $rest_args );
                }
                else {
                    $ast->error("real arguments < formal arguments")
                      if $i >= $rargsn;
                    $self->new_var( $name, $rargs[$i] );
                }
            }
            if ( defined $rest_args ) {
                $i -= 2;
                for ( ; $i < $rargsn ; $i++ ) {
                    $rest_args->append( $rargs[$i] );
                }
            }
            else {
                $ast->error("real arguments > formal arguments")
                  if $i < $rargsn;
            }
            my @body = $fn->slice( 3 .. $fn->size() - 1 );
            my $res;
            foreach my $b (@body) {
                $res = $self->_eval($b);
            }
            $self->pop_scope();
            $self->pop_caller();
            return $self->_eval($res);
          }
        else {
            $ast->error("expect a function or function name or index/key accessor");
        }
    }
    elsif ( $type eq "accessor" ) {
        my $av = $self->_eval($value);
        my $a  = Language::LispPerl::Atom->new({ type => "unknown", value => $av->value() });
        my $at = $av->type();
        if ( $at eq "number" ) {
            $a->type("index accessor");
        }
        elsif ( $at eq "string" or $at eq "keyword" ) {
            $a->type("key accessor");
        }
        else {
            $ast->error(
                "unsupport type " . $at . " for accessor but got " . $at );
        }
        return $a;
    }
    elsif ( $type eq "sender" ) {
        my $sn = $self->_eval($value);
        $ast->error( "sender expects a string or keyword but got " . $type )
          if $sn->type() ne "string"
          and $sn->type() ne "keyword";
        my $s = Language::LispPerl::Atom->new({ type => "symbol", value => $sn->value() });
        return $self->bind($s);
    }
    elsif ( $type eq "symbol" ) {
        return $self->bind($ast);
    }
    elsif ( $type eq "syntaxquotation" ) {
        return $self->bind($ast);
    }
    elsif ( $type eq "quotation" ) {
        return $self->bind($ast);
    }
    elsif ( $class eq "Seq" and $type eq "vector" ) {
        my $v  = Language::LispPerl::Atom->new({ type => "vector" });
        my @vv = ();
        foreach my $i ( @{$value} ) {
            push @vv, $self->_eval($i);
        }
        $v->value( \@vv );
        return $v;
    }
    elsif ( $class eq "Seq" and ( $type eq "map" or $type eq "meta" ) ) {
        my $m  = Language::LispPerl::Atom->new({ type => "map" });
        my %mv = ();
        my $n  = scalar @{$value};
        $ast->error( $type . " should have even number of items" )
          if ( $n % 2 ) != 0;
        for ( my $i = 0 ; $i < $n ; $i += 2 ) {
            my $k = $self->_eval( $value->[$i] );
            $ast->error( $type
                  . " expects keyword or string as key but got "
                  . $k->type() )
              if (  $k->type() ne "keyword"
                and $k->type() ne "string" );
            my $v = $self->_eval( $value->[ $i + 1 ] );
            $mv{ $k->value() } = $v;
        }
        $m->value( \%mv );
        $m->type("meta") if $type eq "meta";
        return $m;
    }
    elsif ( $class eq "Seq" and $type eq "xml" ) {
        my $size = $ast->size();
        $ast->error("xml expects >= 1 arguments") if $size == 0;
        my $first     = $ast->first();
        my $firsttype = $first->type();
        if ( $firsttype ne "symbol" ) {
            $first     = $self->_eval($first);
            $firsttype = $first->type();
        }
        $ast->error(
            "xml expects a symbol or string or keyword as name but got "
              . $firsttype )
          if $firsttype ne "symbol"
          and $firsttype ne "string"
          and $firsttype ne "keyword";
        my @items = ();
        my $xml = Language::LispPerl::Atom->new({ type => "xml", value => \@items });
        $xml->{name} = $first->value();
        my @rest = $ast->slice( 1 .. $size - 1 );
        foreach my $i (@rest) {
            my $iv = $self->_eval($i);
            my $it = $iv->type();
            $ast->error(
                "xml expects string or xml or meta or list as items but got "
                  . $it )
              if $it ne "string"
              and $it ne "xml"
              and $it ne "meta"
              and $it ne "list";
            if ( $it eq "meta" ) {
                $xml->meta_data($iv);
            }
            elsif ( $it eq "list" ) {
                foreach my $i ( @{ $iv->value() } ) {
                    push @items, $i;
                }
            }
            else {
                ;
                push @items, $iv;
            }
        }
        return $xml;
    }
    return $ast;
}

=head2 word_is_reserved

Is the given word reserved?
Usage:

 if( $this->word_is_reserved('bla') ){
   ...
 }

=cut

sub word_is_reserved{
    my ($self, $word ) = @_;
    return $self->builtins()->has_function( $word );
}

sub builtin {
    my ($self, $f , $ast) = @_;

    my $fn = $f->value();

    if( my $function = $self->builtins()->has_function( $fn ) ){
        return $self->builtins()->call_function( $function , $ast , $f );
    }

    confess "Builtin function '$fn' is not implemented";
}

sub perlfunc_call {
    my $self      = shift;
    my $perl_func = shift;
    my $meta      = shift;
    my $rargs     = shift;
    my $ast       = shift;

    my $ret_type  = "scalar";
    my @fargtypes = ();
    if ( defined $meta ) {
        if ( exists $meta->value()->{"return"} ) {
            my $rt = $meta->value()->{"return"};
            $ast->error(
                "return expects a string or keyword but got " . $rt->type() )
              if $rt->type() ne "string"
              and $rt->type() ne "keyword";
            $ret_type = $rt->value();
        }
        if ( exists $meta->value()->{"arguments"} ) {
            my $ats = $meta->value()->{"arguments"};
            $ast->error( "arguments expect a vector but got " . $ats->type() )
              if $ats->type() ne "vector";
            foreach my $arg ( @{ $ats->value() } ) {
                $ast->error(
                    "arguments expect a vector of string or keyword but got "
                      . $arg->type() )
                  if $arg->type() ne "string"
                  and $arg->type() ne "keyword";
                push @fargtypes, $arg->value();
            }
        }
    }
    my @args = ();
    my $i    = 0;
    foreach my $arg ( @{$rargs} ) {
        my $pobj = $self->clj2perl( $self->_eval($arg) );
        if ( $i < scalar @fargtypes ) {
            my $ft = $fargtypes[$i];
            if ( $ft eq "scalar" ) {
                push @args, $pobj;
            }
            elsif ( $ft eq "array" ) {
                push @args, @{$pobj};
            }
            elsif ( $ft eq "hash" ) {
                push @args, %{$pobj};
            }
            elsif ( $ft eq "ref" ) {
                push @args, \$pobj;
            }
            else {
                push @args, $pobj;
            }
        }
        else {
            if ( ref($pobj) eq "ARRAY" ) {
                push @args, @{$pobj};
            }
            elsif ( ref($pobj) eq "HASH" ) {
                push @args, %{$pobj};
            }
            else {
                push @args, $pobj;
            }
        }
        $i++;
    }

    if ( $ret_type eq "scalar" ) {
        my $r = $perl_func->(@args);
        return &wrap_perlobj($r);
    }
    elsif ( $ret_type eq "ref-scalar" ) {
        my $r = $perl_func->(@args);
        return &wrap_perlobj( \$r );
    }
    elsif ( $ret_type eq "array" ) {
        my @r = $perl_func->(@args);
        return &wrap_perlobj(@r);
    }
    elsif ( $ret_type eq "ref-array" ) {
        my @r = $perl_func->(@args);
        return &wrap_perlobj( \@r );
    }
    elsif ( $ret_type eq "hash" ) {
        my %r = $perl_func->(@args);
        return &wrap_perlobj(%r);
    }
    elsif ( $ret_type eq "ref-hash" ) {
        my %r = $perl_func->(@args);
        return &wrap_perlobj( \%r );
    }
    elsif ( $ret_type eq "nil" ) {
        $perl_func->(@args);
        return $nil;
    }
    elsif ( $ret_type eq 'raw' ) {

        # The perl function is expected to return a raw Language::LispPerl::Atom
        return $perl_func->(@args);
    }
    else {
        my $r = \$perl_func->(@args);
        return &wrap_perlobj($r);
    }

}

sub clj2perl {
    my $self  = shift;
    my $ast   = shift;
    my $type  = $ast->type();
    my $value = $ast->value();
    if (   $type eq "string"
        or $type eq "number"
        or $type eq "quotation"
        or $type eq "keyword"
        or $type eq "perlobject" )
    {
        return $value;
    }
    elsif ( $type eq "bool" ) {
        if ( $value eq "true" ) {
            return 1;
        }
        else {
            return 0;
        }
    }
    elsif ( $type eq "nil" ) {
        return undef;
    }
    elsif ( $type eq "list" or $type eq "vector" ) {
        my @r = ();
        foreach my $i ( @{$value} ) {
            push @r, $self->clj2perl($i);
        }
        return \@r;
    }
    elsif ( $type eq "map" ) {
        my %r = ();
        foreach my $k ( keys %{$value} ) {
            $r{$k} = $self->clj2perl( $value->{$k} );
        }
        return \%r;
    }
    elsif ( $type eq "function" ) {
        my $f = sub {
            my @args = @_;
            my $cljf = Language::LispPerl::Seq->new({ type => "list" });
            $cljf->append($ast);
            foreach my $arg (@args) {
                $cljf->append( $self->perl2clj($arg) );
            }
            return $self->clj2perl( $self->_eval($cljf) );
        };
        return $f;
    }
    else {
        $ast->error(
            "unsupported type '" . $type . "' for clj2perl object conversion" );
    }
}

sub wrap_perlobj {
    my $v = shift;
    while ( ref($v) eq "REF" ) {
        $v = ${$v};
    }
    return Language::LispPerl::Atom->new({ type => "perlobject", value => $v });
}

=head2 perl2clj

Turn a native perl Object into a new L<Language::LispPerl::Atom>

Usage:

  my $new_atom = $evaler->perl2clj( .. perl object .. );

=cut

sub perl2clj {
    my ($self, $v) = @_;
    if ( !defined ref($v) or ref($v) eq "" ) {
        return Language::LispPerl::Atom->new({ type =>  "string", value => $v });
    }
    elsif ( ref($v) eq "SCALAR" ) {
        return Language::LispPerl::Atom->new({ type =>  "string", value => ${$v} });
    }
    elsif ( ref($v) eq "HASH" ) {
        my %m = ();
        foreach my $k ( keys %{$v} ) {
            $m{$k} = $self->perl2clj( $v->{$k} );
        }
        return Language::LispPerl::Atom->new({ type => "map", value => \%m });
    }
    elsif ( ref($v) eq "ARRAY" ) {
        my @a = ();
        foreach my $i ( @{$v} ) {
            push @a, $self->perl2clj($i);
        }
        return Language::LispPerl::Atom->new({ type =>  "vector", value => \@a });
    }
    elsif ( ref($v) eq "CODE" ) {
        return Language::LispPerl::Atom->new({ type => "perlfunction", value => $v });
    }
    else {
        return Language::LispPerl::Atom->new({ type =>  "perlobject", value => $v });

        #$ast->error("expect a reference of scalar or hash or array");
    }
}

sub trace_vars {
    my $self = shift;
    print @{ $self->scopes() } . "\n";
    foreach my $vn ( keys %{ $self->current_scope() } ) {
        print
            "$vn\n" # . Language::LispPerl::Printer::to_string(${$self->current_scope()}{$vn}->value()) . "\n";
    }
}

__PACKAGE__->meta->make_immutable();
1;
