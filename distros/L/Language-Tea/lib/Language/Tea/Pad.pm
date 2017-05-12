package Language::Tea::Pad;

use strict;
use Carp;

#use Data::Dump::Streamer;

sub new {

    #print __PACKAGE__,"->new [",Dump(\@_),"]\n";
    my $class  = shift;
    my %data   = @_;          # $.outer, @.lexicals, $.namespace
                              # :add_lexicals -- when called from add_lexicals()
    my $parent = $data{outer}
      || bless {
        evaluator => sub {

            package Language::Tea::Pad::Evaluator;
            eval $_[0]
              or do { Carp::carp($@) if $@ };
        },
        variable_names => [],
        namespace      => 'Language::Tea::Pad::Evaluator',
        parent         => undef,
      }, $class;
    my $namespace = $data{namespace}
      || $parent->namespace;

    my @declarations = map { 'my ' . $_ } @{ $data{lexicals} };
    my @names        = map { $_ } @{ $data{lexicals} };

    #print Dump( @names );
    my $cmd = 'package '
      . $namespace . '; '
      . ( $data{add_lexicals} ? '' : 'my $_MODIFIED = {}; ' )
      . ( scalar @names ? join( '; ', @declarations, '' ) : '' )
      . 'sub { '
      . ( join '; ', '$_MODIFIED', @names,
        '' )    # make sure it's compiled as a closure
      . 'eval $_[0] or do{ Carp::carp( $@ ) if $@ }; ' . '} ';

    #print "Pad.new $cmd\n";
    my $pad = bless {
        evaluator      => $parent->eval($cmd),
        variable_names => $data{lexicals},
        namespace      => $namespace,
        parent         => $parent,
    }, $class;

    #print "Pad new $pad - outer $parent\n";
    return $pad;
}

sub eval {

    #print "Pad.eval $_[1]\n";
    $_[0]{evaluator}( $_[1] );
}

sub variable_names { $_[0]{variable_names} }    # XXX  - remove
sub lexicals       { $_[0]{variable_names} }

sub namespace { $_[0]{namespace} }

sub outer { $_[0]{parent} }

sub add_lexicals {                              # [ Decl, Decl, ... ]
    my $self = shift;

    #print "add_lexicals @{$_[0]}\n";

    # look for new lexicals only
    my @new_lexicals;
    for my $new ( @{ $_[0] } ) {
        push @new_lexicals, $new
          unless $self->local_declaration($new);
    }

    #print "add_lexicals: new = @new_lexicals\n";

    my $inner = Language::Tea::Pad->new(
        outer    => $self,
        lexicals => \@new_lexicals,

        # namespace ,
        add_lexicals => 1,
    );
    $self->{evaluator} = $inner->{evaluator};
    $self->{variable_names} = [ @{ $self->{variable_names} }, @new_lexicals, ];

    #print "add_lexicals: $self = @{$self->{variable_names}}\n";
    $self;
}

# look up for a variable's declaration
sub declaration {    # Var
    my ( $self, $var ) = @_;

    #print "Variables: @{$self->{variable_names}} \n";
    return $var
      if $self->local_declaration($var);
    if ( $self->{parent} ) {

        #print "Parent:\n";
        return $self->{parent}->declaration($var);
    }
    else {
        return undef;
    }
}

sub local_declaration {    # Var
    my ( $self, $var ) = @_;

    #print "Variables: @{$self->{variable_names}} \n";
    for my $decl ( @{ $self->{variable_names} } ) {
        return $decl
          if ( $decl eq $var );
    }
    return undef;
}

our %Names;

sub add_type {
    my $Env  = shift;
    my $type = pop || 'TeaUnknownType';
    my $name = join( '_', @_ );

    my $internal_name = mangle( $_[0] );           # $name );
                                                   #print "get_type ... \n";
    my $old_type      = get_type( $Env, $name );
    my $new_type      = $type;

    #print "Old type: $old_type ; New type: $new_type \n";
    if (
        defined $old_type

        # && $old_type ne ''
        && $old_type ne $new_type
      )
    {

        #die "Type Redefinition";

        # use a global registry; only the first version is not numbered

        $Names{$internal_name}++;
        $internal_name .= '_' . $Names{$internal_name} . '_'
          unless $Names{$internal_name} < 2;
    }

#print "create $internal_name   " .  '$' . mangle( $name ) . "_TYPE_ = '"  . "\n";

    $Env->add_lexicals(
        [ '$' . mangle($name) . "_TYPE_", '$' . mangle($name) . "_NAME_", ] );
    my $cmd = '$'
      . mangle($name)
      . "_TYPE_ = '"
      . mangle($type) . "'; " . '$'
      . mangle($name)
      . "_NAME_ = '"
      . $internal_name . "'; ";

    #print "Env add_type: $cmd\n";
    $Env->eval($cmd);

    #print "--\n";
}

sub get_type {
    my $Env  = shift;
    my $name = join( '_', @_ );
    my $cmd  = '$' . mangle($name) . "_TYPE_";

    #print "get_type: $cmd\n";
    my $type;
    local $@;
    if ( $Env->declaration($cmd) ) {

        #print "Env: $cmd\n";
        $type = $Env->eval($cmd);

        #print "Type = ", $type, "\n";
    }
    else {
        $cmd = '$' . mangle( $_[0] ) . "_TYPE_";    # look for a default type
                                                    #print "Env(2): $cmd\n";
        $type = $Env->eval($cmd) if $Env->declaration($cmd);

        #print "Type = ", $type, "\n";
    }
    $type = undef if $@;
    return $type;
}

sub get_name {
    my $Env  = shift;
    my $name = shift;                               # join( '_', @_ );
    my $cmd  = '$' . mangle($name) . "_NAME_";
    my $type;
    local $@;
    if ( $Env->declaration($cmd) ) {

        #print "Env: $cmd\n";
        $type = $Env->eval($cmd);

        #print "Name = ", $type, "\n";
    }
    return $type if defined $type;
    return mangle($name);                           # make a default name
}

sub mangle {
    my $s = shift;
    Carp::confess unless defined $s;
    $s =~ s/ ([^a-zA-Z0-9_]) / '_'.ord($1).'_' /xge;
    return $s;
}

1;

