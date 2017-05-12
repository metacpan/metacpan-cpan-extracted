package Language::Tea::Environment;

use strict;
use warnings;
use base qw(Language::Tea::Pad);

sub init_env {
    return Pad->new(
        outer     => undef,
        lexicals  => [],
        namespace => 'Main',
    );
}

sub add_type {
    my $Env  = shift;
    my $type = pop;
    my $name = join( '_', @_ );

    my $internal_name = mangle($name);
    my $old_type      = get_type( $Env, $name );
    my $new_type      = $type;

    #print "Old type: $old_type ; New type: $new_type \n";
    if ( defined $old_type
        && $old_type ne $new_type )
    {

        #die "Type Redefinition";
        $internal_name .= '_' . ( 1000 + int( rand(9000) ) ) . '_';
    }

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
}

sub get_type {
    my $Env  = shift;
    my $name = join( '_', @_ );
    my $cmd  = '$' . mangle($name) . "_TYPE_";
    my $type;
    local $@;
    if ( $Env->declaration($cmd) ) {

        #print "Env: $cmd\n";
        $type = $Env->eval($cmd);

        #print "Type = ", $type, "\n";
    }
    else {
        $cmd  = '$' . mangle( $_[0] );    # look for a default type
                                          #print "Env(2): $cmd\n";
        $type = $Env->eval($cmd);

        #print "Type = ", $type, "\n";
    }
    $type = undef if $@;
    return $type;
}

sub get_name {
    my $Env  = shift;
    my $name = join( '_', @_ );
    my $cmd  = '$' . mangle($name) . "_NAME_";
    my $type;
    local $@;
    if ( $Env->declaration($cmd) ) {

        #print "Env: $cmd\n";
        $type = $Env->eval($cmd);

        #print "Name = ", $type, "\n";
    }
    return $type if defined $type;
    return mangle($name);    # make a default name
}

sub mangle {
    my $s = shift;
    Carp::confess unless defined $s;
    $s =~ s/ ([^a-zA-Z0-9_<>]) / '_'.ord($1).'_' /xge;
    return $s;
}

1;
