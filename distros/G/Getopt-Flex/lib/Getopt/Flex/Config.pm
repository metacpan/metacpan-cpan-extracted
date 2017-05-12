package Getopt::Flex::Config;
BEGIN {
  $Getopt::Flex::Config::VERSION = '1.07';
}

# ABSTRACT: Getopt::Flex's way of handling config

use strict; #shut up cpants
use warnings; #shut up cpants
use Moose;
use MooseX::StrictConstructor;
use Moose::Util::TypeConstraints;

#valid non_option_mode arguments
enum 'NonOptionMode' => qw(IGNORE SWITCH_RET_0 VALUE_RET_0 STOP_RET_0 STOP);
 
#valid long_option_mode arguments           
enum 'LongOptionMode' => qw(REQUIRE_DOUBLE_DASH SINGLE_OR_DOUBLE);

#valid case_mode arguments
enum 'CaseMode' => qw(SENSITIVE INSENSITIVE);

#how to react when encountering something that
#isn't an option
has 'non_option_mode' => (
    is => 'ro',
    isa => 'NonOptionMode',
    default => 'IGNORE',
    writer => '_set_non_option_mode',
    predicate => '_has_non_option_mode',
);
 
#allow bundling to be used? automatically
#sets long_option_mode to REQUIRE_DOUBLE_DASH
#if set to true
has 'bundling' => (
    is => 'ro',
    isa => 'Bool',
    default => 0,
    predicate => '_has_bundling',
);
                
#what kind of dashes are expected for
#long options
has 'long_option_mode' => (
    is => 'ro',
    isa => 'LongOptionMode',
    default => 'REQUIRE_DOUBLE_DASH',
    writer => '_set_long_option_mode',
    predicate => '_has_long_option_mode',
);
                    
#how do I use this thing?
has 'usage' => (
    is => 'ro',
    isa => 'Str',
    default => '',
);

#what is this thing like?
has 'desc' => (
    is => 'ro',
    isa => 'Str',
    default => '',
);

#for allowing case-insensitive handling of options
has 'case_mode' => (
    is => 'ro',
    isa => 'CaseMode',
    default => 'SENSITIVE',
);

#if true, specifying the --help switch (or -h) will cause the help
#to be printed, and exit(0) to be called.
has 'auto_help' => (
	is => 'ro',
	isa => 'Bool',
	default => 0,
);

                        
sub BUILD {
    my ($self) = @_;
    
    #die if configured wrong
    if($self->_has_bundling() && $self->_has_long_option_mode()) {
        if($self->bundling() && $self->long_option_mode() eq 'SINGLE_OR_DOUBLE') {
            Carp::confess "Cannot configure with bundling set to true and long_option_mode set to SINGLE_OR_DOUBLE\n";
        }
    }
    
    #automatically set the long_option_mode
    if($self->bundling) {
        $self->_set_long_option_mode('REQUIRE_DOUBLE_DASH');
    }
    
    #if POSIXLY_CORRECT set the non option mode to stop
    if($ENV{'POSIXLY_CORRECT'} && !$self->_has_non_option_mode) {
        $self->_set_non_option_mode('STOP');
    }
}


no Moose;

1;

__END__
=pod

=head1 NAME

Getopt::Flex::Config - Getopt::Flex's way of handling config

=head1 VERSION

version 1.07

=head1 DESCRIPTION

This class is only meant to be used by Getopt::Flex
and should not be used directly.

=head1 NAME

Getopt::Flex::Config - Configuration class for Getopt::Flex

=head1 METHODS

=for Pod::Coverage   BUILD

=head1 AUTHOR

Ryan P. Kelly <rpkelly@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Ryan P. Kelly.

This is free software, licensed under:

  The MIT (X11) License

=cut

