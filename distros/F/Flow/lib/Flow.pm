#===============================================================================
#
#  DESCRIPTION: Flow - Make data flow processing easy
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================

=head1 NAME

Flow - Make data flow processing easy

=head1 SYNOPSIS

    use Flow;
    my $flow = create_flow( Splice=>20, sub{ [ grep { $_ > 1 } @_ ] } )

    my $c1 = new Flow::Code:: {
    flow => sub { my $self = shift; $self->{count_}++ for @_; return},
    end => sub {
          my $self = shift;
          $self->put_flow( $self->{count_} );
          [@_]
    }
    };
    create_flow( $c1, new Flow::To::XML::(\$str) );
    $c1->run(1..1000);

    
=head1 DESCRIPTION

Flow - a set of modules for data flow processing.

=cut

package Flow;
use Flow::Code;
use Flow::Splice;
use Flow::To::XML;
use Flow::To::JXML;
use Flow::From::JXML;
use Flow::From::XML;
use Flow::Join;
use Flow::Split;
use Flow::Grep;
use strict;
use warnings;

#require Exporter;
use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(create_flow);
our $VERSION = '1.01';
use constant MODS_MAP => {
    Splice  => 'Flow::Splice',
    Join    => 'Flow::Join',
    ToXML   => 'Flow::To::XML',
    Code    => 'Flow::Code',
    FromXML => 'Flow::From::XML',
    Split   => 'Flow::Split',
    ToJXML  => 'Flow::To::JXML',
    FromJXML => 'Flow::From::JXML',
    Grep => 'Flow::Grep'
};

our %tmp_map = %{ (MODS_MAP) };

sub define_event {
    __make_methods($_) for @_;
}

sub __make_methods {
    my $method = shift;
    no strict 'refs';
    my $put_method    = "put_${method}";
    my $pivate_method = "_${method}";
    *{ __PACKAGE__ . "::$method" } = sub {
        my $self = shift;
        return $self->$put_method(@_);
    };
    *{ __PACKAGE__ . "::$put_method" } = sub {
        my $self = shift;
        if ( my $h = $self->__handler ) {
            return $h->$pivate_method(@_);
        }

        #clear return results
        return;
    };

    *{ __PACKAGE__ . "::$pivate_method" } = sub {
        my $self = shift;
        my $res  = $self->$method(@_);
        
        #ERROR STATE
        return $res unless ref($res);
        if ( ref($res) eq 'ARRAY' ) {
            return $self->$put_method(@$res);
        }
    };
}

define_event( "begin", "flow", "ctl_flow", "end" );

sub import {
    my ($class) = shift;
    __PACKAGE__->export_to_level( 1, $class, 'create_flow' );
    while ( my ( $alias, $module ) = splice @_, 0, 2 ) {
        if ( defined($alias) && defined($module) ) {
            $tmp_map{$alias} = $module;
        }
    }
}

=head1 FUNCTIONS

=head2 create_flow "MyFlow::Pack"=>{param1=>$val},$my_flow_object, "MyFlow::Pack1"=>12, "MyFlow::Pack3"=>{}

Use last arg as handler for out.

return flow object ref.

    my $h1     = new MyHandler1::;
    my $flow = create_flow( 'MyHandler1', $h1 );
    #also create pipe of flows
    my $filter1 = create_flow( 'MyHandler1'=>{}, 'MyHandler2'=>{} );
    my $h1     = new MyHandler3::;
    my $flow = create_flow(  $filter1, $h1);

=cut

sub create_flow {

    #firest make objects
    my @objects = ();
    while ( $#_ >= 0 ) {
        my $method = shift @_;

        #if object ?
        if ( ref($method) ) {
            if ( ref($method) eq 'CODE' ) {

                #use Flow::Code by default
                $method = new Flow::Code:: $method;
            }
            if ( UNIVERSAL::isa( $method, "Flow" ) ) {
                push @objects, $method;
                next;
            }
            die "bad method $method";
        }
        my $param = shift @_;
        if ( defined $tmp_map{$method} ) {
            $method = $tmp_map{$method};
        }
        push @objects, $method->new($param);
    }
    my @in = reverse map { split_flow($_) } @objects;
    my $next_handler = shift @in;
    foreach my $f (@in) {
        die "$f not isa of Flow::" unless UNIVERSAL::isa( $f, "Flow" );
        $f->set_handler($next_handler);
        $next_handler = $f;
    }
    return $next_handler;
}

=head2 split_flow $flow

Return array of handlers

=cut

sub split_flow {
    my $obj = shift;
    if ( @_ > 1 ) {
        return split_flow($_) for @_;
    }
    my @res = ($obj);
    if ( my $h = $obj->get_handler ) {
        push @res, split_flow($h);
    }
    @res;
}
=head1 METHODS

=cut
sub new {
    my $class = shift;
    $class = ref($class) || $class;
    my $opt = ( $#_ == 0 ) ? shift : {@_};
    my $self = bless( $opt, $class );
    return $self;
}

sub set_handler {
    my $self    = shift;
    my $handler = shift;
    if ( UNIVERSAL::isa( $handler, 'Flow' ) ) {
        $self->__handler($handler);
    }
}

sub get_handler {
    my $self = shift;
    return $self->__handler();
}

sub __handler {
    my $self = shift;
    if (@_) {
        $self->{Handler} = shift @_;
    }
    return $self->{Handler};
}

sub parser {
    my $self = shift;
    my $run_flow = Flow::create_flow( __PACKAGE__->new(), $self );
    return $run_flow;
}

sub run {
    my $self = shift;
    my $p    = $self->parser;
    $p->begin();
    $p->flow(@_);
    $p->end();
}
1;
__END__

=head1 SEE ALSO


=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

