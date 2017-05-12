package JavaScript::Ectype;
use strict;
use warnings;
our $VERSION = q{0.01};

use JSON;
use File::Slurp;
use File::Spec;
use UNIVERSAL::require;
use Carp qw/croak carp/;
use Scalar::Util qw/blessed/;

use base qw/
    Class::Accessor::Fast
/;

sub _minify_javascript;
BEGIN{
    if( JavaScript::Minifier::XS->require ){
        *_minify_javascript = \&JavaScript::Minifier::XS::minify;
    }elsif( JavaScript::Minifier->require ){
        *_minify_javascript = sub{
            JavaScript::Minifier::minify( input => $_[0] );
        };
    }else{
        *_minify_javascript = sub{$_[0]};
    }
}

use constant FORMAT_SCOPE_WITH_NS => q|
/* %s is loaded */
"%s".namespace().using(function(_namespace_){%s});/*END_OF_SCOPE(%s)*/
|;

use constant FORMAT_SCOPE_WITHOUT_NS => q|
/* %s is loaded */
(function(){
%s
})();/*END_OF_FILE_SCOPE(%s)*/
|;

use constant FORMAT_IMPORT_HEADER 
    => q|"%s".namespace().within(%s,function(%s){|;
    
use constant FORMAT_IMPORT_FOOTER
    => q|});/*END_OF_IMPORT(%s)*/|;
    
use constant FORMAT_IMPORT_AUTO_HEADER
    => q|with("%s".namespace().stash()){|;

use constant FORMAT_IMPORT_AUTO_FOOTER 
    => q|}/*END_OF_IMPORT(%s)*/|;

use constant FORMAT_DEPENDS
    => q|"%s".namespace().depends(%s);|;

use constant FORMAT_DEPENDS_WITHOUT_CHECKER
    => q|"%s".namespace().depends();|;

__PACKAGE__->mk_accessors(qw/
    path
    target
    parent
    package
    minify
    _component
/);

sub new {
    my ($class,%option) = @_;
    return bless { ( _component => {},minify => 1 ), %option }, $class;
}

sub load {
    my ( $proto, %args ) = @_;
    my $self = blessed $proto ? $proto : $proto->new( %args );
    $self->{_converted_data} = $self->convert;
    return $self;
}

sub is_converted {
    my $self = shift;
    return ( $self->{_converted_data} ) ? 1:0;
}
sub converted_data{
    my $self = shift;
    return $self->{_converted_data} ;
}

sub file_path {
    my $self = shift;
    unless ( $self->{file_path} ) {
        croak('target undefined') unless defined $self->target;
        $self->{file_path} = _full_file_path( $self->path, $self->target );
    }
    return $self->{file_path};
}

sub convert {
    my $self = ( blessed $_[0] ) ? shift : shift->new(@_);
    my $file_path = $self->file_path;

    return $self->converted_data if ( $self->is_converted );
    return '' if( $self->_is_loaded_depends_file( $file_path ) );
    
    $self->_push_depends_file( $file_path );

    return '' unless $file_path;

    my $data = eval{ File::Slurp::read_file( $file_path ) };
    if( $@ ){
        croak("$file_path does not exist.");
    }
    my $result =  $self->_execute(
        data    => $data,
        filters => [qw/
            _dispatch_command
            _set_scope
            _set_import
            _set_depends
            _set_require
            _filter_minify
         /]
     );
}

sub _command_require {
    my ( $self,$argument ) = @_;
    $self->_add_component(require => $self->_absolutize_namespace($argument) );
    return '';
}

sub _command_depends {
    my ( $self, $argument ) = @_;
    if ( $argument =~ m/->/ ) {
        my ( $namespace, $text ) = split /\-\>/, $argument;
        $namespace =~ s/\s//g;
        $text      =~ s/\s//g;
        $self->_add_component(
            depends => {
                namespace => $self->_absolutize_namespace($namespace),
                data      => [ split /,/, $text ]
            }
        );
    }
    else {
        $self->_add_component(
            depends => $self->_absolutize_namespace($argument) );
    }
    return '';

}

sub _command_import {
    my ( $self, $argument ) = @_;
    if ( $argument =~ m/->/ ) {
        my ( $namespace, $text ) = split /\-\>/, $argument;
        $namespace =~ s/\s//g;
        $text      =~ s/\s//g;
        $self->_add_component(
            import => {
                namespace => $self->_absolutize_namespace($namespace),
                data      => [
                    map {
                        my ( $from, $to ) = split /:/, $_;
                        ( "$from" => ( $to ? $to : $from ) )
                        } split /,/,
                    $text
                ]
            }
        );
    }
    else {
        $self->_add_component(
            import => $self->_absolutize_namespace($argument) );
    }
    return '';
}

sub _command_package {
    my ( $self,$argument ) = @_;
    carp "package redefined $argument" if defined $self->package;
    $self->package($argument);
    return '';

}

sub _command_include {
    my ( $self, $argument ) = @_;
    my $original = $argument;
    $argument =~ s/\.\//$self->path/e;
    $self->_push_depends_file( $argument );
    return eval {
        File::Slurp::read_file($argument) . qq|/* $original is included */|;
    } || croak("$argument cannot include");
}

sub _absolutize_namespace {
    my ( $self, $fqn ) = @_;
    if ( $fqn =~ m/^\_/ ) {
        if ( defined $self->package ) {
            $fqn =~ s/^_/$self->package/e;
        }
        else {
            carp "package is not defined";
        }
    }
    return $fqn;
}

sub _fqn_to_path{
    my $fqn = shift;
    $fqn =~ s/([A-Z]+)([A-Z][a-z])/$1_$2/g;
    $fqn =~ s/([a-z\d])([A-Z])/$1_$2/g;
    File::Spec->catfile( split /\./, lc($fqn));
}

sub _convert_json{
    my ($perl_value ) = @_;
    return JSON->new->utf8->encode( $perl_value );
}

sub _create_child {
    my ( $self, $target ) = @_;
    my $class = ref $self;
    return $class->convert(
        parent => $self->parent || $self,
        target => $_,
        minify => 0,
        path   => $self->path
    );
}

sub _full_file_path {
    my ( $path, $target ) = @_;
    if ( $target =~ m/\.js$/ ) {
        my $file_path = ( $path || '' ) . $target;
        if ( -e $file_path ) {
            return $file_path;
        }
    }
    else {
        my $file_path = ( $path || '' ) . _fqn_to_path($target);
        if ( -e $file_path . '.ectype.js' ) {
            return $file_path . '.ectype.js';
        }
        return $file_path . '.js';
    }
}

sub _push_depends_file{
    my ( $self,$file_path ) = @_;
    my $parent = $self->parent || $self;
    $parent->_loaded_file_map->{$file_path} = 1;
}

sub _is_loaded_depends_file {
    my ( $self,$file_path ) = @_;
    my $parent = $self->parent || $self;
    return ( $parent->_loaded_file_map->{$file_path} ) ? 1 : 0;
}

sub _loaded_file_map{
    my ($self) = @_;
    unless( $self->{_loaded_file_map} ) {
        $self->{_loaded_file_map} = {};
    }
    return $self->{_loaded_file_map};
}

sub related_files{
    my ( $self, %args ) = @_;
    keys %{ $self->_loaded_file_map };
}

sub _add_component{
    my ( $self,$type,@args ) = @_;

    $self->_component( {} ) unless ( defined $self->_component );
    $self->_component->{$type} ||= [];

    push @{ $self->_component->{$type} }, @args;
}

sub _execute {
    my ( $self, %option ) = @_;
    my $data_ref = \$option{data};

    foreach my $method( @{ $option{filters} } ) {
       $self->$method($data_ref);
    }
    return $$data_ref;
}

sub _set_scope{
    my ($self,$text_ref) = @_;

    return if( $self->package and $self->package eq 'NONE' );

    my $file = $self->file_path;
    my $path = $self->path;

    $file =~ s/$path//;
    if( $self->package){ 
        $$text_ref = sprintf( FORMAT_SCOPE_WITH_NS ,
            $file,
            $self->package,
            $$text_ref,
            $self->package
        );
    }
    else{
        $$text_ref = sprintf( FORMAT_SCOPE_WITHOUT_NS,
            $file,
            $$text_ref,
            $file
        );
    }
}

sub _set_import{
    my($self,$text_ref) = @_;
    my @header = ();
    my @footer = ();
    for ( @{ $self->_component->{import} || [] } ) {
        if ( ref $_ eq 'HASH' ) {
            my $namespace = $_->{namespace};
            my %data      = @{ $_->{data} };
            my @real      = keys %data;
            my @alias     = values %data;
            push @header,
              sprintf(
                FORMAT_IMPORT_HEADER,
                $namespace, _convert_json( \@real ),
                join ',', @alias
              );
            unshift @footer, sprintf(FORMAT_IMPORT_FOOTER,$namespace);
        }
        else {
            push @header, sprintf( FORMAT_IMPORT_AUTO_HEADER, $_ );
            unshift @footer, sprintf(FORMAT_IMPORT_AUTO_FOOTER,$_);
        }
    }
    $$text_ref = join '',(@header,$$text_ref,@footer);
}

sub _set_require{
    my ($self,$text_ref) = @_;
    my $data = join '',map{
        $self->_create_child($_);
    }@{$self->_component->{require}};
    $$text_ref = $data . $$text_ref;
}


sub _set_depends {
    my ($self,$text_ref) = @_;
    my $depends  = join '', map {
        if( ref $_ eq 'HASH' ){
            my $namespace = $_->{namespace};
            my $checker   = _convert_json($_->{data});
            sprintf( FORMAT_DEPENDS , $namespace, $checker );
        }else{
            sprintf( FORMAT_DEPENDS_WITHOUT_CHECKER ,$_ );
        }
    } @{ $self->_component->{depends} || [] };

    $$text_ref = $depends . $$text_ref;
}

sub _filter_minify {
    my ( $self, $text_ref ) = @_;

    $$text_ref = _minify_javascript($$text_ref)
      if ( $self->minify );
}

sub _dispatch_command{
    my $self     = shift;
    my $text_ref = shift;

    $$text_ref =~ s|
        ^                            # top of the line
        (?:                          # top of syntax
            //\=                     # //=
            ([\w_]+)                 # command  = $1
            (?:\s+                   # splitter
                ([\w\->\/\s\,\.\:]+) # argument = $2
            )? 
            (?:[;])              # finished
        )                        # end of syntax
        $                        # end of the line
    |$self->__dispatch_command($1,$2)|xgme;
}

sub __dispatch_command {
    my ( $self,$command,$argument ) = @_;
    my $method    = "_command_$command";
    $self->$method( $argument );
}


1;
__END__
=head1 NAME

JavaScript::Ectype - A JavaScript Preprocessor designed for large scale javascript development

=head1 DESCRIPTION

JavaScript::Ectype Preprocessor can extend some features to javascript code with macro like syntax.
These features are designed for large scale developping with javascript,
concatenating other files ,providing namespace as like as Java or Scala and file-level-scope.

=head1 SYNOPSYS

    use JavaScript::Ectype;
    JavaScript::Ectype->convert(
        target   => $script_name,
        path     => $TEST_PATH,
    );


=head2 convert
get converted javascript code

    use JavaScript::Ectype;
    JavaScript::Ectype->convert(
        target   => $script_name,
        path     => $TEST_PATH,
    );


=head2 new

=head2 file_path

=head2 is_converted

=head2 load

=head2 related_files

=head2 converted_data

=head1 SUPPORT SYNTAX

JavaScript::Ectype interprets "//=foobar" style macros in javascript code.

=head2 auto file scope

JavaScript has no file-level-scope,so every js file is in a flat hierarchy.
A file level scope automatically gives to every output of Ectype Preprocessor.

The code descriving in a js file wrapped like this:

    (function(){
        # your great code
    })();

This makes the code forced well-mannered style, which can reduce unintentional change of global variables.

=head2 declare package;

if your js code has "//=package" macro, 

    //=package full.qualified.name;
    SOME_CODE;

convert like this:

    "full.qualified.name".namespace().using( function(_namespace_) {
        SOME_CODE;
    });

=head2 declare dependency
    
if your js code has "//=depends" macro,

    //=depends full.qualified.name;

convert like this:

    "full.qualified.name".namespace().depends();

=head2 load file recursively

if your js code has "//=require" macro,

    //=require full.qualified.name;

load /path/full/qualified/name.js or /path/full/qualified/name.ectype.js at head of your parent js file.

=head2 import from namespace

if your js code has "//=import" macro,

    //=package apps.net.secure;
    //=import apps.lang.class;
    //=import apps.net ->XMLHTTPRequest:http,WebSocket:socket,LongPoll:comet;
    //=import apps.crypt ->encrypt,decrypt,hmac;
    SOMECODE;

convert like this:

    with("apps.lang.class".namespace().stash()){
        // all object exported in "apps.lang.class" is available in this scope. 
        "apps.net".namespace().within(["XMLHTTPRequest","WebScoket","LongPoll"],function(http,socket,comet){
            // A,B,C in "ectype.net" namespace is available as a,b,c
            "apps.crypt".namespace().within(["encrypt","decrypt","hmac"],function(encrypt,decrypt,hmac){
                "apps.net.secure".namespace().using(function(_namespace_){
                    SOMECODE;
                });
            });
        });
    }

=head2 //=include full.qualified.name

the file is developed in the place.

    //=package data.base64;
    //=include lib/data/base64.js
    _namespace_.publish(
        encode : base64encode,
        decode : base64decode
    );

converted like this:

    "data.base64".namespace().using(function(_namespace_){
        /* content of lib/data/base64.js */
        function base64encode(){}
        function base64decode(){}
        _namespace_.publish(
            encode : base64encode,
            decode : base64decode
        );
    });


=head1 FILE FORMAT

The code generated through Ectype Preprocessor follows the fixed file format.
So, converted data does not change whereever the macros descrived.

    /* [ REQUIRE SECTION ] */
        /* - load other files recursively,which follow same format.*/
    /* [ DEPENDENCY CHECK SECTION ] */
        /* - throw error if descrived namespace does'nt declared. */
        "package_own.fuga".namespace().depends();
        "package_own.hoge".namespace().depends();
    /* [ IMPORT HEADER SECTION ] */
        "package_own.fuga.package".namespace().within(["Load"],function(Load){
        "package_own.hoge.package".namespace().within(["Ext"],function(Ext){
    /* [ OWN PACKAGE SECTION ] */
        "package_own".namespace().using(function(_namespace_){
            var Test=Class.create({initialize:function(name){this.name=name:}});
            new Test("<TMPL_VAR NAME=text>");
        });
    /* [ IMPORT FOOTER SECTION] */
        });});

=head1 AUTHOR

Daichi Hiroki, C<< <hirokidaichi<AT>gmail.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2009 Daichi Hiroki.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut



