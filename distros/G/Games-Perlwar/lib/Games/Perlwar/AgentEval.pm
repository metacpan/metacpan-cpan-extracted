package Games::Perlwar::AgentEval;

use strict;
use warnings;
our $VERSION = '0.03';

use Class::Std;
use Carp;

use Safe;

my %code_of         : ATTR( :name<code> );
my %vars_of         : ATTR( :name<vars> :default<undef>);
my %success_of      : ATTR;
my %error_msg_of    : ATTR( :set<error> :get<error> );
my %return_value_of : ATTR( :set<return_value> :get<return_value> );
my %safe_of         : ATTR;
my %container_of    : ATTR;

my $container_id = 0;

sub START {
    my ($self, $id ) = @_;

    my $code = $code_of{ $id };
    my %vars = $vars_of{ $id } ? %{ $vars_of{ $id } } : ();

    # what happens in execute(), stays in execute
#    local *STDERR;
#    my $warnings;
#    open STDERR, '>', \$warnings;
    my $warnings = "";

    $container_of{ $id } = 'C'.$container_id++;

#    eval "*Container:: = *$container_of{ $id }::";

	my $safe = Safe->new( $container_of{ $id } );
    $safe_of{ $id } = $safe;
	$safe->permit( qw/ rand time sort :browse :default / );

    eval  '@'.$container_of{ $id }
         .q#::Array = $vars{'@_'} ? @{ $vars{'@_'} } : ( $code );#
        or die;

    delete $vars{'@_'};
    while( my( $k, $v ) = each %vars ) {
        $k =~ s/([\$\@\%])// 
            or croak "'$k' is not a variable name";

        $v = \do{ my $x = $v } if $1 eq '$';
        eval "*$container_of{ $id }::$k = \$v";
        die $@ if $@;

		#@Container::o = @o;
		#@Container::O = $owner;
		#$Container::S = $self->{conf}{snippetMaxLength};
		#$Container::I = $self->{conf}{gameLength};
		#$Container::i = $self->{conf}{currentIteration};
		#$safe->share_from( 'Container', [ '$S', '$I', '$i', '@_', '@o', '$O' ] );
    };
        
    my( $error, $return_value );

    # die after three seconds
    local $SIG{ALRM} = sub { die "agent timed out\n" };
    alarm 3;

    undef $@;
    {
        local *STDERR;
        my $warnings;
        open STDERR, '>', \$warnings;
        $return_value = $safe->reval( 'local *_ = \@Array;'
                                     .'$_ = $_[0];'
                                     .$code                  );
    }
    alarm 0;

    if ( $error = $@ ) {
        $error =~ s/\s* at .*? $//x;
        $self->set_error( $error );
        $self->set_success( 0 );
    }
    else {
        $self->set_return_value( $return_value );
        $self->set_success( 1 );
    }

 
#    die join "\n", keys %::main::Container::;
    
    return !$self->crashed;
}

sub DEMOLISH {
    my ($self, $id ) = @_;  
    
    # let's clean Container::
    my %keyword = map { $_ => 1 } qw/ __ANON__ INC BEGIN main:: /;
    delete @::main::Container::{ grep { !$keyword{$_} }
                                    keys %::main::Container::  };
}

sub set_success {
    my $self = shift;
    my $id = ident $self;
    return $success_of{ $id } = shift;
}

sub crashed {
    return ! $success_of{ ident shift };
}

sub eval {
    my $self = shift;
    return if $self->crashed;

    return $safe_of{ ident $self }->reval( shift );
}

sub error_msg {
    return $error_msg_of{ ident shift };
}

sub return_value {
    my $self = shift;
    my $id = ident $self;
    return $return_value_of{ $id }; 
}

'end of package Games::Perlwar::AgentEval';
