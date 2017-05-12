package Getopt::Flex::Spec::Argument;
BEGIN {
  $Getopt::Flex::Spec::Argument::VERSION = '1.07';
}

# ABSTRACT: Getopt::Flex's way of specifying arguments

use strict; #shut up cpants
use warnings; #shut up cpants
use Carp;
use Moose;
use Moose::Util::TypeConstraints;
use Moose::Meta::TypeConstraint;
use MooseX::StrictConstructor;

#types an argument know how to be
subtype 'ValidType'
            => as 'Str'
            => where { $_ =~ m/^[a-zA-Z]+$|^ArrayRef\[[a-zA-Z]+\]$|^HashRef\[[a-zA-Z]+\]$/ };

#special type for an incremental argument
subtype 'Inc'
            => as 'Int';

#special type defining what a switch spec should look like            
subtype 'SwitchSpec'
            => as 'Str'
            => where { $_ =~ m/^[a-zA-Z0-9|_?-]+$/ && $_ =~ m/^[a-zA-Z_?]/ && $_ !~ m/\|\|/ && $_ !~ /--/ && $_ !~ /-$/ };

#special type defining what a parsed switch should look like          
subtype 'Switch'
            => as 'Str'
            => where { $_ =~ m/^[a-zA-Z0-9_?-]+$/ && $_ =~ m/^[a-zA-Z_?]/ };

#the argument specification supplied
has 'switchspec' => (
    is => 'ro',
    isa => 'SwitchSpec',
    required => 1,
);

#the primary name of this switch
has 'primary_name' => (
    is => 'ro',
    isa => 'Switch',
    writer => '_set_primary_name',
    init_arg => undef,
);

#any aliases this switch has
has 'aliases' => (
    is => 'ro',
    isa => 'ArrayRef[Switch]',
    writer => '_set_aliases',
    init_arg => undef,
);

#the reference to the variable to populate when this switch is found
has 'var' => (
    is => 'ro',
    isa => 'ScalarRef|ArrayRef|HashRef',
    writer => '_set_var',
    predicate => 'has_var',
);

#the type of values to accept for this variable                
has 'type' => (
    is => 'ro',
    isa => 'ValidType',
    required => 1,
	reader => 'get_type',
);

#the description of this variable, for autohelp
has 'desc' => (
    is => 'ro',
    isa => 'Str',
    default => '',
    writer => '_set_desc',
);

#whether or not this switch must be found
has 'required' => (
    is => 'ro',
    isa => 'Int',
    default => 0,
);

#a function to call to validate the value found by this switch
has 'validator' => (
    is => 'ro',
    isa => 'CodeRef',
    predicate => 'has_validator',
);

#a function to call whenever this switch is found, passing in the
#value found, if any
has 'callback' => (
    is => 'ro',
    isa => 'CodeRef',
);

#default to populate the provided variable reference with
has 'default' => (
    is => 'ro',
    isa => 'Str|ArrayRef|HashRef|CodeRef',
    predicate => 'has_default',
    writer => '_set_default',
);

#whether or not this argument has had its variable set                
has '_set' => (
    is => 'rw',
    isa => 'Int',
    init_arg => undef,
    predicate => 'is_set',
);

#for indicating error conditions
has 'error' => (
    is => 'ro',
    isa => 'Str',
    init_arg => undef,
    writer => '_set_error',
);
            

sub BUILD {
    my ($self) = @_;
    
    #check the type supplied
    if(!Moose::Util::TypeConstraints::find_or_parse_type_constraint($self->get_type())) {
        my $type = $self->get_type();
        Carp::confess "Type constraint $type does not exist or cannot be created\n";
    }
    
    #check that the type supplied is a "simple" type or that the parameterizable
    #type supplied has a parameter which is also simple
    my $type = $self->get_type();
    if($type =~ m/^([a-zA-Z]+)\[([a-zA-Z]+)\]$/) {
        $type = $2;
    }
    my $tc = Moose::Util::TypeConstraints::find_or_parse_type_constraint($type);
    if(!$tc->is_a_type_of('Str')
    && !$tc->is_a_type_of('Int')
    && !$tc->is_a_type_of('Num')
    && !$tc->is_a_type_of('Bool')) {
        Carp::confess "Given type (or parameter) $type is not simple, i.e. it must be a subtype of Str, Num, Int, or Bool\n";
    }
    
    if(!$self->has_var()) {
        if($self->get_type() =~ /^ArrayRef/) {
            my @arr = ();
            $self->_set_var(\@arr);
        } elsif($self->get_type() =~ /^HashRef/) {
            my %has = ();
            $self->_set_var(\%has);
        } else {
            my $var;
            $self->_set_var(\$var);
        }
    }
    
    #check supplied reference type
    my $reft = ref($self->var());
    if($reft ne 'ARRAY' && $reft ne 'HASH' && $reft ne 'SCALAR') {
        Carp::confess "supplied var must be a reference to an ARRAY, HASH, or SCALAR\n";
    }
    
    #make sure the reference has the correct type
    if($reft eq 'ARRAY' || $reft eq 'HASH') {
        my $re = qr/$reft/i;
        
        if($self->get_type() !~ $re) {
            my $type = $self->get_type();
            Carp::confess "supplied var has wrong type $type\n";
        }
    }
    
    #set the default appropriately
    if($self->has_default() && find_type_constraint('CodeRef')->check($self->default())) {
        my $fn = $self->default();
        $self->_set_default(&$fn());
    }
    
    #check the type of the default
    if($self->has_default() && !Moose::Util::TypeConstraints::find_or_parse_type_constraint($self->get_type())->check($self->default())) {
        my $def = $self->default();
        my $type = $self->get_type();
        Carp::confess "default $def fails type constraint $type\n";
    }
    
    #check the default against the validator
    if($self->has_default() && $self->has_validator()) {
        my $fn = $self->validator();
        if($self->get_type() =~ /^ArrayRef/) {
            my @defs = @{$self->default()};
            foreach my $def (@defs) {
                if(!&$fn($def)) {
                    Carp::confess "default $def fails supplied validation check\n";
                }
            }
        } elsif($self->get_type() =~ /^HashRef/) {
            my %defs = %{$self->default()};
            foreach my $key (keys %defs) {
                if(!&$fn($defs{$key})) {
                    Carp::confess "default $defs{$key} (with key $key) fails supplied validation check\n";
                }
            }
        } else {
            if(!&$fn($self->default())) {
                my $def = $self->default();
                Carp::confess "default $def fails supplied validation check\n";
            }
        }
    }
    
    #set the default value onto the supplied var
    if($self->has_default()) {
        if($self->get_type() =~ /^ArrayRef/) {
            my $var = $self->var();
            @$var = @{$self->default()};
        } elsif($self->get_type() =~ /^HashRef/) {
            my $var = $self->var();
            %$var = %{$self->default()};
        } else { #scalar
            my $var = $self->var();
            $$var = $self->default();
        }
    }
    
    #parse the switchspec
    my @aliases = split(/\|/, $self->switchspec);
    $self->_set_primary_name($aliases[0]);
    $self->_set_aliases(\@aliases);
    
    #create appropriate description
    if($self->desc() ne '') {
        my @use = ();
        foreach my $al (sort @{$self->aliases()}) {
            if(length($al) < 22) { #not too long
                push(@use, $al)
            } else {
                Carp::cluck "Alias $al too long for documentation and is being ignored\n";
            }
        }
        
        #all the options were too long, probably should die or issue a warning
        if($#use != -1) {
            $self->_set_desc($self->_create_desc_block(\@use));
        }
    }
}

sub _create_desc_block {
    my ($self, $alsref) = @_;
    
    #don't do so much string concatenation
    my @ret = ();
    push(@ret, '  ');
    my $os = $self->_create_option_string($alsref);
    if($os =~ /^--/) {
        push(@ret, '    '); #align the long options after the short
    }
    push(@ret, $os);
    my $less = $os =~ /^--/ ? 4 : 0; #need four less spaces if we start with a long option
    push(@ret, ' 'x(30-length($os)-$less));
    push(@ret,$self->desc()); #add the description
    push(@ret,"\n");
    
    #process all remaining options
    until((my $t = $self->_create_option_string($alsref)) eq '') {
        if($t =~ /^--/) {
            push(@ret, '      ');
        } else {
            push(@ret, '    ');
        }
        push(@ret, $t);
        push(@ret, "\n");
    }
    
    return join('', @ret);
    
}

sub _create_option_string {
    my ($self, $alsref) = @_;
    my $ret = '';
    while(my $sw = shift @$alsref) {
        next if !defined($sw);
        my $add = length($sw) == 1 ? '-' : '--'; #add dashes
        $add .= $sw;
        $add .= $#{$alsref} == -1 ? '' : ', '; #add a comma, if not last
        if(length($ret.$add) > 25) { unshift(@$alsref, $sw); last; }
        $ret .= $add;
    }
    
    return $ret;
}


sub set_value {
    my ($self, $val) = @_;
    
    #get the type parameter of the compound type
    my $type = $self->get_type();
    if($type =~ m/^([a-zA-Z]+)\[([a-zA-Z]+)\]$/) {
        $type = $2;
    }
    
    #handle different types
    my $var = $self->var;
    if($self->get_type() =~ /ArrayRef/) {
        return 0 if !$self->_check_val($type, $val);
        push(@$var, $val);
    } elsif($self->get_type() =~ /HashRef/) {
        my @kv = split(/=/, $val);
        return 0 if !$self->_check_val($type, $kv[1]);
        $var->{$kv[0]} = $kv[1];
        $val = $kv[1];
    } elsif($self->get_type() eq 'Inc') {
        ++$$var;
    } elsif($self->get_type() eq 'Bool') {
        $$var = 1;
    } else {
        return 0 if !$self->_check_val($type, $val);
        $$var = $val;
    }
    $self->_set(1); #var has been set
    
    if(defined($self->callback)) {
        my $fn = $self->callback;
        &$fn($val);
    }
    
    return 1;
}

sub _check_val {
    my ($self, $type, $val) = @_;
    
    if(!Moose::Util::TypeConstraints::find_type_constraint($type)->check($val)) {
        $self->_set_error("Invalid value $val does not conform to type constraint $type\n");
        return 0;
    }
    
    if(defined($self->validator)) {
        my $fn = $self->validator;
        if(!&$fn($val)) {
            $self->_set_error("Invalid value $val fails supplied validation check\n");
            return 0;
        }
    }
    
    return 1;
}


sub requires_val {
    my ($self) = @_;
    return !Moose::Util::TypeConstraints::find_or_parse_type_constraint($self->get_type())->is_a_type_of('Bool')
            && $self->get_type() ne 'Inc';
}


no Moose;

1;

__END__
=pod

=head1 NAME

Getopt::Flex::Spec::Argument - Getopt::Flex's way of specifying arguments

=head1 VERSION

version 1.07

=head1 DESCRIPTION

This class is only meant to be used by Getopt::Flex::Spec
and should not be used directly.

=head1 NAME

Getopt::Flex::Spec::Argument - Specification class for Getopt::Flex

=head1 METHODS

=head2 set_value

Set the value of this argument

=head2 requires_val

Check whether or not this argument requires a value

=for Pod::Coverage   BUILD

=head1 AUTHOR

Ryan P. Kelly <rpkelly@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Ryan P. Kelly.

This is free software, licensed under:

  The MIT (X11) License

=cut

